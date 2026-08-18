#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2034
# Shared setup for the dotfile test suite.
#
# Isolation here is a kill-switch, not an assumption. Overriding HOME alone does
# NOT isolate mise: it still reads the real ~/.config/mise. Every test therefore
# overrides HOME plus all four XDG base directories, and aborts outright if the
# fake HOME does not resolve inside the Bats temp directory. A leak must fail
# the suite rather than quietly touch the developer's real dotfiles.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Captured before HOME is reassigned, so assertions can prove we never read it.
REAL_HOME="$HOME"

# Build an isolated HOME and mise environment inside the Bats temp directory.
isolate_home() {
	local sandbox="${1:-${BATS_TEST_TMPDIR}}"

	[[ -n "$sandbox" ]] || {
		echo "isolate_home: no sandbox directory" >&2
		return 1
	}

	export HOME="${sandbox}/home"
	mkdir -p "$HOME"

	export XDG_CONFIG_HOME="${HOME}/.config"
	export XDG_CACHE_HOME="${sandbox}/cache"
	export XDG_DATA_HOME="${sandbox}/data"
	export XDG_STATE_HOME="${sandbox}/state"
	mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"

	# mise resolves its global config independently of HOME and XDG_CONFIG_HOME,
	# so overriding those is not enough on its own: the real
	# ~/.config/mise/config.toml still gets loaded. MISE_IGNORED_CONFIG_PATHS is
	# what actually excludes it.
	export MISE_IGNORED_CONFIG_PATHS="${REAL_HOME}/.config/mise"

	# Overriding XDG_STATE_HOME discards mise's trust cache, which makes the
	# repository config read as untrusted and hard-fail. Trust the sandbox and
	# the repository explicitly so runs do not abort.
	export MISE_TRUSTED_CONFIG_PATHS="${sandbox}:${REPO_ROOT}"

	assert_isolated
}

# Hard abort if the sandbox did not take effect.
assert_isolated() {
	case "$HOME" in
		"${BATS_TEST_TMPDIR}"/*) : ;;
		*)
			echo "FATAL: HOME '$HOME' is not inside BATS_TEST_TMPDIR" >&2
			exit 1
			;;
	esac

	if [[ "$HOME" == "$REAL_HOME" ]]; then
		echo "FATAL: HOME still points at the real home directory" >&2
		exit 1
	fi
}

# Assert mise resolved no config out of the real user's mise directory.
assert_no_real_config_leak() {
	local config="$1"
	local out
	out="$(mise_with "$config" config ls 2>&1 || true)"
	if grep -qF "${REAL_HOME}/.config/mise" <<< "$out"; then
		echo "FATAL: mise read the real global config:" >&2
		echo "$out" >&2
		return 1
	fi
}

# A writable copy of the repository, for tests that mutate sources or config.
copy_repo() {
	local dest="${1:-${BATS_TEST_TMPDIR}/repo}"
	mkdir -p "$dest"
	cp -R "${REPO_ROOT}/home" "$dest/"
	cp -R "${REPO_ROOT}/config" "$dest/"
	cp -R "${REPO_ROOT}/scripts" "$dest/"
	cp "${REPO_ROOT}/mise.toml" "$dest/"
	printf '%s\n' "$dest"
}

# Run mise against a given config file.
#
# MISE_CONFIG_FILE does NOT replace config discovery: mise still walks up from
# the working directory and loads any mise.toml it finds there. Running from the
# repository root while pointing at a copied config therefore loads BOTH, and
# the real repository's sources win. Always run from the config's own directory.
mise_with() {
	local config="$1"
	shift
	MISE_CONFIG_FILE="$config" mise --cd "$(dirname "$config")" "$@"
}

# A small, innocuous text file from the manifest, for mutation tests.
#
# Never an image, so a diff is meaningful. Prefers a known-trivial fixture so
# that a regression in a mutation test cannot clobber a substantial config file.
first_text_target() {
	local manifest="$1"
	local preferred candidate

	for preferred in ".warp/themes/foo.md" ".editorconfig" ".prettierrc" ".default-gems"; do
		if cut -f1 "$manifest" | grep -qxF "$preferred"; then
			printf '%s\n' "$preferred"
			return 0
		fi
	done

	candidate="$(awk -F'\t' '$1 !~ /\.(png|jpg|jpeg)$/ { print $1; exit }' "$manifest")"
	printf '%s\n' "$candidate"
}
