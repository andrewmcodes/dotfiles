# Dotfiles

Managed with [mise](https://mise.jdx.dev/), these dotfiles keep shell, editor, and CLI configuration synchronized across machines. The `home/` directory mirrors `$HOME` exactly: `home/.zshenv` is `~/.zshenv`, and `home/.config/git/config` is `~/.config/git/config`.

Every dotfile is managed in mise's `copy` mode, so restored files are real files rather than symlinks into this repository.

## Tooling overview

| Tool | Role |
| ---- | ---- |
| [mise](https://mise.jdx.dev/) | Manage dotfiles, install pinned runtimes, and provision packages. |
| [Homebrew](https://brew.sh/) | Package backend for `[bootstrap.packages]`. |
| [Warp](https://www.warp.dev/) | Terminal profile stored in `home/.warp/`. |
| [Prettier](https://prettier.io/) | Formatter defaults from `home/.prettierrc`. |

Executable helpers live in `home/bin/`, which maps to `~/bin`. Archived or inactive configs reside in `archive/`.

## Setup

On a new machine:

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install mise
git clone https://github.com/<github-username>/dotfiles.git ~/git/<github-username>/dotfiles
cd ~/git/<github-username>/dotfiles
mise trust
mise bootstrap
```

`mise trust` is required once per clone. A fresh checkout is not in mise's trust store, and mise refuses to load an untrusted `mise.toml`, so every `mise` command against this repository fails until it is trusted.

`mise bootstrap` installs the declared packages, applies the dotfiles, and installs the pinned toolchains in one pass.

After a restore, replay the recorded file modes. Git records only whether a file is executable, so modes such as `0600` come from the manifest rather than from the checkout:

```shell
mise run dotfiles:modes
```

## Daily workflow

Edit the real file in `$HOME`, then capture it:

```shell
cd ~/git/<github-username>/dotfiles
git pull --ff-only

mise run dotfiles:backup

git diff
git add home config/dotfiles-manifest.tsv
git commit -m "Back up dotfiles"
git push
```

Back up selected files only:

```shell
./scripts/backup-dotfiles.sh ~/.zshenv ~/.config/git/config
```

The backup direction is always live to repository. It never writes to `$HOME`, never deletes a live file, and never commits.

## Restoring

Preview first; the preview writes nothing:

```shell
./scripts/restore-dotfiles.sh
```

Apply for real, which copies files into `$HOME`, replays recorded modes, then verifies:

```shell
./scripts/restore-dotfiles.sh --apply
```

## Verifying

```shell
mise run dotfiles:verify
```

The verifier's primary invariant is coverage: every path in `config/chezmoi-baseline.txt` must have a row in `config/dotfiles-manifest.tsv`. It also checks checksums, modes, symlink absence, and the configuration safety rules.

## Repository layout

- `home/` mirrors `$HOME`; the path under `home/` is the path under `$HOME`.
- `mise.toml` declares dotfile entries, bootstrap packages, and repository tasks.
- `config/dotfiles-manifest.tsv` records the checksum, mode, and size of every managed file.
- `config/chezmoi-baseline.txt` is the frozen coverage baseline captured at migration time.
- `config/baseline-exclusions.tsv` records deliberate exclusions from that baseline.
- `scripts/` contains the backup, restore, verification, and mode-replay scripts.
- `tests/` contains the Bats suites.
- `archive/` holds legacy configuration kept for reference.

## Adding a new dotfile

Adding files is deliberately explicit, so nothing lands in a public repository by accident:

1. Add an entry to the `[dotfiles]` table in `mise.toml` with `mode = "copy"` stated explicitly.
2. Add the path to `config/chezmoi-baseline.txt`.
3. Run `mise run dotfiles:backup`.

The backup script refuses any target that is not already configured.

## Documentation

See `docs/dotfiles.md` for how backup, restore, and mode preservation work. For writing conventions used in this repository, see `docs/documentation-style-guide.md`.

## Testing

```shell
brew install bats-core shellcheck
mise run ci
```

`mise run ci` runs ShellCheck and both Bats suites. The dotfile tests build an isolated `$HOME` inside the Bats temp directory and abort if that isolation fails, so they never touch real dotfiles.
