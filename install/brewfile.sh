#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2119,SC2120
# Brewfile management script
# Manages Homebrew packages via Brewfile

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
source "${SCRIPT_DIR}/../scripts/lib/common.sh"
# shellcheck source=../scripts/lib/detect.sh
source "${SCRIPT_DIR}/../scripts/lib/detect.sh"

# Constants
BREWFILE_PATH="${BREWFILE_PATH:-${HOME}/.local/share/chezmoi/Brewfile}"

# Check if Brewfile exists
is_brewfile_present() {
  [[ -f "$BREWFILE_PATH" ]]
}

# Validate Brewfile syntax
validate_brewfile() {
  local brewfile="${1:-$BREWFILE_PATH}"

  log_info "Validating Brewfile at: $brewfile"

  if [[ ! -f "$brewfile" ]]; then
    log_error "Brewfile not found: $brewfile"
    return 1
  fi

  # Basic validation: check for common Homebrew keywords
  if ! grep -qE "^(tap|brew|cask|mas)" "$brewfile"; then
    log_warning "Brewfile may be empty or malformed"
  fi

  log_success "Brewfile validation passed"
}

# Install packages from Brewfile
install_from_brewfile() {
  local brewfile="${1:-$BREWFILE_PATH}"

  log_info "Installing from Brewfile: $brewfile"

  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew not installed"
    return 1
  fi

  if [[ ! -f "$brewfile" ]]; then
    log_error "Brewfile not found: $brewfile"
    return 1
  fi

  if brew bundle --file="$brewfile"; then
    log_success "Brewfile installation complete"
    return 0
  else
    log_error "brew bundle failed"
    return 1
  fi
}

# Dump current packages to Brewfile
dump_brewfile() {
  local output_file="${1:-$BREWFILE_PATH}"

  log_info "Dumping current Homebrew packages to: $output_file"

  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew not installed"
    return 1
  fi

  # Create backup if file exists
  if [[ -f "$output_file" ]]; then
    local backup_file
    backup_file="${output_file}.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$output_file" "$backup_file"
    log_info "Backed up existing Brewfile to: $backup_file"
  fi

  if brew bundle dump --force --file="$output_file"; then
    log_success "Brewfile dumped successfully"
    return 0
  else
    log_error "brew bundle dump failed"
    return 1
  fi
}

# Cleanup unused packages
cleanup_brewfile() {
  local brewfile="${1:-$BREWFILE_PATH}"

  log_info "Cleaning up unused Homebrew packages..."

  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew not installed"
    return 1
  fi

  if [[ ! -f "$brewfile" ]]; then
    log_error "Brewfile not found: $brewfile"
    return 1
  fi

  if brew bundle cleanup --file="$brewfile" --force; then
    log_success "Brewfile cleanup complete"
    return 0
  else
    log_warning "Cleanup had issues (may be expected)"
    return 1
  fi
}

# Main entry point
main() {
  log_header "Brewfile Management"

  local action="${1:-install}"

  case "$action" in
  install)
    validate_brewfile
    install_from_brewfile
    ;;
  dump)
    dump_brewfile
    ;;
  cleanup)
    cleanup_brewfile
    ;;
  validate)
    validate_brewfile
    ;;
  *)
    log_error "Unknown action: $action"
    log_info "Usage: $0 {install|dump|cleanup|validate}"
    return 1
    ;;
  esac

  log_success "Brewfile operation complete"
}

# Allow sourcing for tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
