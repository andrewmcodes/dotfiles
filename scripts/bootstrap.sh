#!/usr/bin/env bash
# Bootstrap script for dotfiles setup
# Orchestrates the installation of all dependencies

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source libraries
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/detect.sh
source "${SCRIPT_DIR}/lib/detect.sh"

# Show help message
show_help() {
    cat <<EOF
Dotfiles Bootstrap Script

Usage: $0 [OPTIONS]

This script will:
  1. Install Homebrew (if not present)
  2. Install mise (via Homebrew or curl)
  3. Install chezmoi and apply dotfiles
  4. Install packages from Brewfile (if present)

Options:
  -h, --help          Show this help message
  -d, --debug         Enable debug mode
  -r, --repo REPO     Specify dotfiles repository (default: andrewmcodes/dotfiles)

Environment Variables:
  DOTFILES_REPO       GitHub repo to clone (default: andrewmcodes/dotfiles)
  BREWFILE_PATH       Path to Brewfile (default: ./Brewfile)
  DEBUG               Enable debug output

EOF
}

# Parse command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--debug)
                export DEBUG=1
                set -x
                shift
                ;;
            -r|--repo)
                export DOTFILES_REPO="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main bootstrap function
bootstrap() {
    log_header "Dotfiles Bootstrap"

    show_system_info

    # Check internet connectivity
    log_info "Checking internet connectivity..."
    if ! check_internet; then
        die "No internet connection detected. Please check your network and try again."
    fi
    log_success "Internet connection verified"

    log_info "Starting bootstrap process..."

    # Step 1: Install Homebrew
    log_header "Step 1: Homebrew"
    if "${REPO_ROOT}/install/homebrew.sh"; then
        log_success "Homebrew step complete"
    else
        die "Homebrew installation failed"
    fi

    # Step 2: Install mise
    log_header "Step 2: Mise"
    if "${REPO_ROOT}/install/mise.sh"; then
        log_success "Mise step complete"
    else
        die "Mise installation failed"
    fi

    # Step 3: Install chezmoi and apply dotfiles
    log_header "Step 3: Chezmoi"
    if "${REPO_ROOT}/install/chezmoi.sh"; then
        log_success "Chezmoi step complete"
    else
        die "Chezmoi installation failed"
    fi

    # Step 4: Install from Brewfile (if present)
    if [[ -f "${REPO_ROOT}/Brewfile" ]]; then
        log_header "Step 4: Brewfile"
        if "${REPO_ROOT}/install/brewfile.sh" install; then
            log_success "Brewfile step complete"
        else
            log_warning "Brewfile installation had issues (continuing)"
        fi
    else
        log_info "No Brewfile found, skipping Homebrew bundle installation"
    fi

    log_header "Bootstrap Complete!"
    log_success "Your dotfiles have been set up successfully"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Restart your shell for all changes to take effect"
    log_info "  2. Run 'mise doctor' to verify tool installations"
    log_info "  3. Run 'chezmoi status' to check dotfiles status"
    log_info ""
}

# Main entry point
main() {
    parse_args "$@"

    # Enable debug mode if requested
    if [[ -n "${DEBUG:-}" ]]; then
        set -x
    fi

    bootstrap
}

# Run main
main "$@"
