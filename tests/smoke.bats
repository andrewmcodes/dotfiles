#!/usr/bin/env bats
# Smoke tests - verify scripts are valid and can be sourced

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

@test "install scripts exist and are executable" {
  [ -x "${REPO_ROOT}/install/homebrew.sh" ]
  [ -x "${REPO_ROOT}/install/mise.sh" ]
  [ -x "${REPO_ROOT}/install/chezmoi.sh" ]
  [ -x "${REPO_ROOT}/install/brewfile.sh" ]
}

@test "bootstrap script exists and is executable" {
  [ -x "${REPO_ROOT}/scripts/bootstrap.sh" ]
}

@test "library scripts exist" {
  [ -f "${REPO_ROOT}/scripts/lib/common.sh" ]
  [ -f "${REPO_ROOT}/scripts/lib/detect.sh" ]
  [ -f "${REPO_ROOT}/scripts/lib/validation.sh" ]
}

@test "install scripts pass shellcheck" {
  if ! command -v shellcheck >/dev/null 2>&1; then
    skip "shellcheck not installed"
  fi

  shellcheck "${REPO_ROOT}"/install/*.sh
}

@test "library scripts pass shellcheck" {
  if ! command -v shellcheck >/dev/null 2>&1; then
    skip "shellcheck not installed"
  fi

  shellcheck "${REPO_ROOT}"/scripts/lib/*.sh
}

@test "bootstrap script passes shellcheck" {
  if ! command -v shellcheck >/dev/null 2>&1; then
    skip "shellcheck not installed"
  fi

  shellcheck "${REPO_ROOT}/scripts/bootstrap.sh"
}

@test "install scripts can be sourced without errors" {
  run bash -c "source ${REPO_ROOT}/install/homebrew.sh; type is_homebrew_installed"
  [ "$status" -eq 0 ]

  run bash -c "source ${REPO_ROOT}/install/mise.sh; type is_mise_installed"
  [ "$status" -eq 0 ]

  run bash -c "source ${REPO_ROOT}/install/chezmoi.sh; type is_chezmoi_installed"
  [ "$status" -eq 0 ]
}

@test "library scripts can be sourced without errors" {
  run bash -c "source ${REPO_ROOT}/scripts/lib/common.sh; type log_info"
  [ "$status" -eq 0 ]

  run bash -c "source ${REPO_ROOT}/scripts/lib/detect.sh; type is_macos"
  [ "$status" -eq 0 ]
}

@test "Brewfile has valid content" {
  [ -f "${REPO_ROOT}/Brewfile" ]
  # Should contain at least one brew/cask/tap command
  grep -qE "^(tap|brew|cask)" "${REPO_ROOT}/Brewfile"
}
