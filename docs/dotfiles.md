# Dotfile management

This document explains how dotfiles move between `$HOME` and this repository, and why the manifest exists.

## The two directions

Backup is live to repository. Restore is repository to live. They are separate commands, and only one of them writes to `$HOME`.

```text
edit a real file in $HOME
        ↓
mise run dotfiles:backup
        ↓
mise copies the live file into home/
        ↓
review git diff, then commit
```

```text
clone the repository
        ↓
./scripts/restore-dotfiles.sh --apply
        ↓
mise copies home/ into $HOME as real files
        ↓
recorded modes are replayed from the manifest
```

## Why copy mode

Every entry in the `[dotfiles]` table states `mode = "copy"` explicitly. Copy mode means a restored dotfile is an ordinary file, not a symlink pointing back into a git checkout. Moving or deleting the repository cannot then break a live configuration.

The explicit `mode` matters. When mise adds an entry itself it writes no `mode` key, and the fallback is `symlink`. An entry that omits `mode` is therefore a latent symlink, which is why both the verifier and the test suite reject one.

## Why the manifest exists

Git records exactly one permission bit: whether a regular file is executable. It cannot represent `0600`, `0640`, or `0700`.

That matters here because 27 of the 158 managed files are `0600`, including everything under `home/.warp/` and `home/.claude/settings.json`. A fresh clone materializes those as `0644`, and a restore faithfully reproduces `0644`.

`config/dotfiles-manifest.tsv` is the authoritative record instead:

```text
relative_path<TAB>repo_source<TAB>sha256<TAB>mode<TAB>size
```

The checksum comes from the committed source. The mode and size come from the live file at capture time. `scripts/apply-dotfile-modes.sh` replays those modes after a restore, and the verifier treats a mode mismatch as drift.

## Per-file and directory entries

Most entries name a single file. A few name a directory, which mise copies recursively while preserving each file's mode.

Directory entries are used only where the live tree contains exactly the files listed in `config/chezmoi-baseline.txt`. Two trees deliberately use per-file entries instead:

- `~/.warp/themes` holds live theme files this repository does not manage.
- `~/bin` holds unmanaged scripts plus local tooling directories.

A directory entry there would capture those extra files on the next backup, silently widening what a public repository contains.

Three trees must never get a directory entry, because they hold untracked local files:

- `~/.config` and `~/.config/mise`, because `~/.config/mise/config.local.toml` carries a secret.
- `~/.claude`, because `settings.local.json` is deliberately gitignored.

The verifier and `tests/dotfiles.bats` both enforce that rule.

Note one limitation: because a directory copy does not delete extra files in the target, `mise bootstrap dotfiles status` cannot report an unexpected extra file inside a directory-managed tree. The verifier covers the direction that matters for a public repository: it fails if `home/` holds any file that has no manifest row, which is what would happen if a backup swept an untracked local file in.

## The coverage baseline

`config/chezmoi-baseline.txt` started as a snapshot of the files that were under management when this repository migrated from chezmoi. It is never regenerated automatically; it is the hand-maintained ledger of managed paths that the verifier measures against.

The primary invariant is that every baseline path has a manifest row. If that ever fails, the backup no longer covers everything it used to, and verification fails.

`scripts/backup-dotfiles.sh` both captures *and* generates the manifest from this file: a no-argument run iterates the baseline, so a newly listed path (with its `[dotfiles]` entry) is seeded into `home/` and given a manifest row on the next backup. A new `[dotfiles]` entry whose path is absent here never reaches the manifest, and is therefore never verified. See "Adding a new dotfile" in the README for the full sequence.

`config/baseline-exclusions.tsv` records deliberate departures from that baseline, with a reason for each.

## Safety properties

The backup script:

- passes `--no-apply` to mise on every capture, which leaves the live file's content, mode, size, and mtime untouched
- refuses a target that is not already configured, so mise cannot invent a modeless entry
- refuses symlinks and any path outside `$HOME`
- refuses to delete a repository source because a live file went missing, and exits non-zero instead
- never runs `git add`, `git commit`, or `git push`

The restore script previews by default and requires `--apply` to write. It does not offer `--force`; a conflict stops the restore.

`scripts/fingerprint-home.sh` records a read-only fingerprint of every managed live file, including mtime. Capturing it before and after a batch of work, then diffing, proves whether anything in `$HOME` changed.
