# GitHub Copilot instructions

## Repository overview

This is a **mise-managed dotfiles repository** that synchronizes shell, editor, and CLI configuration across machines.

The mapping rule is direct: **`home/` mirrors `$HOME`**. The path under `home/` is the path under `$HOME`, with no encoded prefixes.

```text
home/.zshenv                  -> ~/.zshenv
home/.config/git/config       -> ~/.config/git/config
home/.warp/workflows/foo.yaml -> ~/.warp/workflows/foo.yaml
home/bin/fzf_prs              -> ~/bin/fzf_prs
```

This repository previously used chezmoi and its `dot_` / `private_` / `executable_` naming scheme. Those conventions are gone. Do not reintroduce them, and do not suggest `chezmoi` commands.

## Core tooling

- **mise**: manages dotfiles, packages, and toolchains. Declared in [mise.toml](../mise.toml).
- **Homebrew**: the package backend for `[bootstrap.packages]`.
- **Warp**: terminal profile in [home/.warp/](../home/.warp/).
- **Starship**: prompt configured in [home/.config/starship.toml](../home/.config/starship.toml).

The user-level mise config that gets deployed is [home/.config/mise/config.toml](../home/.config/mise/config.toml). It is distinct from the repository's own [mise.toml](../mise.toml).

## How dotfiles are declared

Entries live in the `[dotfiles]` table of [mise.toml](../mise.toml):

```toml
"~/.zshenv"        = { source = "home/.zshenv", mode = "copy" }
"~/.warp/workflows" = { source = "home/.warp/workflows", mode = "copy" }
```

**Hard rules. The verifier and test suite enforce all of these:**

1. Every entry states `mode = "copy"` explicitly. Never rely on `dotfiles.default_mode`, because an entry mise writes itself omits `mode` and falls back to `symlink`.
2. No `symlink` or `symlink-each` entry, ever.
3. No directory entry on `~/.config`, `~/.config/mise`, or `~/.claude`. Those trees hold untracked local files, including a secret in `~/.config/mise/config.local.toml`.
4. Directory entries are used only where the live tree contains exactly the baseline files. `~/.warp/themes` and `~/bin` are listed per-file because both hold live files this repository deliberately does not manage.
5. Targets stay under `$HOME`; sources stay under `home/`.

## Common workflows

Capture a live edit into the repository:

```shell
mise run dotfiles:backup
./scripts/backup-dotfiles.sh ~/.zshenv    # or a specific target
```

Verify, preview a restore, and restore:

```shell
mise run dotfiles:verify
./scripts/restore-dotfiles.sh
./scripts/restore-dotfiles.sh --apply
```

Add a new dotfile. This is intentionally explicit, so nothing reaches a public repository by accident:

1. Add a `[dotfiles]` entry with `mode = "copy"`.
2. Add the path to `config/chezmoi-baseline.txt`.
3. Run `mise run dotfiles:backup`.

The backup script refuses any target that is not already configured.

## File modes and the manifest

Git records only whether a file is executable. It cannot carry `0600`, and 23 of the 43 managed files are `0600`.

`config/dotfiles-manifest.tsv` is therefore the authoritative mode record:

```text
relative_path<TAB>repo_source<TAB>sha256<TAB>mode<TAB>size
```

Run `mise run dotfiles:modes` after a restore to replay them. Never assume a checkout's modes are correct.

## mise tasks

Deployed user tasks live in [home/.config/mise/tasks/](../home/.config/mise/tasks/) and must have the executable bit set in git (mode `100755`). There is no filename prefix that conveys executability any more.

Repository tasks are defined in [mise.toml](../mise.toml): `dotfiles:backup`, `dotfiles:restore`, `dotfiles:verify`, `dotfiles:modes`, `dotfiles:fingerprint`, `lint`, `test`, `ci`.

## Shell script conventions

Every script in `scripts/` follows the same shape:

- `#!/usr/bin/env bash`, then `# shellcheck disable=SC1091,SC2119,SC2120`
- `set -euo pipefail` in executables; libraries omit it because they are sourced
- `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` before any `source`
- a `# shellcheck source=` directive before each `source`
- tab indentation
- libraries guard against double-sourcing with `readonly _<NAME>_SH_LOADED=1`
- all scripts must be ShellCheck-clean

Shared helpers are in [scripts/lib/common.sh](../scripts/lib/common.sh) (logging, `die`, `require_command`) and [scripts/lib/dotfiles.sh](../scripts/lib/dotfiles.sh) (repo paths, path validation, manifest generation, the `dotfiles.root` safety guard).

## Testing

```shell
brew install bats-core shellcheck
mise run ci
```

The dotfile tests build an isolated `$HOME` inside `$BATS_TEST_TMPDIR` and **abort** if that isolation fails. Overriding `HOME` alone does not isolate mise, so `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_DATA_HOME`, and `XDG_STATE_HOME` must be overridden too. Never write a test that could touch the real `$HOME`.

## What not to do

- Don't reintroduce `dot_`, `private_`, or `executable_` prefixes.
- Don't suggest `chezmoi` commands; the tool is no longer used here.
- Don't add a `[dotfiles]` entry without an explicit `mode = "copy"`.
- Don't add a directory entry on `~/.config`, `~/.config/mise`, or `~/.claude`.
- Don't hardcode absolute paths; use `$HOME` or paths relative to the repository root.
- Don't commit secrets. `~/.config/mise/config.local.toml` holds a token and is deliberately unmanaged.
- Don't have a backup path write to `$HOME`. Capture always passes `--no-apply`.
