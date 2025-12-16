#!/usr/bin/env bash
# Common utility functions for dotfiles installation
# Provides logging, error handling, and common utilities

# Color codes for logging
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# Logging functions
log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*"
}

log_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $*" >&2
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

log_header() {
    local header="$*"
    local separator="═══════════════════════════════════════"
    echo
    echo -e "${COLOR_BLUE}${separator}${COLOR_RESET}"
    echo -e "${COLOR_BLUE}  $header${COLOR_RESET}"
    echo -e "${COLOR_BLUE}${separator}${COLOR_RESET}"
    echo
}

# Error handling
die() {
    log_error "$@"
    exit 1
}

# Command checking
require_command() {
    local cmd="$1"
    local install_msg="${2:-Install $cmd and try again}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        die "$cmd is required. $install_msg"
    fi
}

# Confirmation prompts
confirm() {
    local prompt="${1:-Are you sure?}"
    local default="${2:-n}"

    local yn
    while true; do
        read -rp "$prompt [y/N] " yn
        yn="${yn:-$default}"
        case "$yn" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# File operations
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d-%H%M%S)"
        cp "$file" "$backup"
        log_info "Backed up: $file -> $backup"
    fi
}

# Network utilities
check_internet() {
    if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Temporary directory management
create_temp_dir() {
    mktemp -d -t dotfiles.XXXXXX
}
