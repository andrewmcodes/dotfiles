#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2119,SC2120
# Chezmoi installation script
# Installs and configures chezmoi for dotfiles management

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
source "${SCRIPT_DIR}/../scripts/lib/common.sh"
# shellcheck source=../scripts/lib/detect.sh
source "${SCRIPT_DIR}/../scripts/lib/detect.sh"

# Constants
CHEZMOI_INSTALL_URL="https://get.chezmoi.io"
DOTFILES_REPO="${DOTFILES_REPO:-andrewmcodes/dotfiles}"

# Check if chezmoi is installed
is_chezmoi_installed() {
	command -v chezmoi >/dev/null 2>&1
}

# Get chezmoi version
get_chezmoi_version() {
	if is_chezmoi_installed; then
		chezmoi --version | awk '{print $3}'
	else
		echo "not installed"
	fi
}

# Install chezmoi via Homebrew
install_chezmoi_via_homebrew() {
	log_info "Installing chezmoi via Homebrew..."

	if ! command -v brew >/dev/null 2>&1; then
		log_error "Homebrew not found"
		return 1
	fi

	if brew install chezmoi; then
		log_success "Chezmoi installed via Homebrew"
		return 0
	else
		log_error "Failed to install chezmoi via Homebrew"
		return 1
	fi
}

# Install chezmoi via curl
install_chezmoi_via_curl() {
	log_info "Installing chezmoi via curl installer..."

	if sh -c "$(curl -fsLS ${CHEZMOI_INSTALL_URL})"; then
		# Add to PATH for current session
		export PATH="${HOME}/.local/bin:${PATH}"
		log_success "Chezmoi installed via curl"
		return 0
	else
		log_error "Failed to install chezmoi via curl"
		return 1
	fi
}

# Install chezmoi (tries Homebrew first on macOS, falls back to curl)
install_chezmoi() {
	if is_chezmoi_installed; then
		log_success "Chezmoi already installed ($(get_chezmoi_version))"
		return 0
	fi

	# Try Homebrew first on macOS, fall back to curl
	if is_macos && command -v brew >/dev/null 2>&1; then
		install_chezmoi_via_homebrew || install_chezmoi_via_curl
	else
		install_chezmoi_via_curl
	fi

	if is_chezmoi_installed; then
		log_success "Chezmoi installation complete ($(get_chezmoi_version))"
		return 0
	else
		log_error "Chezmoi installation failed"
		return 1
	fi
}

# Initialize chezmoi with repository
init_chezmoi() {
	local repo="${1:-$DOTFILES_REPO}"

	log_info "Initializing chezmoi with repo: $repo"

	if [[ -d "${HOME}/.local/share/chezmoi/.git" ]]; then
		log_success "Chezmoi already initialized"
		return 0
	fi

	if chezmoi init "$repo"; then
		log_success "Chezmoi initialized"
		return 0
	else
		log_error "Failed to initialize chezmoi"
		return 1
	fi
}

# Apply chezmoi dotfiles
apply_chezmoi() {
	log_info "Applying chezmoi dotfiles..."

	log_info "Showing changes..."
	chezmoi diff || log_info "Chezmoi diff completed"

	log_info "Applying changes..."
	if chezmoi apply; then
		log_success "Chezmoi dotfiles applied"
		return 0
	else
		log_error "Failed to apply chezmoi dotfiles"
		return 1
	fi
}

# Verify chezmoi setup
verify_chezmoi() {
	log_info "Verifying chezmoi setup..."

	if [[ ! -d "${HOME}/.local/share/chezmoi" ]]; then
		log_error "Chezmoi source directory not found"
		return 1
	fi

	log_info "Checking chezmoi status..."
	chezmoi status || log_info "Chezmoi status check complete"

	log_success "Chezmoi verification complete"
}

# Main entry point
main() {
	log_header "Chezmoi Installation"

	local repo="${1:-$DOTFILES_REPO}"

	install_chezmoi
	init_chezmoi "$repo"
	apply_chezmoi
	verify_chezmoi

	log_success "Chezmoi setup complete"
}

# Allow sourcing for tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
