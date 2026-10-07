# Synthesis — from a project bucket to a Linear project update

Each `projects[name]` bucket from `weekly_activity.py` is a week of activity on one project across Linear, git, and GitHub. Turn it into a stakeholder-facing Linear project update: just the body — `## <Project>` outcome bullets, then `## Bugs`. No header link, no status/health line, no TL;DR, no progress footer (Linear supplies all of those on post). Two passes: reporter, then editor.

## Reporter pass — see the week

Read the whole bucket before writing. Then:

1. **Group by theme, not by source.** A single initiative usually spans a Linear issue, a PR, and several commits. Collapse them into one outcome.
2. **Cluster feature families.** Sales tools, affiliate tools, event tools, email authoring — a run of related PRs becomes one parent bullet with sub-bullets, not six flat lines.
3. **Show trajectory for in-flight work.** If something is mid-stream, say where it stands and where it's going — e.g. "Reworking the PFM pipeline into a schema-driven projection; compatibility 89% → 94% after the open PRs, continuing next week." In-progress work belongs in the main list, not a separate section.
4. **Weigh significance over volume.** One shipped capability outweighs twenty routine commits. `mechanical` and WIP commits are not news.
5. **Be honest about gaps.** The data can't see meetings, DMs, or design work. If a project looks quiet in the data but wasn't, say the update is activity-derived and may be partial.

## Editor pass — write the update

The reader is a project stakeholder. They care about what the product/team can now do, what got fixed, and what's in flight.

- **Outcome bullets, not mechanics.** Each `## <Project>` bullet says what changed in creator/product terms. Past tense. **No ticket refs, no PR numbers, no commit subjects, no review play-by-play.**
  - BAD: "Merged #21106 [PODIA-10836] Route price change through Product::Pricing"
  - GOOD: "Worked on product pricing so all pricing options can be set via the MCP, not just one-time payments, and fixed a bug where previous pricing was wiped when a new option was added"
- **Split out bugs.** Bug fixes go under `## Bugs`; features, tools, hardening, and in-progress work stay under `## <Project>`.
- **Backtick real code symbols only** — class names (`Product::Pricing`) and tool names (`podia_create_email_campaign`), not ordinary nouns.
- **In-progress work** goes in the main list, phrased with its trajectory ("Reworking X; compatibility 89% → 94% after the open PRs, continuing next week").
- **Respect length.** A busy project can run long (the format tolerates a big flat list), but every bullet must earn its place. A quiet project is a short list or a single line.

## Anti-patterns

- Ticket refs or PR numbers in bullets — this update is not the daily log; keep them out.
- Source-grouped output ("Git:… GitHub:… Linear:…") — group by initiative.
- Echoing commit subjects verbatim.
- Padding: empty sections, or a `## Bugs` header with no bugs.
- Inventing a through-line for a grab-bag week — a plain list is more honest.

## Health

Health comes from the activity, not a formula. Meaningful ships and no surfaced blockers → 🟢 On track. Progress shadowed by a blocker, slip, or pivot → 🟡 At risk. Stalled or an unresolved blocker → 🔴 Off track. Present it as a suggestion for Andrew to confirm.
