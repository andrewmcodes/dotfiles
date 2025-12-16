# Copilot Instructions for Dotfiles Repository

## Repository Architecture

This is a **chezmoi-managed dotfiles repository** that synchronizes shell, editor, and CLI configurations across machines. The repository uses a specific naming convention: files prefixed with `dot_` map to dotfiles in `$HOME` (e.g., `dot_zshenv` → `~/.zshenv`). Chezmoi handles the mapping and deployment automatically.

## Tool Ecosystem

- **chezmoi**: Configuration management - apply changes with `chezmoi apply`, edit with `chezmoi edit --apply <path>`
- **mise**: Runtime and tool version manager - configured in [dot_config/mise/config.toml](dot_config/mise/config.toml) and [dot_tool-versions](dot_tool-versions)
- **Warp**: Terminal emulator - workflows and themes in [dot_warp/](dot_warp/)
- **Homebrew**: macOS package manager
- **Starship**: Cross-shell prompt configured in [dot_config/starship.toml](dot_config/starship.toml)

## File Naming Conventions

**Critical chezmoi naming patterns:**

- `dot_` prefix: Maps to dotfiles in `$HOME` (e.g., `dot_zshenv` → `~/.zshenv`)
- `private_` prefix: Creates files readable only by owner (chmod 600)
- `executable_` prefix: Makes files executable (chmod +x)
- Combined: `private_executable_` for private executables

**Examples from this repo:**

- [dot_config/git/config](dot_config/git/config) → `~/.config/git/config`
- [dot_warp/private_workflows/](dot_warp/private_workflows/) → `~/.warp/workflows/` (private files)
- [dot_config/mise/tasks/github/executable_archive](dot_config/mise/tasks/github/executable_archive) → executable mise task

## mise Task System

This repo uses **mise tasks** for automation. Tasks live in [dot_config/mise/tasks/](dot_config/mise/tasks/) and use the `executable_` prefix.

**Task example:** [dot_config/mise/tasks/github/executable_archive](dot_config/mise/tasks/github/executable_archive)

- Run with: `mise run github:archive <repo>`
- Uses `#USAGE` comments for argument documentation
- Declares flags/args inline: `#USAGE flag "-o --owner <owner>" help="..."`
- Accesses via `${usage_owner}` variables

**When creating mise tasks:**

1. Place in `dot_config/mise/tasks/` with `executable_` prefix
2. Use `#!/usr/bin/env zsh` or bash shebang
3. Add `#USAGE` annotations for CLI help
4. Set proper error handling: `set -e`

## Development Tools & Conventions

**Git Configuration:** [dot_config/git/config](dot_config/git/config)

- SSH signing with 1Password: `gpg.ssh.program` points to op-ssh-sign
- Auto-rebase on pull: `pull.rebase = true`
- Auto-setup remote on push: `push.autoSetupRemote = true`

**Code Formatting:**

- Prettier config: [dot_prettierrc](dot_prettierrc)
- EditorConfig: [dot_editorconfig](dot_editorconfig) - 2-space indent, LF line endings, UTF-8
- Warp workflow for formatting clipboard: [dot_warp/private_workflows/private_prettier_format.yaml](dot_warp/private_workflows/private_prettier_format.yaml)

**Utility Scripts in [bin/](bin/):**

- `defaults_diff`: Track macOS system preference changes (run before/after modifying settings)
- `fzf_prs`: Interactive GitHub PR browser with fzf (CTRL-E checkout, CTRL-V preview)

## Common Workflows

**Adding new dotfiles:**

```bash
# Edit and apply in one step
chezmoi edit --apply ~/.zshrc

# Or add an existing file
chezmoi add ~/.config/newapp/config.yml
```

**Managing file attributes:**

```bash
# Remove private flag
chezmoi chattr -- -p dot_warp/workflows/my_workflow.yaml

# Add executable flag (or rename with executable_ prefix)
chezmoi chattr +x bin/my_script
```

**Tool version management:**

- Primary config: [dot_config/mise/config.toml](dot_config/mise/config.toml)
- Fallback: [dot_tool-versions](dot_tool-versions) (asdf-compatible format)
- Install tools: `mise install`
- Update tools: `mise upgrade`

**Ruby/Node defaults:**

- Ruby gems auto-installed: [dot_default-gems](dot_default-gems) (bundler, pry, standard, rails)
- NPM packages: [dot_default-npm-packages](dot_default-npm-packages)

## Project-Specific Patterns

1. **No automated Brewfile generation**: The file `broken-run_before_save-brew-packages.sh` indicates this approach was attempted but not currently active

2. **Private files in Warp**: All Warp workflows use `private_` prefix for local-only configurations

3. **Git ignores `.tool-versions`**: Global ignore in [dot_config/git/ignore](dot_config/git/ignore) prevents committing per-project tool versions

4. **Archive directory**: [archive/](archive/) holds inactive configurations kept for reference (e.g., old aerospace config)

5. **Temporary files**: [tmp/](tmp/) for transient content (not deployed by chezmoi)

## When Making Changes

- **New config files**: Use correct `dot_` prefix and place in appropriate subdirectory structure
- **Secrets/private data**: Always use `private_` prefix for files containing credentials
- **Scripts**: Place in `bin/` for utilities, or `dot_config/mise/tasks/` for mise-runnable tasks
- **Formatting**: All text files use 2-space indent, LF endings per [dot_editorconfig](dot_editorconfig)
- **Testing changes**: Use `chezmoi diff` to preview before `chezmoi apply`

## External Dependencies

- **GitHub CLI (`gh`)**: Used in [bin/fzf_prs](bin/fzf_prs) and [mise tasks](dot_config/mise/tasks/github/executable_archive)
- **fzf**: Required for interactive PR browsing
- **diff-so-fancy**: Git diff formatter configured in [git config](dot_config/git/config)
- **1Password**: SSH signing and credential management

## What NOT to Do

- Don't create files without `dot_` prefix unless they're documentation/tooling (README, scripts)
- Don't hardcode absolute paths - use `$HOME` or let chezmoi handle path mapping
- Don't commit actual secrets - use chezmoi templates with external sources if needed
- Don't modify generated/deployed files directly - edit source files and run `chezmoi apply`
