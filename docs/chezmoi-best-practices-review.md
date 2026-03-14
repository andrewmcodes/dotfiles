# Chezmoi Best Practices Review

This document compares the current dotfiles setup with common dotfiles/chezmoi best practices.

## 1) Idempotency

### What is good
- Install scripts check whether tools are already installed before attempting installation (e.g., `brew`, `mise`, `chezmoi`).
- Bootstrap orchestration is split into clear steps and uses strict shell options (`set -euo pipefail`).

### Where it falls short
- `install/chezmoi.sh` always runs `chezmoi apply` after initialization, which can cause interactive prompts or side effects on each bootstrap run rather than a fully non-interactive, explicitly safe idempotent path.
- Validation in `install/homebrew.sh` runs `brew doctor`, which is useful but noisy/non-deterministic in CI and automation contexts.
- The test suite does not verify rerun behavior (e.g., running bootstrap twice and asserting no changes), so idempotency is not programmatically enforced.

## 2) Separation of concerns

### What is good
- Clear script boundaries (`install/*.sh` for installer units, `scripts/lib/*.sh` for shared helpers, bootstrap as orchestrator).
- Deployment filtering in `.chezmoiignore` avoids applying repo-only assets like CI and test files to `$HOME`.

### Where it falls short
- Homebrew source-of-truth is inconsistent across files:
  - `install/brewfile.sh` defaults to `~/.local/share/chezmoi/Brewfile`.
  - `mise.toml` tasks use `~/.config/homebrew/Brewfile` for dump/add flows.
  - README setup references a root `Brewfile`.
  This split creates drift and makes operations less predictable.
- Runtime installs and config application are tightly coupled inside bootstrap with limited mode control (e.g., no explicit dry-run / install-only / apply-only modes).

## 3) Secret hygiene

### What is good
- Some sensitivity awareness exists (for example, `private_` naming conventions and Claude permissions denying `.env` reads).

### Where it falls short
- Potentially identifying or sensitive values are committed in plaintext:
  - personal email and signing key in git config,
  - a fixed Asciinema install ID,
  - absolute user-specific local paths in Claude settings.
- The repository does not show a documented encrypted-secret workflow (e.g., chezmoi age/gpg secret templates) for sensitive machine/user-specific values.
- `.gitignore` is minimal and does not explicitly guard common local-secret artifacts in the repository root.

## 4) Reliability and portability

### Where it falls short
- Network bootstrap assumes ICMP access to `8.8.8.8`; this is blocked in some corporate/cloud environments and can fail despite working HTTPS connectivity.
- Multiple installers rely on `curl | sh` without pinning checksums/signatures, which is weaker than pinned package manager installs.

## 5) Testing and policy enforcement

### Where it falls short
- Current smoke tests validate file presence/linting/sourcing but do not validate:
  - bootstrap idempotency,
  - non-interactive behavior,
  - secret scanning,
  - cross-path consistency checks (Brewfile location expectations).

## Recommended next steps
1. Standardize on one Brewfile path and update scripts/tasks/docs together.
2. Add explicit bootstrap modes (`--dry-run`, `--install-only`, `--apply-only`) and make default non-interactive behavior explicit.
3. Introduce chezmoi secret management (`age`/`gpg` templates) and move sensitive values out of plaintext tracked files.
4. Replace ICMP-only internet checks with HTTPS-based checks.
5. Add CI checks for idempotency and secret scanning.
