Great! I’ll update the plan with `actions/checkout@v6` and incorporate `mise` for tool management.

## Updated Plan for Adding Tests to Your Chezmoi Dotfiles Repository (with mise)

### Phase 1: Repository Structure Setup

**1. Reorganize your repository into three main directories:**

```
your-dotfiles/
├── home/                    # Chezmoi-managed dotfiles
│   ├── dot_bashrc
│   ├── dot_zshrc
│   ├── dot_config/
│   │   ├── mise/
│   │   │   └── config.toml
│   │   └── git/
│   │       └── config.tmpl
│   ├── dot_tool-versions    # mise configuration
│   └── .chezmoi.yaml.tmpl
│
├── install/                 # Installation scripts (testable)
│   ├── common/             # Cross-platform scripts
│   │   └── mise.sh         # mise installation
│   ├── macos/              # macOS-specific scripts
│   └── ubuntu/             # Ubuntu-specific scripts
│
├── tests/                   # Automated tests
│   ├── install/            # Tests for installation scripts
│   │   └── common/
│   │       └── mise.bats
│   └── files/              # Tests for deployed files
│       ├── common.bats
│       └── mise.bats
│
└── scripts/                # Helper scripts
    └── run_unit_test.sh    # Coverage measurement script
```

**2. Configure chezmoi to use `home/` as the source directory:**

- Create `.chezmoiroot` file in repository root with content: `home`

### Phase 2: Make Installation Scripts Testable (mise-focused)

**1. Create `install/common/mise.sh`:**

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# Debug mode
if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# Check if mise exists
function is_mise_installed() {
    command -v mise &>/dev/null
}

# Install mise
function install_mise() {
    if ! is_mise_installed; then
        echo "Installing mise..."
        curl https://mise.run | sh

        # Add mise to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"

        # Verify installation
        if ! is_mise_installed; then
            echo "Error: mise installation failed"
            return 1
        fi
    else
        echo "mise is already installed"
    fi
}

# Activate mise in shell
function configure_mise() {
    echo "Configuring mise..."

    # Add to shell configuration if not already present
    local shell_config=""
    if [ -f "$HOME/.zshrc" ]; then
        shell_config="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        shell_config="$HOME/.bashrc"
    fi

    if [ -n "$shell_config" ]; then
        if ! grep -q 'mise activate' "$shell_config" 2>/dev/null; then
            echo 'eval "$(mise activate bash)"' >> "$shell_config"
        fi
    fi
}

# Install tools from mise configuration
function install_mise_tools() {
    if [ -f "$HOME/.tool-versions" ] || [ -f "$HOME/.config/mise/config.toml" ]; then
        echo "Installing tools from mise configuration..."
        mise install
    fi
}

# Main function
function main() {
    install_mise
    configure_mise
    install_mise_tools
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
```

**2. Create platform-specific scripts that use mise:**

`install/macos/common/brew.sh`:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function is_brew_installed() {
    command -v brew &>/dev/null
}

function install_brew() {
    if ! is_brew_installed; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add brew to PATH
        if [[ $(uname -m) == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
}

function main() {
    install_brew
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
```

**3. Create example mise configuration in `home/dot_tool-versions`:**

```
nodejs 20.11.0
python 3.12.1
terraform 1.7.0
kubectl 1.29.0
```

Or `home/dot_config/mise/config.toml`:

```toml
[tools]
nodejs = "20.11.0"
python = "3.12.1"
terraform = "1.7.0"
kubectl = "1.29.0"

[env]
_.python.venv = { path = ".venv", create = true }
```

### Phase 3: Implement Unit Tests with Bats

**1. Create `tests/install/common/mise.bats`:**

```bash
#!/usr/bin/env bats

setup() {
    # Save original PATH
    export ORIGINAL_PATH="$PATH"
    # Add mise to PATH if installed
    export PATH="$HOME/.local/bin:$PATH"
}

teardown() {
    # Restore original PATH
    export PATH="$ORIGINAL_PATH"
}

@test "mise installation script exists" {
    [ -f "install/common/mise.sh" ]
}

@test "mise installation script is executable" {
    [ -x "install/common/mise.sh" ]
}

@test "mise installation script runs without errors" {
    run bash install/common/mise.sh
    [ "$status" -eq 0 ]
}

@test "mise command is available after installation" {
    run command -v mise
    [ "$status" -eq 0 ]
}

@test "mise version can be checked" {
    run mise --version
    [ "$status" -eq 0 ]
}

@test "mise can list installed tools" {
    run mise list
    [ "$status" -eq 0 ]
}

@test "mise doctor runs successfully" {
    run mise doctor
    [ "$status" -eq 0 ]
}
```

**2. Create `tests/install/macos/common/brew.bats`:**

```bash
#!/usr/bin/env bats

@test "brew installation script exists" {
    [ -f "install/macos/common/brew.sh" ]
}

@test "brew installation script is executable" {
    [ -x "install/macos/common/brew.sh" ]
}

@test "brew installation script runs without errors" {
    skip "Only run on macOS in CI"
    run bash install/macos/common/brew.sh
    [ "$status" -eq 0 ]
}

@test "brew command is available after installation" {
    skip "Only run on macOS in CI"
    run command -v brew
    [ "$status" -eq 0 ]
}
```

**3. Create `tests/files/mise.bats` for deployed configuration:**

```bash
#!/usr/bin/env bats

@test "mise configuration exists in home directory" {
    # Check for either .tool-versions or mise config.toml
    [ -f "$HOME/.tool-versions" ] || [ -f "$HOME/.config/mise/config.toml" ]
}

@test "mise is activated in shell configuration" {
    if [ -f "$HOME/.zshrc" ]; then
        run grep -q "mise activate" "$HOME/.zshrc"
        [ "$status" -eq 0 ]
    fi
}

@test "mise tools are installed from configuration" {
    run mise list
    [ "$status" -eq 0 ]
    # Check output contains at least one tool
    [ -n "$output" ]
}

@test "specific tools are available via mise" {
    # Test for tools defined in your configuration
    run mise which node
    [ "$status" -eq 0 ]

    run mise which python
    [ "$status" -eq 0 ]
}
```

### Phase 4: GitHub Actions Workflows

**1. Create `.github/workflows/test.yml` for unit testing:**

```yaml
name: Unit Tests

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}

    steps:
      - name: Checkout repository
        uses: actions/checkout@v6

      - name: Install Bats
        run: |
          if [[ "${{ matrix.os }}" == "ubuntu-latest" ]]; then
            sudo apt-get update && sudo apt-get install -y bats
          else
            brew install bats-core
          fi

      - name: Run common installation script tests
        run: bats tests/install/common/

      - name: Run platform-specific tests (macOS)
        if: matrix.os == 'macos-latest'
        run: bats tests/install/macos/

      - name: Run platform-specific tests (Ubuntu)
        if: matrix.os == 'ubuntu-latest'
        run: bats tests/install/ubuntu/

      - name: Install kcov for coverage (Ubuntu only)
        if: matrix.os == 'ubuntu-latest'
        run: |
          sudo apt-get install -y kcov

      - name: Run tests with coverage
        if: matrix.os == 'ubuntu-latest'
        run: bash scripts/run_unit_test.sh

      - name: Upload coverage to Codecov
        if: matrix.os == 'ubuntu-latest'
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage/cobertura.xml
          flags: unittests
          token: ${{ secrets.CODECOV_TOKEN }}
```

**2. Create `.github/workflows/e2e-setup.yml` for end-to-end testing:**

```yaml
name: End-to-End Setup Test

on:
  schedule:
    - cron: "0 0 * * 5" # Every Friday at midnight
  workflow_dispatch: # Manual trigger

jobs:
  e2e-test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-14]
        system: [client, server]
        exclude:
          - os: macos-14
            system: server
      fail-fast: false

    runs-on: ${{ matrix.os }}

    steps:
      - name: Set environment variables
        run: |
          echo "SYSTEM_TYPE=${{ matrix.system }}" >> $GITHUB_ENV

      - name: Execute setup script (macOS)
        if: matrix.os == 'macos-14'
        run: |
          bash -c "$(curl -fsLS https://your-domain.com/dotfiles/setup.sh)"

      - name: Execute setup script (Ubuntu)
        if: matrix.os == 'ubuntu-latest'
        run: |
          bash -c "$(wget -qO - https://your-domain.com/dotfiles/setup.sh)"

      - name: Verify chezmoi installation
        run: |
          command -v chezmoi
          chezmoi --version

      - name: Verify mise installation
        run: |
          export PATH="$HOME/.local/bin:$PATH"
          command -v mise
          mise --version

      - name: Verify dotfiles applied
        run: |
          [ -f "$HOME/.zshrc" ] || exit 1
          [ -f "$HOME/.bashrc" ] || exit 1
          [ -f "$HOME/.tool-versions" ] || [ -f "$HOME/.config/mise/config.toml" ] || exit 1

      - name: Verify mise tools installed
        run: |
          export PATH="$HOME/.local/bin:$PATH"
          eval "$(mise activate bash)"
          mise list
          # Verify specific tools are available
          command -v node
          command -v python

      - name: Checkout repository for tests
        uses: actions/checkout@v6
        with:
          path: dotfiles-test

      - name: Run post-deployment tests
        run: |
          cd dotfiles-test
          # Install bats if not available
          if ! command -v bats &>/dev/null; then
            if [[ "${{ matrix.os }}" == "ubuntu-latest" ]]; then
              sudo apt-get update && sudo apt-get install -y bats
            else
              brew install bats-core
            fi
          fi
          bats tests/files/

      - name: Test mise tool functionality
        run: |
          export PATH="$HOME/.local/bin:$PATH"
          eval "$(mise activate bash)"

          # Test Node.js
          node --version
          npm --version

          # Test Python
          python --version
          pip --version
```

**3. Create `.github/workflows/mise-update-check.yml` for dependency updates:**

````yaml
name: Check mise Tool Updates

on:
  schedule:
    - cron: "0 0 * * 1" # Every Monday
  workflow_dispatch:

jobs:
  check-updates:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v6

      - name: Install mise
        run: |
          curl https://mise.run | sh
          echo "$HOME/.local/bin" >> $GITHUB_PATH

      - name: Apply dotfiles (to get mise config)
        run: |
          # Copy mise configuration from home/ directory
          mkdir -p ~/.config/mise
          if [ -f "home/dot_tool-versions" ]; then
            cp home/dot_tool-versions ~/.tool-versions
          fi
          if [ -f "home/dot_config/mise/config.toml" ]; then
            cp home/dot_config/mise/config.toml ~/.config/mise/config.toml
          fi

      - name: Check for outdated tools
        run: |
          mise install
          mise outdated

      - name: Generate update report
        run: |
          echo "# mise Tool Update Report" > update-report.md
          echo "" >> update-report.md
          echo "Run \`mise outdated\` to see available updates:" >> update-report.md
          echo '```' >> update-report.md
          mise outdated >> update-report.md || echo "All tools are up to date" >> update-report.md
          echo '```' >> update-report.md

      - name: Create issue if updates available
        uses: peter-evans/create-issue-from-file@v5
        with:
          title: "mise Tool Updates Available"
          content-filepath: update-report.md
          labels: dependencies, mise
````

### Phase 5: Code Coverage Integration

**1. Create `scripts/run_unit_test.sh`:**

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

COVERAGE_DIR="coverage"
rm -rf "$COVERAGE_DIR"
mkdir -p "$COVERAGE_DIR"

# Run tests with coverage for common scripts
echo "Running tests for common scripts..."
for test_file in tests/install/common/*.bats; do
    echo "Testing: $test_file"
    kcov --clean \
         --include-path=install/common/ \
         --exclude-path=tests/ \
         "$COVERAGE_DIR/$(basename $test_file .bats)" \
         bats "$test_file" || true
done

# Run tests with coverage for platform-specific scripts
if [ -d "tests/install/ubuntu" ]; then
    echo "Running tests for Ubuntu scripts..."
    for test_file in tests/install/ubuntu/**/*.bats; do
        echo "Testing: $test_file"
        kcov --clean \
             --include-path=install/ubuntu/ \
             --exclude-path=tests/ \
             "$COVERAGE_DIR/$(basename $test_file .bats)" \
             bats "$test_file" || true
    done
fi

# Generate combined report
echo "Generating merged coverage report..."
kcov --merge "$COVERAGE_DIR/merged" "$COVERAGE_DIR"/*

echo "Coverage report generated in $COVERAGE_DIR/merged"
```

**2. Create `.codecov.yml` for coverage configuration:**

```yaml
coverage:
  status:
    project:
      default:
        target: 80%
        threshold: 5%
    patch:
      default:
        target: 80%

comment:
  layout: "reach,diff,flags,tree"
  behavior: default
  require_changes: false

ignore:
  - "tests/"
  - "scripts/"
```

### Phase 6: mise-specific Testing Strategy

**1. Create `tests/install/common/mise-tools.bats` for tool-specific tests:**

```bash
#!/usr/bin/env bats

setup() {
    export PATH="$HOME/.local/bin:$PATH"
    if command -v mise &>/dev/null; then
        eval "$(mise activate bash)"
    fi
}

@test "nodejs is installed via mise" {
    run mise which node
    [ "$status" -eq 0 ]
}

@test "nodejs version matches configuration" {
    if [ -f "$HOME/.tool-versions" ]; then
        expected_version=$(grep nodejs "$HOME/.tool-versions" | awk '{print $2}')
        run node --version
        [[ "$output" == *"$expected_version"* ]]
    else
        skip "No .tool-versions file found"
    fi
}

@test "python is installed via mise" {
    run mise which python
    [ "$status" -eq 0 ]
}

@test "python version matches configuration" {
    if [ -f "$HOME/.tool-versions" ]; then
        expected_version=$(grep python "$HOME/.tool-versions" | awk '{print $2}')
        run python --version
        [[ "$output" == *"$expected_version"* ]]
    else
        skip "No .tool-versions file found"
    fi
}

@test "mise can install new tools" {
    run mise use nodejs@latest
    [ "$status" -eq 0 ]
}

@test "mise plugins are properly configured" {
    run mise plugins list
    [ "$status" -eq 0 ]
    [[ "$output" == *"nodejs"* ]]
    [[ "$output" == *"python"* ]]
}
```

### Phase 7: Development Workflow with mise

**Test-Driven Development Process:**

1. **Adding a new tool via mise:**

   ```bash
   # Add tool to mise configuration
   mise use nodejs@20.11.0

   # Update your dotfiles
   chezmoi add ~/.tool-versions
   # or
   chezmoi add ~/.config/mise/config.toml

   # Write test
   # tests/install/common/mise-tools.bats

   # Run test locally
   bats tests/install/common/mise-tools.bats

   # Commit and push
   ```

1. **Testing mise installation script:**

   ```bash
   # Test locally
   DOTFILES_DEBUG=1 bash install/common/mise.sh

   # Run unit tests
   bats tests/install/common/mise.bats

   # Check in fresh container
   docker run -it --rm -v $(pwd):/dotfiles ubuntu:latest bash
   cd /dotfiles && bash install/common/mise.sh
   ```

1. **Updating tool versions:**

   ```bash
   # Check for updates
   mise outdated

   # Update specific tool
   mise use nodejs@20.12.0

   # Test new version
   bats tests/install/common/mise-tools.bats

   # Update dotfiles
   chezmoi add ~/.tool-versions
   ```

### Expected Benefits with mise Integration

1. **Unified tool management:** Single source of truth for all development tools
1. **Version consistency:** Same tool versions across all machines and CI
1. **Fast installation:** mise handles downloads and compilation efficiently
1. **Testable versions:** Verify exact tool versions are installed
1. **Easy updates:** Simple workflow for updating dependencies
1. **Cross-platform:** Works on macOS, Linux, and WSL
1. **CI/CD friendly:** Reproducible builds in GitHub Actions

This updated plan leverages mise’s strengths while maintaining the testability focus from the original article.​​​​​​​​​​​​​​​​
