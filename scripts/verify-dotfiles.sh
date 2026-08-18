#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2119,SC2120
# SC2088: the "~/..." strings below are literal mise target identifiers as they
# appear in mise.toml and in `mise ... status --json`, not paths to expand.
# shellcheck disable=SC2088
# verify-dotfiles.sh - Prove the committed backup covers and matches the dotfiles.
#
# The primary invariant is coverage: every path in config/chezmoi-baseline.txt
# must appear in config/dotfiles-manifest.tsv. That is what guarantees the mise
# backup contains at least everything chezmoi used to manage.
#
# Exit codes:
#   0  verified
#   1  drift, coverage gap, or invariant failure
#   2  verifier prerequisite failure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=scripts/lib/dotfiles.sh
source "${SCRIPT_DIR}/lib/dotfiles.sh"

# Trees whose live contents include untracked local files. A directory entry on
# any of these would sweep secrets into a public repository.
readonly FORBIDDEN_DIR_ENTRIES=(
	"~/.config"
	"~/.config/mise"
	"~/.claude"
)

ERRORS=0
CHECKED_CONTENT=0

ok() { printf 'OK\t%s\t%s\n' "$1" "$2"; }

bad() {
	printf 'ERROR\t%s\t%s\n' "$1" "$2"
	ERRORS=$((ERRORS + 1))
}

usage() {
	cat <<-EOF
		Usage: ${0##*/} [--no-live]

		  --no-live   Skip checks against \$HOME. Use in CI, where the live
		              dotfiles do not exist. Repository-internal checks still run.
	EOF
}

# Coverage: baseline must be a subset of the manifest.
check_coverage() {
	local relative
	while IFS= read -r relative; do
		if dotfiles_manifest_has "$relative"; then
			ok coverage "$relative"
		else
			bad missing-backup "$relative"
		fi
	done < <(dotfiles_baseline)
}

# Every manifest row must point at a real, non-symlink source with the recorded
# checksum, and optionally match the live target.
check_manifest_rows() {
	local check_live="$1"
	local relative source sha mode size
	local abs_source live actual

	while IFS=$'\t' read -r relative source sha mode size; do
		[[ -n "$relative" ]] || continue

		if ! dotfiles_validate_relative "$relative" >/dev/null 2>&1; then
			bad unsafe-path "$relative"
			continue
		fi

		if [[ "$source" != "home/${relative}" ]]; then
			bad source-mismatch "$relative"
			continue
		fi

		abs_source="${REPO_ROOT}/${source}"
		if [[ -L "$abs_source" ]]; then
			bad source-is-symlink "$relative"
			continue
		fi
		if [[ ! -f "$abs_source" ]]; then
			bad source-missing "$relative"
			continue
		fi

		actual="$(shasum -a 256 "$abs_source" | cut -d' ' -f1)"
		if [[ "$actual" != "$sha" ]]; then
			bad source-checksum "$relative"
			continue
		fi
		ok content "$relative"
		CHECKED_CONTENT=$((CHECKED_CONTENT + 1))

		[[ "$check_live" == "yes" ]] || continue

		live="${HOME}/${relative}"
		if [[ -L "$live" ]]; then
			bad live-is-symlink "$relative"
			continue
		fi
		if [[ ! -f "$live" ]]; then
			bad live-missing "$relative"
			continue
		fi
		if ! cmp -s "$abs_source" "$live"; then
			bad live-content-differs "$relative"
			continue
		fi
		if [[ "$(stat -f '%Lp' "$live")" != "$mode" ]]; then
			bad live-mode-differs "$relative"
			continue
		fi
		if [[ "$(stat -f '%z' "$live")" != "$size" ]]; then
			bad live-size-differs "$relative"
			continue
		fi
		ok live "$relative"
	done < "$MANIFEST_FILE"
}

# The backup tree must hold nothing but manifest sources. A directory entry
# re-imports whatever the live tree contains, so an untracked local file can
# arrive in home/ without ever reaching the manifest.
check_no_extra_sources() {
	local extras found
	found=0

	while IFS= read -r extras; do
		[[ -n "$extras" ]] || continue
		bad unmanaged-source "home/${extras}"
		found=1
	done < <(
		LC_ALL=C comm -23 \
			<(cd "$BACKUP_TREE" && find . -type f | sed 's|^\./||' | LC_ALL=C sort) \
			<(dotfiles_manifest_paths | LC_ALL=C sort)
	)

	[[ "$found" -eq 1 ]] || ok invariant no-unmanaged-sources
}

check_no_duplicates() {
	local dupes
	dupes="$(cut -f1 "$MANIFEST_FILE" | LC_ALL=C sort | uniq -d)"
	if [[ -n "$dupes" ]]; then
		while IFS= read -r relative; do
			bad duplicate-target "$relative"
		done <<< "$dupes"
	else
		ok invariant no-duplicate-targets
	fi

	dupes="$(cut -f2 "$MANIFEST_FILE" | LC_ALL=C sort | uniq -d)"
	if [[ -n "$dupes" ]]; then
		while IFS= read -r source; do
			bad duplicate-source "$source"
		done <<< "$dupes"
	else
		ok invariant no-duplicate-sources
	fi
}

# Config safety, read straight from mise rather than by grepping TOML, so the
# check sees what mise actually resolved.
check_config_safety() {
	local json target mode source forbidden entries edits

	if ! json="$(dotfiles_mise bootstrap dotfiles status --json 2>/dev/null)"; then
		bad config unreadable
		return
	fi

	local rows counts
	if ! rows="$(printf '%s' "$json" | python3 -c '
import json, sys
doc = json.load(sys.stdin)
files = doc.get("files") or []
print("COUNTS\t%d\t%d" % (len(files), len(doc.get("edits") or [])))
for f in files:
    print("\t".join((f.get("target", ""), f.get("mode", ""), f.get("source", ""))))
')"; then
		bad config unparseable
		return
	fi

	counts="$(printf '%s\n' "$rows" | grep '^COUNTS	' | head -1)"
	entries="$(printf '%s' "$counts" | cut -f2)"
	edits="$(printf '%s' "$counts" | cut -f3)"
	rows="$(printf '%s\n' "$rows" | grep -v '^COUNTS	' || true)"

	# An empty table must not pass silently: a restore would then write nothing.
	if [[ "${entries:-0}" -eq 0 ]]; then
		bad config no-dotfile-entries
		return
	fi

	# Edit entries write into files mise does not own; none of the safety rules
	# below apply to them, so refuse them outright.
	if [[ "${edits:-0}" -ne 0 ]]; then
		bad config "edit-entries-present (${edits})"
	fi

	: > "$SCRATCH_CONFIGURED"

	while IFS=$'\t' read -r target mode source; do
		[[ -n "$target" ]] || continue
		printf '%s\n' "$target" >> "$SCRATCH_CONFIGURED"

		if [[ "$mode" != "copy" ]]; then
			bad non-copy-mode "${target} (mode=${mode:-unset})"
			continue
		fi

		case "$target" in
			"~/"*) : ;;
			*) bad target-outside-home "$target" ;;
		esac

		if [[ "$source" != *"/home/"* && "$source" != "home/"* ]]; then
			bad source-outside-backup-tree "$target"
		fi

		for forbidden in "${FORBIDDEN_DIR_ENTRIES[@]}"; do
			if [[ "$target" == "$forbidden" ]]; then
				bad forbidden-directory-entry "$target"
			fi
		done
	done <<< "$rows"

	if printf '%s' "$json" | grep -qE '"mode"[[:space:]]*:[[:space:]]*"symlink'; then
		bad invariant symlink-entry-present
	else
		ok invariant copy-only
	fi
}

# Every manifest path must be owned by a configured entry -- itself for a
# per-file entry, or an ancestor for a directory entry. Without this the
# manifest and the [dotfiles] table can drift apart, and a restore would
# silently skip paths the manifest still claims to cover.
check_manifest_is_configured() {
	local relative candidate found missing=0

	if [[ ! -s "$SCRATCH_CONFIGURED" ]]; then
		return
	fi

	while IFS= read -r relative; do
		[[ -n "$relative" ]] || continue
		candidate="$relative"
		found=0
		while :; do
			if grep -qxF "~/${candidate}" "$SCRATCH_CONFIGURED"; then
				found=1
				break
			fi
			[[ "$candidate" == */* ]] || break
			candidate="${candidate%/*}"
		done
		if [[ "$found" -eq 0 ]]; then
			bad unconfigured-manifest-path "$relative"
			missing=1
		fi
	done < <(dotfiles_manifest_paths)

	[[ "$missing" -eq 1 ]] || ok invariant manifest-fully-configured
}

main() {
	local check_live="yes"

	if [[ $# -gt 1 ]]; then
		usage >&2
		exit "$EXIT_PREREQ"
	fi

	case "${1:-}" in
		--no-live) check_live="no" ;;
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

	SCRATCH_CONFIGURED="$(mktemp)" || die "cannot create temp file"
	readonly SCRATCH_CONFIGURED
	# shellcheck disable=SC2064
	trap "rm -f '${SCRATCH_CONFIGURED}'" EXIT

	require_command shasum
	require_command mise
	require_command python3

	[[ -f "$BASELINE_FILE" ]] || {
		log_error "baseline not found: $BASELINE_FILE"
		exit "$EXIT_PREREQ"
	}
	[[ -f "$MANIFEST_FILE" ]] || {
		log_error "manifest not found: $MANIFEST_FILE (run scripts/backup-dotfiles.sh)"
		exit "$EXIT_PREREQ"
	}

	dotfiles_enter_repo

	check_coverage
	check_manifest_rows "$check_live"
	check_no_duplicates
	check_no_extra_sources
	check_config_safety
	check_manifest_is_configured

	local baseline_count manifest_count excluded_count
	baseline_count="$(dotfiles_baseline | wc -l | tr -d ' ')"
	manifest_count="$(dotfiles_manifest_paths | wc -l | tr -d ' ')"
	excluded_count=0
	if [[ -f "${REPO_ROOT}/config/baseline-exclusions.tsv" ]]; then
		excluded_count="$(grep -vc '^[[:space:]]*$' "${REPO_ROOT}/config/baseline-exclusions.tsv" || true)"
	fi

	printf 'SUMMARY\tbaseline=%s\tbacked_up=%s\texcluded=%s\tlive=%s\terrors=%s\n' \
		"$baseline_count" "$manifest_count" "$excluded_count" "$check_live" "$ERRORS"

	[[ "$ERRORS" -eq 0 ]] || exit "$EXIT_FAIL"
}

main "$@"
