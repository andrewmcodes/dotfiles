#!/usr/bin/env bats
# Tests for install/brewfile.sh

load '../../test_helper'

# Source the script to test
setup_file() {
    # shellcheck source=../../../install/brewfile.sh
    source "${BATS_TEST_DIRNAME}/../../../install/brewfile.sh"
}

@test "is_brewfile_present returns true when file exists" {
    # Create mock Brewfile
    export BREWFILE_PATH="${TEST_TEMP_DIR}/Brewfile"
    touch "$BREWFILE_PATH"

    run is_brewfile_present
    [ "$status" -eq 0 ]
}

@test "is_brewfile_present returns false when file missing" {
    export BREWFILE_PATH="${TEST_TEMP_DIR}/nonexistent"

    run is_brewfile_present
    [ "$status" -eq 1 ]
}

@test "validate_brewfile fails for missing file" {
    run validate_brewfile "/nonexistent/Brewfile"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not found" ]]
}

@test "validate_brewfile warns for empty file" {
    local brewfile="${TEST_TEMP_DIR}/Brewfile"
    touch "$brewfile"

    run validate_brewfile "$brewfile"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "may be empty" ]]
}

@test "validate_brewfile succeeds for valid file" {
    local brewfile="${TEST_TEMP_DIR}/Brewfile"
    cat > "$brewfile" <<EOF
tap "homebrew/bundle"
brew "git"
cask "warp"
EOF

    run validate_brewfile "$brewfile"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "validation passed" ]]
}

@test "install_from_brewfile fails without Homebrew" {
    local brewfile="${TEST_TEMP_DIR}/Brewfile"
    echo "brew 'git'" > "$brewfile"

    run install_from_brewfile "$brewfile"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not installed" ]]
}

@test "install_from_brewfile fails for missing Brewfile" {
    mock_command "brew" "Homebrew 4.0.0"

    run install_from_brewfile "/nonexistent/Brewfile"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not found" ]]
}

@test "install_from_brewfile succeeds with valid Brewfile" {
    local brewfile="${TEST_TEMP_DIR}/Brewfile"
    echo "brew 'git'" > "$brewfile"

    mock_command_with_script "brew" '
if [[ "$1" == "bundle" && "$2" == "--file="* ]]; then
    echo "Installing from Brewfile..."
    exit 0
fi
'

    run install_from_brewfile "$brewfile"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "installation complete" ]]
}

@test "dump_brewfile fails without Homebrew" {
    run dump_brewfile "${TEST_TEMP_DIR}/Brewfile"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not installed" ]]
}

@test "dump_brewfile creates backup of existing file" {
    local brewfile="${TEST_TEMP_DIR}/Brewfile"
    echo "brew 'old'" > "$brewfile"

    mock_command_with_script "brew" '
if [[ "$1" == "bundle" && "$2" == "dump" ]]; then
    echo "brew '\''new'\''" > "$4"
    exit 0
fi
'

    run dump_brewfile "$brewfile"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Backed up" ]]

    # Verify backup exists
    local backup_count
    backup_count=$(find "$TEST_TEMP_DIR" -name "Brewfile.backup.*" | wc -l)
    [ "$backup_count" -ge 1 ]
}

@test "dump_brewfile succeeds with Homebrew available" {
    local brewfile="${TEST_TEMP_DIR}/Brewfile"

    mock_command_with_script "brew" '
if [[ "$1" == "bundle" && "$2" == "dump" ]]; then
    echo "brew '\''git'\''" > "$4"
    exit 0
fi
'

    run dump_brewfile "$brewfile"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "dumped successfully" ]]
}

@test "cleanup_brewfile fails without Homebrew" {
    run cleanup_brewfile "${TEST_TEMP_DIR}/Brewfile"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not installed" ]]
}

@test "cleanup_brewfile fails for missing Brewfile" {
    mock_command "brew" "Homebrew 4.0.0"

    run cleanup_brewfile "/nonexistent/Brewfile"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not found" ]]
}

@test "cleanup_brewfile succeeds with valid Brewfile" {
    local brewfile="${TEST_TEMP_DIR}/Brewfile"
    echo "brew 'git'" > "$brewfile"

    mock_command_with_script "brew" '
if [[ "$1" == "bundle" && "$2" == "cleanup" ]]; then
    echo "Cleaned up packages"
    exit 0
fi
'

    run cleanup_brewfile "$brewfile"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "cleanup complete" ]]
}

@test "main with invalid action shows usage" {
    run main "invalid"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown action" ]]
    [[ "$output" =~ "Usage" ]]
}
