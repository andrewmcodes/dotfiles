#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2119,SC2120
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

DRY_RUN=0
SKIP_INSTALL=0
SKIP_APPLY=0

# Show help message
show_help() {
	cat <<EOF2
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
      --dry-run       Print planned steps without applying changes
      --install-only  Install dependencies but skip chezmoi apply
      --apply-only    Apply dotfiles only (skip Homebrew/mise/Brewfile install)

Environment Variables:
  DOTFILES_REPO       GitHub repo to clone (default: andrewmcodes/dotfiles)
  BREWFILE_PATH       Path to Brewfile (default: ./Brewfile)
  DEBUG               Enable debug output

EOF2
}

# Parse command-line arguments
parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_help
			exit 0
			;;
		-d | --debug)
			export DEBUG=1
			set -x
			shift
			;;
		-r | --repo)
			export DOTFILES_REPO="$2"
			shift 2
			;;
		--dry-run)
			DRY_RUN=1
			shift
			;;
		--install-only)
			SKIP_APPLY=1
			shift
			;;
		--apply-only)
			SKIP_INSTALL=1
			shift
			;;
		*)
			log_error "Unknown option: $1"
			show_help
			exit 1
			;;
		esac
	done

	if [[ "$SKIP_INSTALL" -eq 1 && "$SKIP_APPLY" -eq 1 ]]; then
		die "--install-only and --apply-only cannot be used together"
	fi
}

run_step() {
	local desc="$1"
	shift
	if [[ "$DRY_RUN" -eq 1 ]]; then
		log_info "[dry-run] ${desc}"
		return 0
	fi
	"$@"
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

	if [[ "$SKIP_INSTALL" -eq 0 ]]; then
		# Step 1: Install Homebrew
		log_header "Step 1: Homebrew"
		if run_step "Run install/homebrew.sh" "${REPO_ROOT}/install/homebrew.sh"; then
			log_success "Homebrew step complete"
		else
			die "Homebrew installation failed"
		fi

		# Step 2: Install mise
		log_header "Step 2: Mise"
		if run_step "Run install/mise.sh" "${REPO_ROOT}/install/mise.sh"; then
			log_success "Mise step complete"
		else
			die "Mise installation failed"
		fi
	fi

	# Step 3: Install chezmoi and apply dotfiles
	log_header "Step 3: Chezmoi"
	if [[ "$DRY_RUN" -eq 1 ]]; then
		log_info "[dry-run] Run install/chezmoi.sh"
	elif [[ "$SKIP_APPLY" -eq 1 ]]; then
		if SKIP_CHEZMOI_APPLY=1 "${REPO_ROOT}/install/chezmoi.sh"; then
			log_success "Chezmoi install complete (apply skipped)"
		else
			die "Chezmoi installation failed"
		fi
	elif "${REPO_ROOT}/install/chezmoi.sh"; then
		log_success "Chezmoi step complete"
	else
		die "Chezmoi installation failed"
	fi

	# Step 4: Install from Brewfile (if present)
	if [[ "$SKIP_INSTALL" -eq 0 && -f "${REPO_ROOT}/Brewfile" ]]; then
		log_header "Step 4: Brewfile"
		if run_step "Run install/brewfile.sh install" "${REPO_ROOT}/install/brewfile.sh" install; then
			log_success "Brewfile step complete"
		else
			log_warning "Brewfile installation had issues (continuing)"
		fi
	elif [[ "$SKIP_INSTALL" -eq 0 ]]; then
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
