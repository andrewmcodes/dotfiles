---
name: daily-log-updater
description: Update Andrew's digital-brain daily log file with the day's work activity — git commits across the Podia repo and personal repos, Linear issues created/commented/transitioned, and GitHub PRs/repos opened/merged/reviewed/created. Defaults to today (Pacific time). Use this skill whenever Andrew asks to update his log, fill in his daybook/journal, recap "what did I do today/yesterday", log activity for a specific date, or asks to capture the day's work — even when he doesn't explicitly say "skill". Also use when he asks for a daily standup summary or end-of-day write-up.
---

# Daily Log Updater

Andrew keeps a daily log under `/Users/andrew.mason/git/andrewmcodes/digital-brain/logs/days/YYYY-MM-DD.md`. This skill fills the `## Log` section with checkbox entries derived from real activity across git, Linear, and GitHub for a given Pacific-time day.

## Sources

For the target day (always interpreted in **America/Los_Angeles**, since Andrew is in PT), pull from:

1. **Git** — commits authored by Andrew across the Podia repo (`/Users/andrew.mason/git/work/podia`, with worktrees) and every personal repo under `/Users/andrew.mason/git/andrewmcodes/`. The bundled script handles timezone math, worktree de-duplication, and SHA-dedup across repos.
2. **Linear** — issues Andrew created, completed, or transitioned status on, plus comments he wrote. The bundled script wraps the `linear` CLI (preferred over the `mcp__linear-server__*` tools per Andrew's `CLAUDE.local.md`) and PT-trims the results.
3. **GitHub** — PRs Andrew opened or had merged across both `podia` and `andrewmcodes` owners, plus reviews + inline review comments, plus any brand-new repos he created on his personal account that day. Use the bundled script.

Always pull from all three. Even if git looks empty, check Linear and GitHub — comments, reviews, and new-repo creation don't always have a corresponding commit visible locally.

## Workflow

### 1. Resolve the target date

If the user gave a date (e.g. "update my log for 2026-05-03"), use that. Otherwise default to today in PT. Confirm the date in your first status message so the user can correct you before any work happens.

### 2. Gather raw activity (run in parallel)

Run all three in parallel — they're independent.

**Git:**
```bash
python3 /Users/andrew.mason/.claude/skills/daily-log-updater/scripts/git_activity.py YYYY-MM-DD
```
Returns JSON: list of `{sha, short, datetime_pt, subject, branches, repo, mechanical}` covering both the Podia repo and every personal repo under `~/git/andrewmcodes/`. The `repo` field is the basename of the repo's local directory (`podia`, `DropSwipe`, `forem_lite`, …) — use it to separate Podia work from personal work when synthesizing entries. The `mechanical` field is `true` for automated commits (Mac backup script, vault activity tracker, etc.) that should be ignored when synthesizing. Empty list if no commits.

**GitHub:**
```bash
python3 /Users/andrew.mason/.claude/skills/daily-log-updater/scripts/github_activity.py YYYY-MM-DD
```
Returns JSON with four lists: `authored_prs` (opened or merged that day, across both `podia` and `andrewmcodes`), `reviews` (PRs Andrew reviewed, with inline comments), `pr_comments` (top-level PR comments), and `created_repos` (brand-new personal repos created that day — surfaces things like new side projects that have no PR yet).

**Linear:**
```bash
python3 /Users/andrew.mason/.claude/skills/daily-log-updater/scripts/linear_activity.py YYYY-MM-DD
```
Returns JSON already PT-trimmed with three lists plus a projects map: `issues` (assigned to Andrew, touched that day — each with `state`, `state_type`, `project`, `completedAt`), `created` (issues Andrew filed that day), `comments` (comments he wrote, each with its `issue_identifier`/`issue_title`/`issue_url`), and `projects` (a map keyed by Linear project name holding the metadata needed to create a matching vault project note — `id`, `url`, `state`, `startDate`, `targetDate`, `lead`). This replaces the old firehose `linear issue query --all-teams` dump (~57 KB of unused fields) — the script queries `linear api` server-side by assignee and requests only the fields the log needs.

Notes on the data:
- **Issues are filtered by assignee**, so an issue Andrew *touched but isn't assigned to* (e.g. he only commented) won't appear in `issues` — the `comments` list is the safety net for those. Cross-reference any status change (e.g. → *Merged*) against the GitHub PRs so you produce one combined bullet, not two.
- Drop CC-only mentions and one-word acks from `comments`.

If you ever need a raw query the script doesn't cover, use the `linear` CLI (`linear api '<graphql>'`), preferred over the MCP per Andrew's `CLAUDE.local.md`. Andrew's Linear user id is `f84f3997-690e-4238-9e22-ca1c7c5f0583` (re-fetch with `linear api 'query { viewer { id } }'` if it stops matching). **Quoting gotcha:** inline the literal user id into the single-quoted GraphQL string; wrapping it in a shell variable with nested double-quotes (`"'"$UID"'"`) fails with a confusing `failed to change user ID: operation not permitted` error. The Linear API only accepts UTC-bounded windows, so raw queries need PT-trimming yourself — the three scripts already handle that for their data.

### 3. Synthesize entries

Group the raw data into checkbox bullets that read as natural English. Each bullet should describe **what Andrew did**, not just dump data. Combine related signals — e.g. if there are commits, a PR, and a Linear status change all for PODIA-9028, that's *one* bullet, not three.

**Format conventions** (match Andrew's existing style — look at the file before writing):

- Top-level bullet: `- [x] <action verb> ...`
- Link Podia Linear tickets as `[[PODIA-NNNN]]` Obsidian wikilinks — **not** a Markdown link to Linear. The wikilink resolves to the ticket's task note at `projects/tasks/PODIA-NNNN.md`, which `ensure_task_notes.py` creates (see step 4). The task note holds the Linear link, the PR(s), and status; the log bullet just needs the `[[PODIA-NNNN]]` ref plus a short description of what changed.
- **Do not link Podia PRs inline in the log.** A Podia ticket's PRs live on its task note (in the `### PRs` list and the `github_url` frontmatter), not in the day bullet — `ensure_task_notes.py` folds them in. Only mention a PR number in the log when it has **no** ticket (rare). Personal-repo PRs (no ticket) are still linked inline as `[andrewmcodes/repo#NN](https://github.com/andrewmcodes/repo/pull/NN)`.
- Link projects (Podia or personal) as `[[Project Name]]` Obsidian wikilinks. For Podia work, pull the project name from the Linear issue's `project` field and append " Project" (this matches Andrew's existing notes and is the exact name `ensure_project_notes.py` creates — see step 4, so the wikilink always resolves). For personal side projects with a known vault note (e.g. DropSwipe), use the repo's display name.
- Wrap code symbols in backticks: `` `PerformFeatureChangesJob` ``, `` `TierChangeResolver` ``
- Use *italics* for Linear statuses: *In PR*, *Merged*, *In Review*

**Bucketing guidance (Podia work):**

Ticket refs are `[[PODIA-X]]` wikilinks (the PR link lives on the task note, not here). Keep the project wikilink and the ticket wikilink both when it reads naturally.

| Activity | Phrasing pattern |
|---|---|
| Merged PR | `Merged [[Project]] ticket [[PODIA-X]] (now *Merged*) — <one-line of what shipped>` |
| Opened PR (still in progress) | `Worked on [[PODIA-X]] (now *In PR*) — <one-line of what changed>` |
| Pushed commits to existing PR | `Pushed <short summary of commits> for [[PODIA-X]] (still *In PR*)` |
| Code review given | `Reviewed PR [#N](url) ([[PODIA-X]]) for <Author> — <one-line digest of what feedback covered>` (reviews are of **someone else's** PR, so the PR link stays) |
| New Linear issue filed | `Filed new [[Project]] tickets: [[PODIA-X]], …` (one bullet, comma-separated, if multiple in same project) |
| Substantive Linear comment | `Commented on [[PODIA-X]] — <one-sentence gist>` or `Answered <Person>'s question on [[PODIA-X]] with <gist>` |

**Bucketing guidance (personal work):**

Personal-repo commits don't have Linear tickets, so identify them by the `repo` field on each commit (and by repos in `created_repos` from the GitHub script). Group them by repo or by sweep theme. **Critical:** the `digital-brain` repo accumulates large volumes of automated commits (Mac backup script, vault activity tracker) on top of real work. Always look past `mechanical: true` commits to find substantive ones — if a personal repo has *any* non-mechanical commit on the target day, that's real work that belongs in the log. Don't dismiss a personal repo as "all noise" without verifying every non-mechanical commit was considered.

| Activity | Phrasing pattern |
|---|---|
| New personal repo created | `Started a new personal project [[Repo Name]] — created the [andrewmcodes/repo](https://github.com/andrewmcodes/repo) repo and spiked the initial …` |
| Substantive work in a personal project | `Shipped <feature summary> in [[Repo Name]]` — combine the day's commits in that repo into one descriptive bullet rather than listing them individually |
| Mass sweep across many personal repos (LICENSE bump, CI modernization, dependency bumps) | One single bullet: `Ran a personal-repos maintenance sweep across N repos (\`repo1\`, \`repo2\`, …) — <theme 1>, <theme 2>, …`. Enumerate the repos in backticks and describe the themes briefly. Don't open one bullet per repo. |
| Personal PR opened or merged | Use the same Merged/Opened patterns as Podia, but link the repo-qualified PR URL |

Drop trivia. A one-word "+1" comment isn't a bullet. Status-only auto-transitions aren't bullets. WIP commits aren't bullets unless they're the only signal of work that day. Trust the user's time — if the day was light, the log should be light.

### 4. Ensure linked project and task notes exist

Every `[[<Name> Project]]` and `[[PODIA-NNNN]]` wikilink in the log needs a matching note, or it dangles. Run both scripts before (or right after) writing the log — they're independent, so run them in parallel:

```bash
python3 /Users/andrew.mason/.claude/skills/daily-log-updater/scripts/ensure_project_notes.py --date YYYY-MM-DD
python3 /Users/andrew.mason/.claude/skills/daily-log-updater/scripts/ensure_task_notes.py --date YYYY-MM-DD
```

**Project notes** (`ensure_project_notes.py`): reads the `projects` map from `linear_activity.py`, and for each project with no existing note, creates one from the DKS project template (`digital-brain/util/obj_tmpl/project.tmpl.md`, per `digital-brain/_meta/schema.json`) filled with the Linear metadata — `status` mapped from Linear's project state, `start_on`/`end_on` from the project dates, `project_url` (normalized to the `/overview` URL), and `linear_id` (the project slug). It is **create-if-missing only** — existing notes are never overwritten, so it is safe to re-run. It prints `{"created": [...], "skipped": [...]}`. The note name appended with " Project" is deliberately the same string the log wikilinks use, so `[[Shop Project]]` resolves to `projects/Shop Project.md`.

**Task notes** (`ensure_task_notes.py`): runs `linear_activity.py` and `github_activity.py` itself, then for every Podia ticket touched that day (assigned issue, ticket filed that day, or an authored PR whose title carries `[PODIA-NNNN]`) it ensures a `task`-schema note at `projects/tasks/PODIA-NNNN.md` (per `digital-brain/_meta/schema.json`) and folds that day's PRs into it. This is why the log links tickets as `[[PODIA-NNNN]]` and drops inline PR links (step 3) — **the PRs live on the task note, not the log bullet.** Behavior:
- **`status`** — a live PR wins over the Linear state: merged (PR merged OR Linear *completed*) → `done`; any open PR → `in_pr`; else the Linear state maps to `in_progress` / `active` / `closed`.
- **`github_url`** frontmatter holds the earliest (lowest-numbered) PR; the full set lives in the note body's `### PRs` list.
- **`project`** is set to the ticket's `[[<Name> Project]]` wikilink, `linear_id` to `PODIA-NNNN`.
- **Create-or-update**, not create-if-missing: an existing note is never clobbered, but new PRs are appended to `### PRs` (deduped by PR number) and the volatile frontmatter (`status`, empty `github_url`, empty `end_on`) is refreshed. Priority, tags, `up`, `start_on`, and the note body are left as hand-edited. **Known limitation:** an already-listed PR bullet is not rewritten when its state changes (e.g. open → merged) — only the frontmatter `status` reflects the change; new PRs are always appended fresh.

It prints `{"created": [...], "updated": [...], "skipped": [...]}` (each with `prs_added`). Mention any newly-created notes from either script in the closing summary. If you use a personal-project or other non-Linear wikilink neither script creates, make sure a note already exists for it.

### 5. Update the file

Read `/Users/andrew.mason/git/andrewmcodes/digital-brain/logs/days/YYYY-MM-DD.md` first.

- If the file doesn't exist, create it using the template at `assets/log_template.md`.
- If the `## Log` section is empty, insert the new bullets directly after the `## Log` header.
- If the `## Log` section already has entries, **append** new bullets at the end of the existing list rather than overwriting — Andrew may have hand-edited.
- **Re-running the same day:** existing entries can go stale between runs — a PR logged as *open* may have since *Merged*, an *In PR* ticket may have shipped. When that happens, make a surgical Edit to that one bullet to correct its status rather than appending a near-duplicate; "one bullet per work item" applies across runs too. Reserve appends for work that has *no* existing entry.
- **Never** touch `## Notes`, frontmatter, or any other section.
- After writing, show the user a short summary of what was added (e.g. "Added 6 entries to the Log section: 1 merged PR, 1 opened PR, 1 in-progress PR, 1 code review, 4 new tickets, 2 comments").

### 6. Edge cases

- **No activity at all**: tell the user the day looks empty and ask whether they want to leave the log untouched or add a manual note.
- **Date in the future / before Linear was set up**: tell the user, don't fabricate.
- **Multiple worktrees on the same branch**: the git script de-duplicates by SHA.
- **Commits on a branch that was later squash-merged**: the original commits still count as work — keep them, but if the squash-merge happened the same day, prefer the merged-PR phrasing over listing individual commits.
- **WIP / fixup commits**: skip them in the log unless they're the only signal of work on that ticket.
- **Linear comment was a CC-only mention** (e.g. `cc @spencer`): skip it.

## Files

- `scripts/git_activity.py` — git commits for a PT day across Podia + every personal repo under `~/git/andrewmcodes/`, deduplicated by SHA across worktrees and roots; each commit carries a `repo` field
- `scripts/github_activity.py` — PRs authored/merged + reviews given (with inline comments) + brand-new personal repos created, for a PT day, across both `podia` and `andrewmcodes` owners
- `scripts/linear_activity.py` — Andrew's Linear activity for a PT day (assigned issues with state/project, issues created, comments written) plus a `projects` metadata map, PT-trimmed and compact; replaces the raw `linear api`/`issue query` calls
- `scripts/ensure_project_notes.py` — create-if-missing vault project notes for the day's Linear projects (from the DKS project template) so `[[<Name> Project]]` wikilinks in the log resolve; consumes `linear_activity.py`'s `projects` map (via `--date`, `--linear-json`, or stdin)
- `scripts/ensure_task_notes.py` — create-or-update vault task notes (`projects/tasks/PODIA-NNNN.md`, from the DKS `task` schema) for every Podia ticket touched that day, folding the day's PRs into each note's `### PRs` list + `github_url` so `[[PODIA-NNNN]]` wikilinks resolve and PRs stay off the log bullet; consumes `linear_activity.py` + `github_activity.py` (via `--date`, `--linear-json`/`--github-json`, or a combined `{"linear":…,"github":…}` on stdin)
- `assets/log_template.md` — fallback template if the day's log file doesn't exist yet
