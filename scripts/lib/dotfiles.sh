#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2119,SC2120
# SC2034: the EXIT_* codes and path constants are consumed by the scripts that
# source this library, not by the library itself.
# shellcheck disable=SC2034
# Shared helpers for dotfile backup, restore, and verification
# Centralises the safety guards that keep operations inside the repository

# Prevent double-sourcing
if [[ -n "${_DOTFILES_SH_LOADED:-}" ]]; then
	return 0
fi
readonly _DOTFILES_SH_LOADED=1

_DOTFILES_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${_DOTFILES_LIB_DIR}/../.." && pwd)"
readonly REPO_ROOT

readonly MISE_CONFIG="${REPO_ROOT}/mise.toml"
readonly BASELINE_FILE="${REPO_ROOT}/config/chezmoi-baseline.txt"
readonly MANIFEST_FILE="${REPO_ROOT}/config/dotfiles-manifest.tsv"
readonly BACKUP_TREE="${REPO_ROOT}/home"

# Exit codes shared by the dotfile scripts
readonly EXIT_OK=0
readonly EXIT_FAIL=1
readonly EXIT_PREREQ=2

# mise resolves a relative `dotfiles.root` against the process working
# directory, and its default (~/.dotfiles) writes into $HOME. Always run mise
# from the repository root, and prove the resolved root landed inside the repo.
dotfiles_enter_repo() {
	cd "$REPO_ROOT" || die "cannot cd to $REPO_ROOT"

	local root
	root="$(mise settings get dotfiles.root 2>/dev/null || echo "")"
	case "$root" in
		home | ./home)
			: # relative to the repo root we just entered
			;;
		"$REPO_ROOT"/*)
			: # already absolute and inside the repo
			;;
		*)
			die "unsafe dotfiles.root '${root}': must be 'home' or inside ${REPO_ROOT}"
			;;
	esac
}

# Run mise against this repository's config, from the repository root.
dotfiles_mise() {
	MISE_CONFIG_FILE="$MISE_CONFIG" mise "$@"
}

# Reject anything that is not a plain, $HOME-relative path.
dotfiles_validate_relative() {
	local relative="$1"

	[[ -n "$relative" ]] || {
		log_error "empty path"
		return 1
	}
	[[ "$relative" != /* ]] || {
		log_error "absolute path rejected: $relative"
		return 1
	}
	[[ "$relative" != *".."* ]] || {
		log_error "path traversal rejected: $relative"
		return 1
	}
	[[ "$relative" != "~"* ]] || {
		log_error "unexpanded tilde rejected: $relative"
		return 1
	}
	return 0
}

# Turn a user-supplied target into a validated $HOME-relative path.
dotfiles_to_relative() {
	local target="$1"
	local relative

	target="${target/#\~\//${HOME}/}"
	if [[ "$target" != /* ]]; then
		target="${HOME}/${target}"
	fi

	case "$target" in
		"${HOME}/"*)
			relative="${target#"${HOME}/"}"
			;;
		*)
			log_error "target is outside \$HOME: $target"
			return 1
			;;
	esac

	dotfiles_validate_relative "$relative" || return 1
	printf '%s\n' "$relative"
}

# Baseline paths, one per line.
dotfiles_baseline() {
	[[ -f "$BASELINE_FILE" ]] || die "baseline not found: $BASELINE_FILE"
	grep -v '^[[:space:]]*$' "$BASELINE_FILE"
}

# Manifest relative paths, one per line.
dotfiles_manifest_paths() {
	[[ -f "$MANIFEST_FILE" ]] || die "manifest not found: $MANIFEST_FILE"
	cut -f1 "$MANIFEST_FILE" | grep -v '^[[:space:]]*$'
}

dotfiles_manifest_has() {
	local relative="$1"
	dotfiles_manifest_paths | grep -qxF "$relative"
}

dotfiles_baseline_has() {
	local relative="$1"
	dotfiles_baseline | grep -qxF "$relative"
}

# Rebuild config/dotfiles-manifest.tsv from the baseline.
#
# Checksums come from the committed repo source; mode and size come from the
# live target, because git records only the executable bit and cannot carry
# modes such as 0600.
dotfiles_generate_manifest() {
	local relative source live sha mode size errors=0
	local tmp expected rows

	# `dotfiles_baseline` dies inside the process substitution below, which only
	# kills that subshell. Check here so a missing baseline cannot silently
	# produce a zero-row manifest.
	[[ -f "$BASELINE_FILE" ]] || die "baseline not found: $BASELINE_FILE"
	expected="$(dotfiles_baseline | wc -l | tr -d ' ')"
	[[ "$expected" -gt 0 ]] || die "baseline is empty: $BASELINE_FILE"

	tmp="$(mktemp)" || die "cannot create temp file"

	while IFS= read -r relative; do
		source="${BACKUP_TREE}/${relative}"
		live="${HOME}/${relative}"

		if [[ ! -f "$source" ]]; then
			log_error "missing repo source: home/${relative}"
			errors=$((errors + 1))
			continue
		fi
		if [[ ! -f "$live" || -L "$live" ]]; then
			log_error "missing or non-regular live target: ${relative}"
			errors=$((errors + 1))
			continue
		fi

		sha="$(shasum -a 256 "$source" | cut -d' ' -f1)"
		mode="$(stat -f '%Lp' "$live")"
		size="$(stat -f '%z' "$live")"

		printf '%s\t%s\t%s\t%s\t%s\n' \
			"$relative" "home/${relative}" "$sha" "$mode" "$size" >> "$tmp"
	done < <(dotfiles_baseline)

	if [[ "$errors" -gt 0 ]]; then
		rm -f "$tmp"
		return 1
	fi

	# Never overwrite the committed manifest with fewer rows than the baseline.
	rows="$(wc -l < "$tmp" | tr -d ' ')"
	if [[ "$rows" -ne "$expected" ]]; then
		rm -f "$tmp"
		log_error "manifest would have ${rows} row(s) for ${expected} baseline path(s); refusing to write"
		return 1
	fi

	if ! LC_ALL=C sort -t$'\t' -k1,1 "$tmp" > "${tmp}.sorted"; then
		rm -f "$tmp" "${tmp}.sorted"
		log_error "cannot sort generated manifest"
		return 1
	fi
	mv "${tmp}.sorted" "$MANIFEST_FILE"
	rm -f "$tmp"
}
