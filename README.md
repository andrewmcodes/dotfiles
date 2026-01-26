# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/), these dotfiles keep shell, editor, and CLI configuration synchronized across machines. Files prefixed with `dot_` map directly to paths in `$HOME` (for example `dot_zshenv` → `~/.zshenv`).

## Tooling Overview

| Tool | Role |
| ---- | ---- |
| [chezmoi](https://www.chezmoi.io/) | Apply and template the repository contents. |
| [mise](https://mise.jdx.dev/) | Install pinned runtimes and development tools. |
| [Homebrew](https://brew.sh/) | Provision CLI tools and apps. |
| [Warp](https://www.warp.dev/) | Terminal profile stored in `dot_warp/`. |
| [Docker](https://www.docker.com/) | CLI settings in `dot_docker/`. |
| [Prettier](https://prettier.io/) | Formatter defaults from `dot_prettierrc`. |

Executable helpers live in `bin/`. Archived or inactive configs reside in `archive/`.

## Setup

1. **Install prerequisites**
   ```shell
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   brew install chezmoi jdx/mise/mise
   ```
2. **Apply the dotfiles**
   ```shell
   chezmoi init --apply <github-username>/dotfiles
   ```
3. **Install toolchains**
   ```shell
   mise install
   ```
   Run `brew bundle` if a Brewfile is present.

## Common chezmoi Commands

- Edit and apply a file in one step: `chezmoi edit --apply <path>`
- Review pending changes: `chezmoi diff`
- Re-apply everything: `chezmoi apply`
- Adjust attributes (e.g., remove private flag): `chezmoi chattr -- -p <path>`

## Repository Layout

- `dot_*` files map to configuration files in `$HOME`.
- `bin/` contains executables linked into `~/bin`.
- `archive/` holds legacy configuration kept for reference.
- `install/` contains installation scripts for Homebrew, mise, chezmoi, and Brewfile management.
- `scripts/` contains the bootstrap orchestrator and utility scripts.
- `tests/` contains comprehensive unit and E2E tests for all installation scripts.

## Testing

This repository includes comprehensive test coverage for all installation scripts using [bats-core](https://github.com/bats-core/bats-core).

### Running Tests Locally

```bash
# Install test dependencies
brew install bats-core bats-support bats-assert shellcheck shfmt

# Run all unit tests
bats tests/unit/

# Run specific test file
bats tests/unit/install/homebrew.bats

# Check shell script formatting
shfmt -d install/ scripts/

# Run shellcheck linter
shellcheck install/*.sh scripts/**/*.sh

# Generate coverage report (requires kcov)
./scripts/coverage.sh
```

### CI/CD

- **Unit Tests**: Run on every push/PR for both macOS and Ubuntu
- **Linting**: Automatic shellcheck and shfmt validation
- **Coverage**: Code coverage tracked (target: 70%+)

### Test Structure

```
tests/
├── unit/          # Unit tests for individual functions
│   ├── install/   # Tests for installation scripts
│   └── scripts/   # Tests for library functions
├── e2e/           # End-to-end workflow tests
├── fixtures/      # Test fixtures and mocks
└── helpers/       # Test helper functions
```

## Bootstrap Script

For a fresh machine setup, use the bootstrap script:

```bash
# Clone the repository
git clone https://github.com/<username>/dotfiles.git ~/.local/share/chezmoi
cd ~/.local/share/chezmoi

# Run bootstrap (installs Homebrew, mise, chezmoi, and applies dotfiles)
./scripts/bootstrap.sh

# With options
./scripts/bootstrap.sh --help
./scripts/bootstrap.sh --debug
```

The bootstrap script will:
1. Install Homebrew (if not present)
2. Install mise for runtime management
3. Install and configure chezmoi
4. Apply dotfiles from this repository
5. Install packages from Brewfile (if present)
