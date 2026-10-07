#!/usr/bin/env bats
# Repository hygiene: scripts are executable and lint clean, mise.toml parses,
# and no chezmoi remnant is left behind.

setup() {
	load 'test_helper'
}

@test "all scripts are executable" {
	for script in "${REPO_ROOT}"/scripts/*.sh; do
		[ -x "$script" ] || {
			echo "not executable: $script"
			false
		}
	done
}

@test "shared libraries exist" {
	[ -f "${REPO_ROOT}/scripts/lib/common.sh" ]
	[ -f "${REPO_ROOT}/scripts/lib/dotfiles.sh" ]
}

@test "shellcheck passes on scripts" {
	if ! command -v shellcheck > /dev/null 2>&1; then
		skip "shellcheck not installed"
	fi
	run shellcheck "${REPO_ROOT}"/scripts/*.sh
	[ "$status" -eq 0 ]
}

@test "shellcheck passes on libraries" {
	if ! command -v shellcheck > /dev/null 2>&1; then
		skip "shellcheck not installed"
	fi
	run shellcheck "${REPO_ROOT}"/scripts/lib/*.sh
	[ "$status" -eq 0 ]
}

@test "libraries source cleanly and export their helpers" {
	run bash -c "
		source '${REPO_ROOT}/scripts/lib/common.sh'
		source '${REPO_ROOT}/scripts/lib/dotfiles.sh'
		declare -F log_info > /dev/null &&
		declare -F die > /dev/null &&
		declare -F dotfiles_validate_relative > /dev/null &&
		declare -F dotfiles_generate_manifest > /dev/null
	"
	[ "$status" -eq 0 ]
}

@test "path validation rejects traversal and absolute paths" {
	run bash -c "
		source '${REPO_ROOT}/scripts/lib/common.sh'
		source '${REPO_ROOT}/scripts/lib/dotfiles.sh'
		dotfiles_validate_relative '../outside' 2>/dev/null
	"
	[ "$status" -ne 0 ]

	run bash -c "
		source '${REPO_ROOT}/scripts/lib/common.sh'
		source '${REPO_ROOT}/scripts/lib/dotfiles.sh'
		dotfiles_validate_relative '/etc/passwd' 2>/dev/null
	"
	[ "$status" -ne 0 ]

	run bash -c "
		source '${REPO_ROOT}/scripts/lib/common.sh'
		source '${REPO_ROOT}/scripts/lib/dotfiles.sh'
		dotfiles_validate_relative '.config/git/config'
	"
	[ "$status" -eq 0 ]
}

@test "mise.toml parses and exposes the dotfile tasks" {
	run mise --cd "$REPO_ROOT" tasks ls
	[ "$status" -eq 0 ]
	[[ "$output" == *"dotfiles:backup"* ]]
	[[ "$output" == *"dotfiles:restore"* ]]
	[[ "$output" == *"dotfiles:verify"* ]]
}

@test "no chezmoi remnants remain" {
	[ ! -f "${REPO_ROOT}/.chezmoiignore" ]
	[ ! -d "${REPO_ROOT}/install" ]
	[ ! -f "${REPO_ROOT}/Brewfile" ]

	run bash -c "ls -d '${REPO_ROOT}'/dot_* 2>/dev/null"
	[ -z "$output" ]

	# No script or task actually invokes chezmoi. Prose may still name the tool
	# (the migration baseline is called chezmoi-baseline.txt, and the Copilot
	# instructions tell contributors not to use it), so match invocations only.
	run bash -c "
		cd '${REPO_ROOT}' &&
		git ls-files -z -- mise.toml scripts tests |
			xargs -0 grep -nE '(^|[^-[:alnum:]_])chezmoi[[:space:]]+(apply|add|diff|status|init|edit|chattr|managed|source-path)' 2>/dev/null || true
	"
	[ -z "$output" ]
}

@test "the backup tree mirrors home-relative paths" {
	[ -d "${REPO_ROOT}/home" ]
	[ -f "${REPO_ROOT}/home/.zshenv" ]
	[ -f "${REPO_ROOT}/home/.config/git/config" ]

	# No chezmoi-style encoded names survived the move.
	run bash -c "cd '${REPO_ROOT}/home' && find . -name 'dot_*' -o -name 'private_*' -o -name 'executable_*' | head"
	[ -z "$output" ]
}

@test "bootstrap packages are declared and parse" {
	run mise --cd "$REPO_ROOT" bootstrap packages status
	[ "$status" -eq 0 ]
	[[ "$output" == *"brew"* ]]
}
