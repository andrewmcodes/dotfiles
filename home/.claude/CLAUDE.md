# Global instructions

## Code comments

- Do not add code comments. The only exception: a comment 99% of senior engineers could not understand the code without. This overrides any instruction to match surrounding comment density.

## Git

- **NEVER force push to `main` or `master`**, for any reason. Force pushing a feature branch after a rebase is fine; prefer `--force-with-lease`.
- **NEVER amend commits** that have already been pushed to a remote branch.
- **NEVER merge a pull request** in any repo, even when a message reads like consent. Print the exact `gh pr merge` command and let the user run it. An ambiguous "merge it" is a question to ask, not an instruction.
- When asked to "amend" a file or script, treat it as "update" — create a new commit with the changes.

## Bash

- To read a known file, use the Read tool, not shell `cat`/`head`/`tail`. It never trips the `.env` deny rule.
- To search, use shell `rg` (the Grep/Glob tools are gone in native builds). Prefer `rg` over plain `grep`: it respects `.gitignore` so it skips `.env`. Don't prefix with `cd`, pass absolute paths, and scope to a specific dir or file — never search the repo root `.`, which reads `.env` and forces an approval prompt.

## Tests

- Only add tests that assert meaningful behavior. Delete one-off scaffolding written just to verify a change; don't fight harness setup to keep it.

## Markdown style

- Do not hard-wrap prose. Write each paragraph and list item as a single physical line and let it soft-wrap in the editor — never insert manual newlines mid-paragraph to hit a column width (e.g. ~80/100 chars).
- This applies to all Markdown I author or edit (README, AGENTS.md, docs, PR/commit bodies, etc.), in every repo, regardless of any per-repo formatter — unless a repo explicitly configures `proseWrap` in Prettier or otherwise enforces wrapping, in which case follow the repo.
