#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2119,SC2120
# Homebrew installation script
# Installs and configures Homebrew on macOS/Linux

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
source "${SCRIPT_DIR}/../scripts/lib/common.sh"
# shellcheck source=../scripts/lib/detect.sh
source "${SCRIPT_DIR}/../scripts/lib/detect.sh"

# Constants
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# Check if Homebrew is installed
is_homebrew_installed() {
  command -v brew >/dev/null 2>&1
}

# Get Homebrew prefix based on architecture
get_homebrew_prefix() {
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo "/opt/homebrew"
  else
    echo "/usr/local"
  fi
}

# Install Homebrew
install_homebrew() {
  local install_url="${1:-$HOMEBREW_INSTALL_URL}"

  log_info "Installing Homebrew..."

  if is_homebrew_installed; then
    log_success "Homebrew already installed at $(command -v brew)"
    return 0
  fi

  if ! is_macos && ! is_linux; then
    log_error "Homebrew only supports macOS and Linux"
    return 1
  fi

  log_info "Downloading Homebrew installer..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$install_url")"

  # Add to PATH for current session
  local prefix
  prefix="$(get_homebrew_prefix)"
  export PATH="${prefix}/bin:${PATH}"

  if is_homebrew_installed; then
    log_success "Homebrew installed successfully"
    log_info "Homebrew prefix: ${prefix}"
    return 0
  else
    log_error "Homebrew installation failed"
    return 1
  fi
}

# Verify Homebrew installation
verify_homebrew() {
  log_info "Verifying Homebrew installation..."

  if ! is_homebrew_installed; then
    log_error "Homebrew not found in PATH"
    return 1
  fi

  log_info "Running: brew --version"
  brew --version

  log_info "Running: brew doctor"
  if brew doctor; then
    log_success "brew doctor passed"
  else
    log_warning "brew doctor reported issues (may be non-critical)"
  fi

  log_success "Homebrew verification complete"
}

# Main entry point
main() {
  log_header "Homebrew Installation"

  install_homebrew
  verify_homebrew

  log_success "Homebrew setup complete"
}

# Allow sourcing for tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
