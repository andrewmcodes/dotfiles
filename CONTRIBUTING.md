# Contributing to Dotfiles

Thank you for your interest in contributing! This document provides guidelines for maintaining and improving this dotfiles repository.

## Table of Contents

- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing Guidelines](#testing-guidelines)
- [Code Style](#code-style)
- [Pull Request Process](#pull-request-process)
- [Adding New Installation Scripts](#adding-new-installation-scripts)
- [Troubleshooting](#troubleshooting)

## Development Setup

### Prerequisites

```bash
# Install test dependencies
brew install bats-core bats-support bats-assert shellcheck shfmt

# Optional: Install kcov for coverage reports
brew install kcov  # macOS
# or
sudo apt-get install kcov  # Linux
```

### Repository Structure

```
.
├── install/          # Installation scripts (testable, idempotent)
├── scripts/          # Bootstrap & utility scripts
│   └── lib/         # Shared library functions
├── tests/           # Test suite
│   ├── unit/        # Unit tests for functions
│   └── e2e/         # End-to-end integration tests
├── dot_*            # Chezmoi-managed dotfiles
├── Brewfile         # Homebrew package manifest
└── .github/         # CI/CD workflows
```

## Making Changes

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

- Keep changes focused and atomic
- Update tests for any code changes
- Update documentation if needed

### 3. Test Your Changes

```bash
# Run all tests
bats tests/

# Run specific test suite
bats tests/unit/install/
bats tests/e2e/

# Check shell script formatting
shfmt -d install/ scripts/

# Run shellcheck linter
shellcheck install/*.sh scripts/**/*.sh

# Generate coverage report
./scripts/coverage.sh
```

### 4. Format Your Code

```bash
# Auto-format shell scripts
shfmt -w install/ scripts/

# Verify formatting
shfmt -d install/ scripts/
```

## Testing Guidelines

### Writing Unit Tests

All installation scripts must have comprehensive unit tests. Follow this pattern:

**Example: `tests/unit/install/example.bats`**

```bash
#!/usr/bin/env bats

load '../../test_helper'

# Source the script to test
setup_file() {
    source "${BATS_TEST_DIRNAME}/../../../install/example.sh"
}

@test "function_name succeeds with valid input" {
    run function_name "valid_input"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected output" ]]
}

@test "function_name fails gracefully with invalid input" {
    run function_name "invalid_input"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "error message" ]]
}

@test "function_name is idempotent" {
    # Run twice, should succeed both times
    run function_name
    [ "$status" -eq 0 ]

    run function_name
    [ "$status" -eq 0 ]
}
```

### Test Coverage Goals

- **Overall**: 70%+ coverage
- **Critical scripts** (install/*): 80%+ coverage
- **Library functions** (scripts/lib/*): 75%+ coverage

### Using Mocks in Tests

```bash
# Mock a command with specific output
mock_command "brew" "Homebrew 4.0.0"

# Mock a command with custom behavior
mock_command_with_script "brew" '
if [[ "$1" == "--version" ]]; then
    echo "Homebrew 4.0.0"
elif [[ "$1" == "install" ]]; then
    echo "Installing $2..."
    exit 0
fi
'
```

## Code Style

### Shell Script Guidelines

1. **Use strict error handling:**
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   ```

2. **Source shared libraries:**
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   # shellcheck source=../scripts/lib/common.sh
   source "${SCRIPT_DIR}/../scripts/lib/common.sh"
   ```

3. **Use logging functions:**
   ```bash
   log_info "Installing package..."
   log_success "Installation complete"
   log_warning "Non-critical issue detected"
   log_error "Installation failed"
   ```

4. **Make functions testable:**
   ```bash
   # Allow sourcing for tests
   if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
       main "$@"
   fi
   ```

5. **Write idempotent scripts:**
   ```bash
   install_tool() {
       if is_tool_installed; then
           log_success "Tool already installed"
           return 0
       fi
       # ... installation logic
   }
   ```

### Naming Conventions

- **Functions**: Use lowercase with underscores: `install_homebrew`, `is_tool_installed`
- **Constants**: Use uppercase with underscores: `HOMEBREW_INSTALL_URL`
- **Variables**: Use lowercase with underscores: `local config_path`

### Documentation

- Add comments for complex logic
- Include usage examples in script headers
- Keep comments concise and focused on "why" not "what"

## Pull Request Process

### Before Submitting

1. **Ensure all tests pass:**
   ```bash
   bats tests/
   ```

2. **Verify linting:**
   ```bash
   shellcheck install/*.sh scripts/**/*.sh
   shfmt -d install/ scripts/
   ```

3. **Update documentation:**
   - Update README.md if adding new features
   - Update PLAN.md if changing architecture
   - Add inline comments for complex logic

4. **Check for sensitive data:**
   - No API keys, tokens, or passwords
   - No private email addresses or personal information
   - Use `.chezmoiignore` for sensitive files

### PR Guidelines

1. **Use descriptive titles:**
   - Good: "Add PostgreSQL installation script with tests"
   - Bad: "Update stuff"

2. **Provide context:**
   - Explain what changes were made
   - Explain why the changes were necessary
   - Link to related issues

3. **Keep PRs focused:**
   - One feature or fix per PR
   - Split large changes into multiple PRs

4. **Request review:**
   - Tag relevant reviewers
   - Respond to feedback promptly

## Adding New Installation Scripts

### 1. Create the Installation Script

**Template: `install/newtool.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
source "${SCRIPT_DIR}/../scripts/lib/common.sh"
# shellcheck source=../scripts/lib/detect.sh
source "${SCRIPT_DIR}/../scripts/lib/detect.sh"

# Constants
NEWTOOL_INSTALL_URL="https://example.com/install"

# Check if tool is installed
is_newtool_installed() {
    command -v newtool >/dev/null 2>&1
}

# Get tool version
get_newtool_version() {
    if is_newtool_installed; then
        newtool --version | awk '{print $2}'
    else
        echo "not installed"
    fi
}

# Install the tool
install_newtool() {
    if is_newtool_installed; then
        log_success "Newtool already installed ($(get_newtool_version))"
        return 0
    fi

    log_info "Installing newtool..."

    # Installation logic here
    if curl -fsSL "${NEWTOOL_INSTALL_URL}" | sh; then
        log_success "Newtool installed successfully"
        return 0
    else
        log_error "Newtool installation failed"
        return 1
    fi
}

# Verify installation
verify_newtool() {
    log_info "Verifying newtool installation..."

    if ! is_newtool_installed; then
        log_error "Newtool not found in PATH"
        return 1
    fi

    log_success "Newtool verification complete"
}

# Main entry point
main() {
    log_header "Newtool Installation"

    install_newtool
    verify_newtool

    log_success "Newtool setup complete"
}

# Allow sourcing for tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### 2. Make the Script Executable

```bash
chmod +x install/newtool.sh
```

### 3. Create Unit Tests

**Template: `tests/unit/install/newtool.bats`**

```bash
#!/usr/bin/env bats

load '../../test_helper'

setup_file() {
    source "${BATS_TEST_DIRNAME}/../../../install/newtool.sh"
}

@test "is_newtool_installed returns 0 when available" {
    mock_command "newtool" "v1.0.0"
    run is_newtool_installed
    [ "$status" -eq 0 ]
}

@test "is_newtool_installed returns 1 when not available" {
    run is_newtool_installed
    [ "$status" -eq 1 ]
}

@test "get_newtool_version returns version" {
    mock_command "newtool" "newtool version v1.0.0"
    run get_newtool_version
    [ "$status" -eq 0 ]
    [ "$output" = "v1.0.0" ]
}

@test "install_newtool skips if already installed" {
    mock_command "newtool" "v1.0.0"
    run install_newtool
    [ "$status" -eq 0 ]
    [[ "$output" =~ "already installed" ]]
}

# Add more tests...
```

### 4. Make Tests Executable

```bash
chmod +x tests/unit/install/newtool.bats
```

### 5. Run Tests

```bash
bats tests/unit/install/newtool.bats
shellcheck install/newtool.sh
```

### 6. Update Bootstrap Script (if needed)

If the tool should be installed by default, add it to `scripts/bootstrap.sh`.

## Troubleshooting

### Tests Failing

```bash
# Run tests with verbose output
bats -t tests/unit/install/yourscript.bats

# Check shellcheck errors
shellcheck -x install/yourscript.sh

# Verify script can be sourced
bash -c "source install/yourscript.sh && type function_name"
```

### Formatting Issues

```bash
# See what would change
shfmt -d install/yourscript.sh

# Apply formatting
shfmt -w install/yourscript.sh
```

### CI/CD Failures

1. Check the GitHub Actions logs
2. Run the same commands locally
3. Verify all files are committed
4. Ensure executable permissions are correct

### Common Issues

**Issue: "command not found" in tests**
- Solution: Mock the command using `mock_command`

**Issue: Tests pass locally but fail in CI**
- Solution: Check for environment-specific assumptions (PATH, HOME, etc.)

**Issue: Shellcheck warnings**
- Solution: Add shellcheck directives or fix the underlying issue

## Best Practices

1. **Write tests first** (TDD approach)
2. **Keep functions small** and focused
3. **Make scripts idempotent** (safe to run multiple times)
4. **Handle errors gracefully** with clear messages
5. **Use logging functions** for consistent output
6. **Document complex logic** with comments
7. **Test on multiple platforms** (macOS and Linux)
8. **Avoid hard-coded paths** use variables and detection
9. **Check prerequisites** before running operations
10. **Provide helpful error messages** with remediation steps

## Questions or Issues?

- Open an issue on GitHub
- Check existing issues for similar problems
- Review the plan document (PLAN.md) for architecture details
