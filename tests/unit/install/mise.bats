#!/usr/bin/env bats
# Tests for install/mise.sh

load '../../test_helper'

# Source the script to test
setup_file() {
    # shellcheck source=../../../install/mise.sh
    source "${BATS_TEST_DIRNAME}/../../../install/mise.sh"
}

@test "is_mise_installed returns 0 when mise is available" {
    mock_command "mise" "2024.1.0"

    run is_mise_installed
    [ "$status" -eq 0 ]
}

@test "is_mise_installed returns 1 when mise is not available" {
    run is_mise_installed
    [ "$status" -eq 1 ]
}

@test "get_mise_version returns version when installed" {
    mock_command "mise" "mise 2024.1.0"

    run get_mise_version
    [ "$status" -eq 0 ]
    [ "$output" = "2024.1.0" ]
}

@test "get_mise_version returns 'not installed' when not available" {
    run get_mise_version
    [ "$status" -eq 0 ]
    [ "$output" = "not installed" ]
}

@test "install_mise skips installation if already installed" {
    mock_command "mise" "mise 2024.1.0"

    run install_mise
    [ "$status" -eq 0 ]
    [[ "$output" =~ "already installed" ]]
}

@test "install_mise_via_homebrew fails without brew" {
    run install_mise_via_homebrew
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Homebrew not found" ]]
}

@test "install_mise_via_homebrew succeeds with brew available" {
    mock_command_with_script "brew" '
if [[ "$1" == "install" && "$2" == "mise" ]]; then
    echo "Installing mise..."
    exit 0
fi
'

    run install_mise_via_homebrew
    [ "$status" -eq 0 ]
    [[ "$output" =~ "installed via Homebrew" ]]
}

@test "install_mise_tools fails without config file" {
    run install_mise_tools "/nonexistent/config.toml"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not found" ]]
}

@test "install_mise_tools succeeds with valid config" {
    # Create mock config
    mkdir -p "${TEST_TEMP_DIR}/.config/mise"
    cat > "${TEST_TEMP_DIR}/.config/mise/config.toml" <<EOF
[tools]
ruby = "3.2.2"
EOF

    # Mock mise command
    mock_command_with_script "mise" '
if [[ "$1" == "install" ]]; then
    echo "Installing tools..."
    exit 0
fi
'

    run install_mise_tools "${TEST_TEMP_DIR}/.config/mise/config.toml"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "tools installed" ]]
}

@test "verify_mise_tools succeeds when mise list works" {
    mock_command_with_script "mise" '
if [[ "$1" == "list" ]]; then
    echo "ruby 3.2.2"
    echo "nodejs 20.9.0"
    exit 0
fi
'

    run verify_mise_tools
    [ "$status" -eq 0 ]
    [[ "$output" =~ "verification complete" ]]
}

@test "activate_mise fails when mise not in PATH" {
    run activate_mise
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not found" ]]
}

@test "activate_mise succeeds when mise is available" {
    mock_command "mise" "2024.1.0"

    run activate_mise
    [ "$status" -eq 0 ]
    [[ "$output" =~ "activated" ]]
}
