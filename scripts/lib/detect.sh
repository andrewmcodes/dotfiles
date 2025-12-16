#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2119,SC2120
# OS and environment detection utilities

# Prevent double-sourcing
if [[ -n "${_DETECT_SH_LOADED:-}" ]]; then
  return 0
fi
readonly _DETECT_SH_LOADED=1

# Source common functions for logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

# OS detection
is_macos() {
  [[ "$OSTYPE" == "darwin"* ]]
}

is_linux() {
  [[ "$OSTYPE" == "linux-gnu"* ]]
}

is_wsl() {
  [[ -f /proc/version ]] && grep -qi microsoft /proc/version
}

get_os_type() {
  if is_macos; then
    echo "macos"
  elif is_wsl; then
    echo "wsl"
  elif is_linux; then
    echo "linux"
  else
    echo "unknown"
  fi
}

# Architecture detection
get_arch() {
  uname -m
}

is_arm64() {
  [[ "$(get_arch)" == "arm64" ]] || [[ "$(get_arch)" == "aarch64" ]]
}

is_x86_64() {
  [[ "$(get_arch)" == "x86_64" ]]
}

# macOS version detection
get_macos_version() {
  if is_macos; then
    sw_vers -productVersion
  else
    echo "N/A"
  fi
}

# Shell detection
get_current_shell() {
  basename "$SHELL"
}

is_zsh() {
  [[ "$(get_current_shell)" == "zsh" ]]
}

is_bash() {
  [[ "$(get_current_shell)" == "bash" ]]
}

# CI detection
is_ci() {
  [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]
}

is_github_actions() {
  [[ -n "${GITHUB_ACTIONS:-}" ]]
}

# User detection
is_root() {
  [[ "$EUID" -eq 0 ]]
}

# Display info
show_system_info() {
  log_info "System Information:"
  log_info "  OS: $(get_os_type)"
  log_info "  Architecture: $(get_arch)"
  log_info "  Shell: $(get_current_shell)"
  if is_macos; then
    log_info "  macOS Version: $(get_macos_version)"
  fi
}
