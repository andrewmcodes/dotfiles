#!/usr/bin/env bats
# Tests for install/homebrew.sh

load '../../test_helper'

# Source the script to test
setup_file() {
    # shellcheck source=../../../install/homebrew.sh
    source "${BATS_TEST_DIRNAME}/../../../install/homebrew.sh"
}

@test "is_homebrew_installed returns 0 when brew is available" {
    mock_command "brew" "Homebrew 4.0.0"

    run is_homebrew_installed
    [ "$status" -eq 0 ]
}

@test "is_homebrew_installed returns 1 when brew is not available" {
    # Don't mock brew - let it fail naturally

    run is_homebrew_installed
    [ "$status" -eq 1 ]
}

@test "get_homebrew_prefix returns /opt/homebrew on arm64" {
    # Mock uname to return arm64
    mock_command "uname" "arm64" 0

    run get_homebrew_prefix
    [ "$status" -eq 0 ]
    [ "$output" = "/opt/homebrew" ]
}

@test "get_homebrew_prefix returns /usr/local on x86_64" {
    # Mock uname to return x86_64
    mock_command "uname" "x86_64" 0

    run get_homebrew_prefix
    [ "$status" -eq 0 ]
    [ "$output" = "/usr/local" ]
}

@test "install_homebrew skips installation if already installed" {
    mock_command "brew" "Homebrew 4.0.0"

    run install_homebrew
    [ "$status" -eq 0 ]
    [[ "$output" =~ "already installed" ]]
}

@test "install_homebrew fails on unsupported OS" {
    # Mock OS detection to return unsupported OS
    export OSTYPE="unsupported"

    run install_homebrew
    [ "$status" -eq 1 ]
    [[ "$output" =~ "only supports" ]]
}

@test "verify_homebrew fails when brew is not installed" {
    # Don't mock brew

    run verify_homebrew
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not found" ]]
}

@test "verify_homebrew succeeds when brew is installed" {
    # Mock brew command and brew doctor
    mock_command_with_script "brew" '
if [[ "$1" == "--version" ]]; then
    echo "Homebrew 4.0.0"
elif [[ "$1" == "doctor" ]]; then
    echo "Your system is ready to brew."
fi
'

    run verify_homebrew
    [ "$status" -eq 0 ]
    [[ "$output" =~ "verification complete" ]]
}

@test "verify_homebrew warns on brew doctor issues" {
    # Mock brew command with doctor warnings
    mock_command_with_script "brew" '
if [[ "$1" == "--version" ]]; then
    echo "Homebrew 4.0.0"
elif [[ "$1" == "doctor" ]]; then
    echo "Warning: Some issues detected"
    exit 1
fi
'

    run verify_homebrew
    [ "$status" -eq 0 ]
    [[ "$output" =~ "may be non-critical" ]]
}
