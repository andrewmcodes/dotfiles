---
name: weekly-project-update
description: Draft Andrew's weekly Linear project updates from his real activity — Linear issues (moved/completed/created/commented), git commits, and GitHub PRs (opened/merged/reviewed), all grouped by Linear project. Produces one paste-ready markdown update per project, each with a suggested health status and a short narrative. Use whenever Andrew asks for his weekly project update(s), a "what did I ship this week" per-project writeup, a Linear update draft, an end-of-week status for stakeholders, or a weekly recap grouped by project — even when he doesn't say "skill". For a personal daybook entry grouped by day, use daily-log-updater instead.
---

# Weekly Project Update

Turns a week of Andrew's activity into **one paste-ready update per Linear project**, for pasting into each project's update box in Linear (health + body). It reuses the tested daily fetchers from `daily-log-updater` and adds two things they don't do: a **week window** and **grouping by Linear project** (git commits and PRs are mapped to their project via their `PODIA-NNNN` ticket ref).

The synthesis is yours to do — the script gathers and groups the raw activity; you write the narrative like a reporter/editor. Do not just dump the JSON.

## 1. Resolve the week

- No date given → default to the **current calendar week** (Monday 00:00 PT through today).
- "last week" / "the week that just ended" → pass `--last-week` (previous complete Mon–Sun).
- Explicit range → `--since YYYY-MM-DD [--until YYYY-MM-DD]`.

Confirm the resolved week in your first message so Andrew can correct it before you write anything.

## 2. Gather + group (one command)

```bash
python3 /Users/andrew.mason/.agents/skills/weekly-project-update/scripts/weekly_activity.py [--last-week | --since YYYY-MM-DD --until YYYY-MM-DD]
```

Runs the git and Linear daily fetchers across each PT day of the week (in parallel) and the GitHub fetcher once over the whole range (`github_week.py` — one search per category, so it stays under the search rate limit and past the 100/day cap). Emits JSON:

```
{
  "week":    { "since", "until", "days": [...] },
  "projects": { "<Linear project name>": { issues, created, comments, prs, commits, reviews, pr_comments } },
  "personal": { "<owner/repo>": { commits, prs, ... } },   # personal-repo work, no Linear project
  "reviews_other": [ ... ],                                  # reviews Andrew gave on PRs with no resolvable ticket
  "unmatched":     { issues, commits, comments, ... },       # Podia activity with no project / no ticket ref
  "created_repos": [ ... ],
  "project_meta":  { "<name>": { url, state, startDate, targetDate, lead } },
  "warnings": [ ... ]
}
```

Notes on the data:
- Each `projects[name]` bucket is **everything** that happened on that project this week across all three sources. That bucket is the raw material for one project update.
- Commits carrying `mechanical: true` are already dropped from grouping; ignore them entirely if you see any.
- A PR that was opened Monday and merged Wednesday carries both `opened_today` and `merged_today` = true and `state: "merged"`.
- `unmatched` holds Podia work whose ticket has no Linear project, or commits/PRs with no `PODIA-NNNN` ref. Don't invent a project for it — either fold it into the closest project's update if you (or Andrew) know where it belongs, or leave it out.
- If `warnings` is non-empty, tell Andrew which source/day failed (e.g. a GitHub rate limit) so he knows the update may be thin there.

## 3. Synthesize — one update per project

For **each** project in `projects`, write a self-contained Linear project update that matches the house format below. Work like a reporter then an editor (see `@references/synthesis.md`): read the whole bucket, group by theme not by source, weigh significance over volume, and write **outcome bullets** — what a creator/teammate can now do or what got fixed, in plain past tense — **not** commit subjects, PR numbers, or ticket refs.

The audience is **project stakeholders**, not Andrew. This update gets pasted into the project's update box in Linear.

### Output format (per project)

````markdown
## <Project Name>

* <Outcome bullet — a shipped capability or change, plain English, no ticket ref>
* <Grouped feature family with sub-bullets:>
  * <sub-capability>
  * <sub-capability>
* <In-progress work, phrased with its trajectory — e.g. "Reworking X; compatibility 89% → 94% after the open PRs, continuing next week">

## Bugs

* <Bug fix in plain English>
````

Just the body — **no header link, no status/health line, no TL;DR, no "Progress since" footer.** Linear supplies the project title, the health, the byline, and the progress diff itself when Andrew posts; the paste is only the `## <Project>` / `## Bugs` content. Rules:
- **Bullets carry no `[[PODIA-NNNN]]`, no PR numbers, no code-review play-by-play.** Describe the outcome. Wrap true code symbols (`Product::Pricing`, tool names like `podia_create_email_campaign`) in backticks.
- **Group tool/feature families** (sales tools, affiliate tools, event tools, …) under one parent bullet with sub-bullets, as in the example.
- **`## Bugs`** holds bug fixes (Linear issues whose title/type reads as a bug, or fix-shaped PRs). Everything else — features, tools, hardening, in-progress — goes under `## <Project>`. Drop the `## Bugs` header if there are none.
- **Reviews of teammates' PRs** can become a single outcome bullet if they represent real project contribution (e.g. "Reviewed the PFM schema/renderer series"); otherwise omit.
- Put a `---` divider between projects so Andrew can copy one block at a time.

### Health

Don't put a health line in the paste (Linear sets it). Still tell Andrew your suggested health in the surrounding chat so he can pick it in Linear: 🟢 On track (meaningful ships, no blockers surfaced) · 🟡 At risk (progress but a blocker/pivot/slip appeared) · 🔴 Off track (little movement or an unresolved blocker). No activity at all → say so plainly, don't draft a fake update.

## 4. Handle the leftovers

- **`personal`** work (personal repos, no Linear project) is not a project update. Mention it to Andrew in a one-line aside only if he asked for a full weekly recap; otherwise leave it out.
- **`reviews_other`** (reviews on PRs with no resolvable ticket) — usually noise for a project update; skip unless a review is clearly significant.
- **`unmatched`** — see the note above.

## 5. Deliver

Print the per-project markdown blocks to the chat for Andrew to paste. Do **not** write to Linear or to the vault — this skill only drafts. Close with a one-line summary: how many projects, and any warnings.

## Files

- `scripts/weekly_activity.py` — driver: resolves the week, runs the git + Linear daily fetchers per day and `github_week.py` once, merges/dedups, resolves every `PODIA-NNNN` ref to its Linear project, and emits activity grouped by project
- `scripts/github_week.py` — range-native GitHub fetcher (one search per category over the whole week); a sibling of `daily-log-updater/github_activity.py` that avoids the per-day rate-limit and 100-result cap
- `references/synthesis.md` — reporter/editor principles for turning a project bucket into a narrative update
