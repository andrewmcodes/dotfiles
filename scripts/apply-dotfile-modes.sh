#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2119,SC2120
# apply-dotfile-modes.sh - Restore recorded file modes after a dotfile restore.
#
# Git records only whether a regular file is executable. It cannot carry modes
# such as 0600, and 23 of the managed dotfiles are 0600. The manifest is
# therefore the authoritative record of the intended mode, and this script
# replays it. Run it after `mise bootstrap dotfiles apply`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=scripts/lib/dotfiles.sh
source "${SCRIPT_DIR}/lib/dotfiles.sh"

usage() {
	cat <<-EOF
		Usage: ${0##*/} [--dry-run]

		Applies the mode recorded in config/dotfiles-manifest.tsv to each
		restored file under \$HOME. Current user only; never uses sudo.
	EOF
}

main() {
	local dry_run="no"

	if [[ $# -gt 1 ]]; then
		usage >&2
		exit "$EXIT_PREREQ"
	fi

	case "${1:-}" in
		--dry-run) dry_run="yes" ;;
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

	[[ -f "$MANIFEST_FILE" ]] || {
		log_error "manifest not found: $MANIFEST_FILE"
		exit "$EXIT_PREREQ"
	}

	local relative source sha mode size
	local live current changed=0 errors=0

	while IFS=$'\t' read -r relative source sha mode size; do
		[[ -n "$relative" ]] || continue

		if ! dotfiles_validate_relative "$relative" >/dev/null 2>&1; then
			log_error "unsafe manifest path: $relative"
			errors=$((errors + 1))
			continue
		fi

		# chmod is about to run on a live file, so never hand it a value the
		# manifest did not record as a plain octal mode.
		if [[ ! "$mode" =~ ^[0-7]{3,4}$ ]]; then
			log_error "bad recorded mode for ${relative}: '${mode}'"
			errors=$((errors + 1))
			continue
		fi

		live="${HOME}/${relative}"

		if [[ -L "$live" ]]; then
			log_error "refusing symlink: $relative"
			errors=$((errors + 1))
			continue
		fi
		if [[ ! -f "$live" ]]; then
			log_error "missing restored file: $relative"
			errors=$((errors + 1))
			continue
		fi

		current="$(stat -f '%Lp' "$live")"
		[[ "$current" == "$mode" ]] && continue

		if [[ "$dry_run" == "yes" ]]; then
			printf 'WOULD-CHMOD\t%s\t%s -> %s\n' "$relative" "$current" "$mode"
		elif chmod "$mode" "$live"; then
			printf 'CHMOD\t%s\t%s -> %s\n' "$relative" "$current" "$mode"
		else
			log_error "chmod failed: $relative"
			errors=$((errors + 1))
			continue
		fi
		changed=$((changed + 1))
	done < "$MANIFEST_FILE"

	printf 'SUMMARY\tchanged=%s\terrors=%s\n' "$changed" "$errors"

	# Unused by design: kept so the manifest column order stays self-documenting.
	: "${source:-}" "${sha:-}" "${size:-}"

	[[ "$errors" -eq 0 ]] || exit "$EXIT_FAIL"
}

main "$@"
