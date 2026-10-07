#!/usr/bin/env bash
# fingerprint-home.sh - Record a read-only fingerprint of every managed live dotfile.
#
# Emits one TSV row per path in config/chezmoi-baseline.txt:
#   relative_path<TAB>sha256<TAB>mode<TAB>size<TAB>mtime
#
# This is the migration safety gate: capture it before any work, capture it
# again afterwards, and diff. A non-empty diff means $HOME was modified.
# mtime is included so a rewrite with identical content is still caught.
#
# Intentionally dependency-free (no lib sourcing, no mise) so the gate cannot
# be undermined by the code it is auditing. Reads only; never writes to $HOME.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT

readonly BASELINE="${REPO_ROOT}/config/chezmoi-baseline.txt"

usage() {
	cat <<-EOF
		Usage: ${0##*/} <output-file>

		Writes a TSV fingerprint of all baseline dotfiles to <output-file>.
		<output-file> must be outside \$HOME so the gate never writes into
		the tree it is auditing. Use "-" to write to stdout.
	EOF
}

main() {
	if [[ $# -ne 1 ]]; then
		usage >&2
		exit 2
	fi

	case "$1" in
		-h | --help)
			usage
			exit 0
			;;
	esac

	if [[ ! -f "$BASELINE" ]]; then
		echo "ERROR: baseline not found: $BASELINE" >&2
		exit 2
	fi

	local out="$1"
	if [[ "$out" != "-" ]]; then
		local out_dir real_home
		if ! out_dir="$(cd "$(dirname "$out")" 2>/dev/null && pwd -P)"; then
			echo "ERROR: output directory does not exist: $(dirname "$out")" >&2
			exit 2
		fi
		# Compare resolved paths on both sides: a symlink outside $HOME that
		# points into it must not slip past this guard.
		real_home="$(cd "$HOME" && pwd -P)"
		if [[ "$out_dir" == "$real_home" || "$out_dir" == "$real_home"/* ]]; then
			echo "ERROR: refusing to write the fingerprint inside \$HOME: $out" >&2
			exit 2
		fi
	fi

	local errors=0
	local rows=""
	local relative live sha mode size mtime

	while IFS= read -r relative; do
		[[ -n "$relative" ]] || continue
		live="${HOME}/${relative}"

		if [[ -L "$live" ]]; then
			echo "ERROR: unexpected symlink: $relative" >&2
			errors=$((errors + 1))
			continue
		fi

		if [[ ! -f "$live" ]]; then
			echo "ERROR: missing live file: $relative" >&2
			errors=$((errors + 1))
			continue
		fi

		sha="$(shasum -a 256 "$live" | cut -d' ' -f1)"
		mode="$(stat -f '%Lp' "$live")"
		size="$(stat -f '%z' "$live")"
		mtime="$(stat -f '%Fm' "$live")"

		rows+="${relative}	${sha}	${mode}	${size}	${mtime}"$'\n'
	done < "$BASELINE"

	# A partial fingerprint is worse than none: diffing it against a complete one
	# reports spurious changes. Write only when every baseline path was read.
	if [[ "$errors" -gt 0 ]]; then
		echo "ERROR: $errors problem(s) fingerprinting baseline; no fingerprint written" >&2
		exit 1
	fi

	if [[ "$out" == "-" ]]; then
		printf '%s' "$rows"
	else
		printf '%s' "$rows" > "$out"
	fi
}

main "$@"
