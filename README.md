# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/), these dotfiles keep shell, editor, and CLI configuration synchronized across machines. Files prefixed with `dot_` map directly to paths in `$HOME` (for example `dot_zshenv` → `~/.zshenv`).

## Tooling Overview

| Tool | Role |
| ---- | ---- |
| [chezmoi](https://www.chezmoi.io/) | Apply and template the repository contents. |
| [Antidote](https://github.com/mattmc3/antidote) | Fast Zsh plugin manager. |
| [mise](https://mise.jdx.dev/) | Install pinned runtimes via `.tool-versions`. |
| [Homebrew](https://brew.sh/) | Provision CLI tools and apps. |
| [Warp](https://www.warp.dev/) | Terminal profile stored in `dot_warp/`. |
| [Docker](https://www.docker.com/) | CLI settings in `dot_docker/`. |
| [Prettier](https://prettier.io/) | Formatter defaults from `dot_prettierrc`. |

Executable helpers live in `bin/`. Archived or inactive configs reside in `archive/`.

## Zsh Configuration

The Zsh configuration follows a modular structure inspired by [zdotdir](https://github.com/mattmc3/zdotdir):

- **`dot_config/zsh/`** — The `$ZDOTDIR` with modular Zsh configuration
  - `.zshrc` — Interactive shell configuration
  - `.zshenv` — Environment setup and XDG directories
  - `.zstyles` — Zstyle settings for plugins
  - `.zsh_plugins.txt` — Antidote plugin definitions
  - `lib/antidote.zsh` — Antidote plugin manager loader
  - `conf.d/` — Modular configuration files loaded automatically
  - `functions/` — Custom Zsh functions
  - `completions/` — Custom completion scripts

See [dot_config/zsh/README.md](dot_config/zsh/README.md) for details on the Zsh configuration.

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
