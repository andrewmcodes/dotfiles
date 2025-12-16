#!/usr/bin/env bash
# Custom assertions for bats tests

# Assert that a directory exists
assert_dir_exists() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo "Directory does not exist: $dir"
        return 1
    fi
}

# Assert that a directory does not exist
assert_dir_not_exists() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        echo "Directory exists (should not): $dir"
        return 1
    fi
}

# Assert that a file exists
assert_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "File does not exist: $file"
        return 1
    fi
}

# Assert that a file does not exist
assert_file_not_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo "File exists (should not): $file"
        return 1
    fi
}

# Assert that a file is executable
assert_file_executable() {
    local file="$1"
    if [[ ! -x "$file" ]]; then
        echo "File is not executable: $file"
        return 1
    fi
}

# Assert that a file is not empty
assert_file_not_empty() {
    local file="$1"
    if [[ ! -s "$file" ]]; then
        echo "File is empty: $file"
        return 1
    fi
}

# Assert that output contains a string
assert_output_contains() {
    local expected="$1"
    if [[ ! "$output" =~ $expected ]]; then
        echo "Output does not contain: $expected"
        echo "Actual output: $output"
        return 1
    fi
}

# Assert that output does not contain a string
assert_output_not_contains() {
    local unexpected="$1"
    if [[ "$output" =~ $unexpected ]]; then
        echo "Output contains (should not): $unexpected"
        echo "Actual output: $output"
        return 1
    fi
}

# Assert that output equals a string (exact match)
assert_output_equals() {
    local expected="$1"
    if [[ "$output" != "$expected" ]]; then
        echo "Output does not match"
        echo "Expected: $expected"
        echo "Actual: $output"
        return 1
    fi
}

# Assert that a variable is set
assert_variable_set() {
    local var_name="$1"
    if [[ -z "${!var_name:-}" ]]; then
        echo "Variable is not set: $var_name"
        return 1
    fi
}

# Assert that a variable is not set
assert_variable_not_set() {
    local var_name="$1"
    if [[ -n "${!var_name:-}" ]]; then
        echo "Variable is set (should not be): $var_name=${!var_name}"
        return 1
    fi
}

# Assert that exit status equals expected value
assert_status_equals() {
    local expected="$1"
    if [[ "$status" != "$expected" ]]; then
        echo "Exit status does not match"
        echo "Expected: $expected"
        echo "Actual: $status"
        return 1
    fi
}

# Assert that exit status is success (0)
assert_success() {
    if [[ "$status" -ne 0 ]]; then
        echo "Command failed with exit status: $status"
        echo "Output: $output"
        return 1
    fi
}

# Assert that exit status is failure (non-zero)
assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        echo "Command succeeded (expected failure)"
        echo "Output: $output"
        return 1
    fi
}
