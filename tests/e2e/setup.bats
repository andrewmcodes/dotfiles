#!/usr/bin/env bats
# End-to-end tests for full bootstrap workflow

load '../test_helper'

@test "bootstrap script exists and is executable" {
    [ -f "${REPO_ROOT}/scripts/bootstrap.sh" ]
    [ -x "${REPO_ROOT}/scripts/bootstrap.sh" ]
}

@test "bootstrap script shows help message" {
    run "${REPO_ROOT}/scripts/bootstrap.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Bootstrap Script" ]]
    [[ "$output" =~ "Usage:" ]]
}

@test "homebrew installer exists and is executable" {
    [ -f "${REPO_ROOT}/install/homebrew.sh" ]
    [ -x "${REPO_ROOT}/install/homebrew.sh" ]
}

@test "mise installer exists and is executable" {
    [ -f "${REPO_ROOT}/install/mise.sh" ]
    [ -x "${REPO_ROOT}/install/mise.sh" ]
}

@test "chezmoi installer exists and is executable" {
    [ -f "${REPO_ROOT}/install/chezmoi.sh" ]
    [ -x "${REPO_ROOT}/install/chezmoi.sh" ]
}

@test "brewfile manager exists and is executable" {
    [ -f "${REPO_ROOT}/install/brewfile.sh" ]
    [ -x "${REPO_ROOT}/install/brewfile.sh" ]
}

@test "all library scripts are present" {
    [ -f "${REPO_ROOT}/scripts/lib/common.sh" ]
    [ -f "${REPO_ROOT}/scripts/lib/detect.sh" ]
    [ -f "${REPO_ROOT}/scripts/lib/validation.sh" ]
}

@test "Brewfile exists and is valid" {
    [ -f "${REPO_ROOT}/Brewfile" ]

    # Should contain at least some brew/cask/tap commands
    grep -qE "^(tap|brew|cask)" "${REPO_ROOT}/Brewfile"
}

@test "test infrastructure is complete" {
    [ -f "${REPO_ROOT}/tests/test_helper.bash" ]
    [ -d "${REPO_ROOT}/tests/unit/install" ]
    [ -d "${REPO_ROOT}/tests/helpers" ]
}

@test "all installation scripts can be sourced without errors" {
    # Test that scripts can be sourced for testing
    run bash -c "source ${REPO_ROOT}/install/homebrew.sh && type is_homebrew_installed"
    [ "$status" -eq 0 ]

    run bash -c "source ${REPO_ROOT}/install/mise.sh && type is_mise_installed"
    [ "$status" -eq 0 ]

    run bash -c "source ${REPO_ROOT}/install/chezmoi.sh && type is_chezmoi_installed"
    [ "$status" -eq 0 ]

    run bash -c "source ${REPO_ROOT}/install/brewfile.sh && type is_brewfile_present"
    [ "$status" -eq 0 ]
}

@test "library scripts can be sourced without errors" {
    run bash -c "source ${REPO_ROOT}/scripts/lib/common.sh && type log_info"
    [ "$status" -eq 0 ]

    run bash -c "source ${REPO_ROOT}/scripts/lib/detect.sh && type is_macos"
    [ "$status" -eq 0 ]

    run bash -c "source ${REPO_ROOT}/scripts/lib/validation.sh && type validate_brewfile"
    [ "$status" -eq 0 ]
}

@test "all scripts pass shellcheck" {
    if ! command -v shellcheck >/dev/null 2>&1; then
        skip "shellcheck not installed"
    fi

    run shellcheck "${REPO_ROOT}/install/"*.sh
    [ "$status" -eq 0 ]

    run shellcheck "${REPO_ROOT}/scripts/lib/"*.sh
    [ "$status" -eq 0 ]

    run shellcheck "${REPO_ROOT}/scripts/bootstrap.sh"
    [ "$status" -eq 0 ]
}

@test "CI workflow files exist" {
    [ -f "${REPO_ROOT}/.github/workflows/unit-tests.yml" ]
}

@test "documentation is up to date" {
    [ -f "${REPO_ROOT}/README.md" ]

    # README should mention testing
    grep -q "Testing" "${REPO_ROOT}/README.md"

    # README should mention bootstrap
    grep -q "bootstrap" "${REPO_ROOT}/README.md"
}

@test "chezmoiignore excludes test infrastructure" {
    [ -f "${REPO_ROOT}/.chezmoiignore" ]

    # Should ignore tests directory
    grep -q "tests/" "${REPO_ROOT}/.chezmoiignore"

    # Should ignore install scripts
    grep -q "install/" "${REPO_ROOT}/.chezmoiignore"

    # Should ignore scripts directory
    grep -q "scripts/" "${REPO_ROOT}/.chezmoiignore"
}
