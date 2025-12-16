#!/usr/bin/env bats
# Tests for install/chezmoi.sh

load '../../test_helper'

# Source the script to test
setup_file() {
    # shellcheck source=../../../install/chezmoi.sh
    source "${BATS_TEST_DIRNAME}/../../../install/chezmoi.sh"
}

@test "is_chezmoi_installed returns 0 when chezmoi is available" {
    mock_command "chezmoi" "chezmoi version 2.40.0"

    run is_chezmoi_installed
    [ "$status" -eq 0 ]
}

@test "is_chezmoi_installed returns 1 when chezmoi is not available" {
    run is_chezmoi_installed
    [ "$status" -eq 1 ]
}

@test "get_chezmoi_version returns version when installed" {
    mock_command "chezmoi" "chezmoi version 2.40.0"

    run get_chezmoi_version
    [ "$status" -eq 0 ]
    [ "$output" = "2.40.0" ]
}

@test "get_chezmoi_version returns 'not installed' when not available" {
    run get_chezmoi_version
    [ "$status" -eq 0 ]
    [ "$output" = "not installed" ]
}

@test "install_chezmoi skips installation if already installed" {
    mock_command "chezmoi" "chezmoi version 2.40.0"

    run install_chezmoi
    [ "$status" -eq 0 ]
    [[ "$output" =~ "already installed" ]]
}

@test "install_chezmoi_via_homebrew fails without brew" {
    run install_chezmoi_via_homebrew
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Homebrew not found" ]]
}

@test "install_chezmoi_via_homebrew succeeds with brew available" {
    mock_command_with_script "brew" '
if [[ "$1" == "install" && "$2" == "chezmoi" ]]; then
    echo "Installing chezmoi..."
    exit 0
fi
'

    run install_chezmoi_via_homebrew
    [ "$status" -eq 0 ]
    [[ "$output" =~ "installed via Homebrew" ]]
}

@test "init_chezmoi skips if already initialized" {
    # Create mock .git directory
    mkdir -p "${HOME}/.local/share/chezmoi/.git"

    run init_chezmoi "test/repo"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "already initialized" ]]
}

@test "init_chezmoi succeeds with valid repo" {
    mock_command_with_script "chezmoi" '
if [[ "$1" == "init" ]]; then
    mkdir -p "$HOME/.local/share/chezmoi/.git"
    echo "Initialized chezmoi"
    exit 0
fi
'

    run init_chezmoi "andrewmcodes/dotfiles"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "initialized" ]]
}

@test "apply_chezmoi succeeds when chezmoi apply works" {
    mock_command_with_script "chezmoi" '
if [[ "$1" == "diff" ]]; then
    echo "No changes"
    exit 0
elif [[ "$1" == "apply" ]]; then
    echo "Applied dotfiles"
    exit 0
fi
'

    run apply_chezmoi
    [ "$status" -eq 0 ]
    [[ "$output" =~ "dotfiles applied" ]]
}

@test "apply_chezmoi fails when chezmoi apply fails" {
    mock_command_with_script "chezmoi" '
if [[ "$1" == "diff" ]]; then
    echo "Changes detected"
    exit 0
elif [[ "$1" == "apply" ]]; then
    echo "Failed to apply"
    exit 1
fi
'

    run apply_chezmoi
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Failed to apply" ]]
}

@test "verify_chezmoi fails without source directory" {
    run verify_chezmoi
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not found" ]]
}

@test "verify_chezmoi succeeds with valid setup" {
    # Create mock chezmoi directory
    mkdir -p "${HOME}/.local/share/chezmoi"

    mock_command_with_script "chezmoi" '
if [[ "$1" == "status" ]]; then
    echo "Clean"
    exit 0
fi
'

    run verify_chezmoi
    [ "$status" -eq 0 ]
    [[ "$output" =~ "verification complete" ]]
}
