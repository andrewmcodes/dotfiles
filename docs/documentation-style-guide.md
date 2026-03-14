# Documentation style guide

This guide captures the writing patterns used in this repository’s existing docs and defines a consistent standard for future documentation.

## Purpose

Write docs that help someone set up, use, and maintain these dotfiles quickly, with minimal ambiguity and copy-paste-ready commands.

## Voice and tone

- **Use a practical, neutral, concise voice.** Prefer direct statements over marketing language.
- **Be action-oriented.** Lead with verbs like “Install,” “Apply,” “Run,” and “Review.”
- **Be confident but factual.** State what a script or tool does without overpromising.
- **Explain just enough context.** Assume readers are technical, but do not assume they know this repo’s conventions.

### Example tone

- Good: “Executable helpers live in `bin/`.”
- Avoid: “This amazing folder contains powerful automation magic.”

## Structure conventions

Use predictable sections so readers can scan quickly.

### Recommended order for top-level docs

1. **Title (`#`)**: short and specific.
2. **One-paragraph summary**: what this doc/repo is and why it exists.
3. **Overview section (`##`)**: key components, often a table.
4. **Setup / Usage (`##`)**: numbered steps in execution order.
5. **Common commands (`##`)**: short task-oriented bullets.
6. **Layout / Architecture (`##`)**: where important files live.
7. **Testing / Validation (`##`)**: runnable checks.
8. **Appendix sections (`##`)**: optional deeper workflows (for example bootstrap details).

### Heading style

- Use **sentence case** for headings (for example, `## Tooling overview`).
- Keep headings short and concrete.
- Prefer `##` for major sections and `###` for subsections.
- Avoid skipping levels (`##` directly to `####`).

## Code and command formatting

- Use fenced code blocks with a language hint:
  - `shell` or `bash` for commands.
  - `yaml`, `toml`, etc. for config.
- Keep commands copy-pasteable:
  - Include exact commands.
  - Keep placeholders explicit, e.g. `<github-username>`.
- Use inline code for:
  - file paths (`scripts/bootstrap.sh`)
  - commands (`chezmoi apply`)
  - flags (`--debug`)
  - directory names (`bin/`, `tests/`)

## Warnings, notes, and safety

This repo’s docs favor calm inline caution over heavy callout blocks.

- Use short warning sentences near the relevant step.
- State the condition and action clearly.
- Prefer wording like:
  - “Run `brew bundle` if a Brewfile is present.”
  - “Install Homebrew (if not present).”
- Reserve emphatic language (`IMPORTANT`, `MUST`) for genuinely destructive or irreversible steps.

## Assumed reader knowledge

Assume the reader:

- Is comfortable with terminal basics and package managers.
- Understands how to run scripts and read command output.
- May be unfamiliar with this repo’s file naming and tool choices.

Therefore:

- Briefly define repo-specific conventions (for example `dot_*` file mapping).
- Link tools on first mention.
- Do not over-explain general shell fundamentals.

## Terminology and naming

- Use canonical tool names consistently: **chezmoi**, **mise**, **Homebrew**, **Warp**.
- Use “dotfiles” for the repository contents.
- Use “bootstrap script” for `scripts/bootstrap.sh`.
- Use “smoke tests” for lightweight validation checks.
- Prefer “apply” for synchronizing changes via chezmoi.

## What to avoid

- Vague instructions (“set things up as needed”).
- Large unstructured text blocks with no headings.
- Mixing multiple tasks in one step.
- Inconsistent command styles (switching between pseudo-code and runnable commands).
- Unexplained acronyms and internal shorthand.
- “Cute” tone, jokes, or opinionated commentary that obscures action.

## Documentation quality checklist

Before merging docs, confirm:

- Sections follow a clear scan-friendly structure.
- Commands are runnable and include required placeholders.
- Repo-specific terms are introduced once and reused consistently.
- Any caution is placed at the exact step where it matters.
- Testing/validation commands are provided when relevant.
