#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2119,SC2120
# restore-dotfiles.sh - Restore dotfiles from this repository into $HOME.
#
# This is the only script that writes to $HOME, and it does so only when passed
# --apply. Without that flag it previews and changes nothing. Copy mode means
# every restored path is a real file, never a symlink.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=scripts/lib/dotfiles.sh
source "${SCRIPT_DIR}/lib/dotfiles.sh"

usage() {
	cat <<-EOF
		Usage: ${0##*/} [--apply]

		Without --apply, previews the restore and writes nothing.
		With --apply, copies files into \$HOME, replays the recorded modes,
		then verifies the result.

		Conflicts stop the restore. --force is deliberately not offered.
	EOF
}

main() {
	local apply="no"

	# This is the only script that writes to $HOME. Never let an unrecognised
	# extra argument (`--apply --dry-run`) be silently ignored.
	if [[ $# -gt 1 ]]; then
		usage >&2
		exit "$EXIT_PREREQ"
	fi

	case "${1:-}" in
		--apply) apply="yes" ;;
		-h | --help)
			usage
			exit "$EXIT_OK"
			;;
		"") : ;;
		*)
			usage >&2
			exit "$EXIT_PREREQ"
			;;
	esac

	require_command mise
	dotfiles_enter_repo

	if [[ "$apply" == "no" ]]; then
		log_header "Preview only - nothing will be written"
		dotfiles_mise bootstrap dotfiles apply --dry-run --verbose
		echo
		log_info "Re-run with --apply to write these files into \$HOME"
		exit "$EXIT_OK"
	fi

	log_header "Restoring dotfiles into \$HOME"
	dotfiles_mise bootstrap dotfiles apply --yes

	log_info "Replaying recorded file modes"
	"${SCRIPT_DIR}/apply-dotfile-modes.sh"

	log_info "Verifying"
	"${SCRIPT_DIR}/verify-dotfiles.sh"

	log_success "Restore complete"
}

main "$@"
