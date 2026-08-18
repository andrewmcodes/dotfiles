#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2119,SC2120
# backup-dotfiles.sh - Capture live dotfiles from $HOME into this repository.
#
# Direction is live -> repo, always. This script never writes to $HOME: every
# mise invocation passes --no-apply, which is verified to leave the live file's
# content, mode, size, and mtime untouched.
#
# With no arguments, every path in the manifest is captured. With arguments,
# only those targets are captured, and only if they are already configured --
# an unconfigured target would make mise invent a new entry with no explicit
# mode, which falls back to symlink.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=scripts/lib/dotfiles.sh
source "${SCRIPT_DIR}/lib/dotfiles.sh"

usage() {
	cat <<-EOF
		Usage: ${0##*/} [target ...]

		With no arguments, captures every path in config/dotfiles-manifest.tsv.
		Targets must already be configured in mise.toml; new files are refused.

		  ${0##*/}
		  ${0##*/} ~/.zshenv ~/.config/git/config
	EOF
}

# Map a $HOME-relative file to the configured mise target that owns it. That is
# the file itself for a per-file entry, or the ancestor for a directory entry.
resolve_configured_target() {
	local relative="$1"
	local candidate="$relative"

	while :; do
		if grep -qxF "\"~/${candidate}\"" "${SCRATCH_TARGETS}" 2>/dev/null; then
			printf '%s\n' "$candidate"
			return 0
		fi
		[[ "$candidate" == */* ]] || return 1
		candidate="${candidate%/*}"
	done
}

load_configured_targets() {
	SCRATCH_TARGETS="$(mktemp)" || die "cannot create temp file"
	readonly SCRATCH_TARGETS
	# shellcheck disable=SC2064
	trap "rm -f '${SCRATCH_TARGETS}'" EXIT

	dotfiles_mise bootstrap dotfiles status --json 2>/dev/null |
		python3 -c '
import json, sys
for f in json.load(sys.stdin)["files"]:
    print("\"%s\"" % f["target"])
' > "$SCRATCH_TARGETS" || die "cannot read dotfile config from mise"
}

capture() {
	local relative="$1"
	local live="${HOME}/${relative}"
	local owner

	if [[ -L "$live" ]]; then
		log_error "refusing symlink target: ${relative}"
		return 1
	fi
	if [[ ! -f "$live" ]]; then
		log_error "live file is missing: ${relative} (repo source left untouched)"
		return 1
	fi

	if ! owner="$(resolve_configured_target "$relative")"; then
		log_error "not a configured dotfile: ${relative}"
		log_error "  add an explicit mode = \"copy\" entry to mise.toml first"
		return 1
	fi

	# --no-apply keeps this strictly live -> repo.
	if ! dotfiles_mise bootstrap dotfiles add "${HOME}/${owner}" --no-apply -y >/dev/null 2>&1; then
		log_error "mise could not capture: ${owner}"
		return 1
	fi
	return 0
}

main() {
	case "${1:-}" in
		-h | --help)
			usage
			exit "$EXIT_OK"
			;;
	esac

	require_command mise
	require_command shasum
	require_command python3

	dotfiles_enter_repo
	load_configured_targets

	local -a relatives=()
	local arg relative failures=0

	if [[ $# -eq 0 ]]; then
		# On the first run the manifest does not exist yet, so seed the path
		# list from the frozen baseline instead. Both hold the same 43 paths.
		if [[ -f "$MANIFEST_FILE" ]]; then
			while IFS= read -r relative; do
				relatives+=("$relative")
			done < <(dotfiles_manifest_paths)
		else
			log_warning "no manifest yet; seeding from ${BASELINE_FILE#"${REPO_ROOT}/"}"
			while IFS= read -r relative; do
				relatives+=("$relative")
			done < <(dotfiles_baseline)
		fi
	else
		for arg in "$@"; do
			relative="$(dotfiles_to_relative "$arg")" || die "invalid target: $arg"
			if [[ -f "$MANIFEST_FILE" ]] && ! dotfiles_manifest_has "$relative"; then
				die "not in the manifest: ${relative} (adding new files is a separate, explicit workflow)"
			fi
			relatives+=("$relative")
		done
	fi

	log_info "Capturing ${#relatives[@]} path(s) from \$HOME into home/"

	local -A seen_owners=()
	local owner
	for relative in "${relatives[@]}"; do
		# A directory entry only needs one capture for the whole tree.
		if owner="$(resolve_configured_target "$relative")" && [[ -n "${seen_owners[$owner]:-}" ]]; then
			continue
		fi
		if capture "$relative"; then
			[[ -n "${owner:-}" ]] && seen_owners["$owner"]=1
		else
			failures=$((failures + 1))
		fi
	done

	if [[ "$failures" -gt 0 ]]; then
		die "${failures} path(s) could not be captured; nothing was deleted"
	fi

	log_info "Regenerating ${MANIFEST_FILE#"${REPO_ROOT}/"}"
	dotfiles_generate_manifest || die "manifest generation failed"

	log_info "Verifying"
	"${SCRIPT_DIR}/verify-dotfiles.sh"

	log_header "Review before committing"
	git -C "$REPO_ROOT" status --short
	git -C "$REPO_ROOT" diff --stat
	log_success "Backup complete. Nothing was written to \$HOME and nothing was committed."
}

main "$@"
