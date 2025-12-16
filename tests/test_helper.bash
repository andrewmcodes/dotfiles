#!/usr/bin/env bash
# Main test helper for bats tests
# Provides setup/teardown and common testing utilities

# Load bats support libraries (if installed via Homebrew)
BATS_SUPPORT_PATH="/opt/homebrew/lib"
if [[ -d "$BATS_SUPPORT_PATH" ]]; then
    # Try to load bats-support and bats-assert if available
    if [[ -f "${BATS_SUPPORT_PATH}/bats-support/load.bash" ]]; then
        # shellcheck source=/dev/null
        source "${BATS_SUPPORT_PATH}/bats-support/load.bash"
    fi
    if [[ -f "${BATS_SUPPORT_PATH}/bats-assert/load.bash" ]]; then
        # shellcheck source=/dev/null
        source "${BATS_SUPPORT_PATH}/bats-assert/load.bash"
    fi
fi

# Test fixtures directory
export FIXTURES_DIR="${BATS_TEST_DIRNAME}/fixtures"

# Temporary test directory
export TEST_TEMP_DIR

# Repository root
export REPO_ROOT
REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"

# Setup function called before each test
setup() {
    # Create temporary directory for test
    TEST_TEMP_DIR="$(mktemp -d -t bats-test.XXXXXX)"
    export TEST_TEMP_DIR

    # Set HOME to temp directory for isolated tests
    export HOME="$TEST_TEMP_DIR"

    # Mock common environment variables
    export CI="true"
    export GITHUB_ACTIONS="false"
}

# Teardown function called after each test
teardown() {
    # Clean up temporary directory
    if [[ -n "$TEST_TEMP_DIR" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Helper function to mock commands
mock_command() {
    local cmd="$1"
    local output="${2:-}"
    local exit_code="${3:-0}"

    # Create mock script directory if it doesn't exist
    mkdir -p "${TEST_TEMP_DIR}/bin"

    # Create mock script
    cat > "${TEST_TEMP_DIR}/bin/${cmd}" <<EOF
#!/usr/bin/env bash
echo "$output"
exit $exit_code
EOF
    chmod +x "${TEST_TEMP_DIR}/bin/${cmd}"

    # Add to PATH
    export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
}

# Helper function to create mock command with custom behavior
mock_command_with_script() {
    local cmd="$1"
    local script_content="$2"

    # Create mock script directory if it doesn't exist
    mkdir -p "${TEST_TEMP_DIR}/bin"

    # Create mock script with custom content
    cat > "${TEST_TEMP_DIR}/bin/${cmd}" <<EOF
#!/usr/bin/env bash
$script_content
EOF
    chmod +x "${TEST_TEMP_DIR}/bin/${cmd}"

    # Add to PATH
    export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
}

# Helper function to assert command exists
assert_command_exists() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Command not found: $cmd"
        return 1
    }
}

# Helper function to assert file contains
assert_file_contains() {
    local file="$1"
    local pattern="$2"

    if [[ ! -f "$file" ]]; then
        echo "File not found: $file"
        return 1
    fi

    if ! grep -q "$pattern" "$file"; then
        echo "Pattern not found in $file: $pattern"
        return 1
    fi
}

# Helper function to assert file does not contain
assert_file_not_contains() {
    local file="$1"
    local pattern="$2"

    if [[ ! -f "$file" ]]; then
        echo "File not found: $file"
        return 1
    fi

    if grep -q "$pattern" "$file"; then
        echo "Pattern found in $file (should not exist): $pattern"
        return 1
    fi
}

# Helper function to create test file with content
create_test_file() {
    local file="$1"
    local content="$2"

    mkdir -p "$(dirname "$file")"
    echo "$content" > "$file"
}
