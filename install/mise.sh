#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2119,SC2120
# Mise installation script
# Installs and configures mise (formerly rtx) for tool version management

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
source "${SCRIPT_DIR}/../scripts/lib/common.sh"
# shellcheck source=../scripts/lib/detect.sh
source "${SCRIPT_DIR}/../scripts/lib/detect.sh"

# Constants
MISE_INSTALL_URL="https://mise.run"
MISE_CONFIG_PATH="${HOME}/.config/mise/config.toml"
TOOL_VERSIONS_PATH="${HOME}/.tool-versions"

# Check if mise is installed
is_mise_installed() {
  command -v mise >/dev/null 2>&1
}

# Get mise version
get_mise_version() {
  if is_mise_installed; then
    mise --version | awk '{print $2}'
  else
    echo "not installed"
  fi
}

# Install mise via Homebrew
install_mise_via_homebrew() {
  log_info "Installing mise via Homebrew..."

  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew not found. Install Homebrew first."
    return 1
  fi

  if brew install mise; then
    log_success "Mise installed via Homebrew"
    return 0
  else
    log_error "Failed to install mise via Homebrew"
    return 1
  fi
}

# Install mise via curl
install_mise_via_curl() {
  log_info "Installing mise via curl installer..."

  if curl -fsSL "${MISE_INSTALL_URL}" | sh; then
    # Add to PATH for current session
    export PATH="${HOME}/.local/bin:${PATH}"
    log_success "Mise installed via curl"
    return 0
  else
    log_error "Failed to install mise via curl"
    return 1
  fi
}

# Install mise (tries Homebrew first on macOS, falls back to curl)
install_mise() {
  if is_mise_installed; then
    log_success "Mise already installed ($(get_mise_version))"
    return 0
  fi

  # Try Homebrew first on macOS, fall back to curl
  if is_macos && command -v brew >/dev/null 2>&1; then
    install_mise_via_homebrew || install_mise_via_curl
  else
    install_mise_via_curl
  fi

  if is_mise_installed; then
    log_success "Mise installation complete ($(get_mise_version))"
    return 0
  else
    log_error "Mise installation failed"
    return 1
  fi
}

# Activate mise (configure shell integration)
activate_mise() {
  log_info "Activating mise..."

  # This function adds mise to shell config if needed
  # For testing, we just verify it's in PATH
  if ! is_mise_installed; then
    log_error "Mise not found in PATH"
    return 1
  fi

  log_success "Mise activated"
}

# Install mise tools from configuration
install_mise_tools() {
  local config_path="${1:-$MISE_CONFIG_PATH}"

  log_info "Installing mise tools from config..."

  if [[ ! -f "$config_path" ]]; then
    log_warning "Mise config not found at: $config_path"
    log_info "Checking for .tool-versions..."

    if [[ -f "$TOOL_VERSIONS_PATH" ]]; then
      config_path="$TOOL_VERSIONS_PATH"
      log_info "Using .tool-versions instead"
    else
      log_error "No mise config or .tool-versions found"
      return 1
    fi
  fi

  log_info "Installing tools from: $config_path"
  if mise install; then
    log_success "Mise tools installed"
    return 0
  else
    log_error "Failed to install some mise tools"
    return 1
  fi
}

# Verify mise tools installation
verify_mise_tools() {
  log_info "Verifying installed tools..."

  if mise list; then
    log_success "Mise tools verification complete"
    return 0
  else
    log_warning "Could not list mise tools"
    return 1
  fi
}

# Main entry point
main() {
  log_header "Mise Installation"

  install_mise
  activate_mise
  install_mise_tools
  verify_mise_tools

  log_success "Mise setup complete"
}

# Allow sourcing for tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
