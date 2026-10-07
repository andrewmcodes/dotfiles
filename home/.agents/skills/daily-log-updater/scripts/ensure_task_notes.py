#!/usr/bin/env python3
"""Ensure a vault task note exists for each Podia Linear ticket seen in a day.

The daily log links tickets as Obsidian wikilinks (e.g. `[[PODIA-10397]]`). For
those links to resolve, a note must exist at `projects/tasks/PODIA-10397.md`. This
script reads the day's Linear + GitHub activity, and for every ticket that was
touched (assigned issue, newly-filed issue, or authored PR) it creates a note from
the DKS `task` schema and folds the day's PRs into that note — so PRs live on the
task, not inline in the daily log.

Unlike ensure_project_notes.py this is **create-or-update**: an existing note is
never clobbered, but new PRs are appended to its `### PRs` list and the volatile
frontmatter fields (`status`, `github_url`, `end_on`) are refreshed. Everything
else (priority, tags, up, project, start_on, Summary body) is left as hand-edited.

Status rule: a live PR wins over the Linear state. Merged (PR merged OR Linear
completed) -> done; any open PR -> in_pr; else the Linear state maps to
in_progress / active / closed. `github_url` holds the earliest (lowest-numbered)
PR; the full list lives in the body.

Usage:
    python ensure_task_notes.py --date YYYY-MM-DD                 # runs both activity scripts
    python ensure_task_notes.py --linear-json L.json --github-json G.json
    # stdin: {"linear": {...linear_activity...}, "github": {...github_activity...}}
    python ensure_task_notes.py --date YYYY-MM-DD < /dev/null

Prints JSON: {"created": [...], "updated": [...], "skipped": [...]} where each
entry is {"ticket", "note", "path", "prs_added"}.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

VAULT = Path("/Users/andrew.mason/git/andrewmcodes/digital-brain")
TASKS_DIR = VAULT / "projects" / "tasks"
SCRIPT_DIR = Path(__file__).resolve().parent

TICKET_RE = re.compile(r"PODIA-\d+")

# Linear issue state_type -> DKS task status (schema.json task `status` options),
# used only when no PR overrides it.
STATE_TYPE_TO_STATUS = {
    "started": "in_progress",
    "completed": "done",
    "canceled": "closed",
    "backlog": "active",
    "unstarted": "active",
    "triage": "active",
}


def note_name(project_name: str) -> str:
    """Vault project-note name for a Linear project, matching ensure_project_notes.py."""
    name = (project_name or "").strip()
    if not name:
        return ""
    if name.lower().endswith("project"):
        return name
    return f"{name} Project"


def ticket_of(text: str) -> str:
    """First PODIA-NNNN identifier in a string (PR title, issue identifier), or ""."""
    m = TICKET_RE.search(text or "")
    return m.group(0) if m else ""


def strip_ticket(title: str) -> str:
    """A PR/issue title with its leading `[PODIA-NNNN]` tag removed."""
    if not title:
        return ""
    cleaned = re.sub(r"^\s*\[?PODIA-\d+\]?\s*[:\-]?\s*", "", title).strip()
    return cleaned or title.strip()


def pr_date(pr: dict, day: str = "") -> str:
    """Display date for a PR: the PT `day` when it happened today, else the UTC day.

    The activity script PT-trims and flags `opened_today`/`merged_today`, so those
    map to the target PT day; older stamps fall back to the raw UTC date portion.
    """
    merged = pr.get("state") == "merged"
    if day and merged and pr.get("merged_today"):
        return day
    if day and not merged and pr.get("opened_today"):
        return day
    stamp = pr.get("mergedAt") if merged else pr.get("createdAt")
    return (stamp or "")[:10]


def pr_bullet(pr: dict, day: str = "") -> str:
    num = pr.get("number")
    url = pr.get("url") or ""
    state = pr.get("state") or "open"
    verb = "merged" if state == "merged" else "opened"
    return f"- [#{num}]({url}) — {verb} {pr_date(pr, day)} (*{state}*)"


def compute_status(state_type: str, prs: list) -> str:
    """PR presence beats the Linear state (decision: trust the PR)."""
    states = {pr.get("state") for pr in prs}
    if "merged" in states or state_type == "completed":
        return "done"
    if "open" in states:
        return "in_pr"
    return STATE_TYPE_TO_STATUS.get(state_type or "", "active")


def collect_tickets(linear: dict, github: dict) -> dict:
    """Union of every PODIA ticket touched today, keyed by identifier.

    Sources: assigned issues (with state/project), issues filed today, and authored
    PRs (parsed from title). Each entry gathers title, linear_url, project,
    state_type, and its list of PRs.
    """
    tickets: dict[str, dict] = {}

    def slot(ident: str) -> dict:
        return tickets.setdefault(
            ident,
            {"ident": ident, "title": "", "linear_url": "", "project": "", "state_type": "", "prs": []},
        )

    for issue in (linear.get("issues") or []) + (linear.get("created") or []):
        ident = issue.get("identifier") or ticket_of(issue.get("title", ""))
        if not ident:
            continue
        entry = slot(ident)
        entry["title"] = entry["title"] or strip_ticket(issue.get("title", ""))
        entry["linear_url"] = entry["linear_url"] or (issue.get("url") or "")
        entry["project"] = entry["project"] or (issue.get("project") or "")
        # `issues` carries state_type; `created` does not. Keep the strongest we've seen.
        if issue.get("state_type"):
            entry["state_type"] = issue["state_type"]

    for pr in github.get("authored_prs") or []:
        if not str(pr.get("repo", "")).startswith("podia/"):
            continue
        ident = ticket_of(pr.get("title", ""))
        if not ident:
            continue
        entry = slot(ident)
        entry["title"] = entry["title"] or strip_ticket(pr.get("title", ""))
        entry["prs"].append(pr)

    for entry in tickets.values():
        entry["prs"].sort(key=lambda p: p.get("number") or 0)

    return tickets


def linear_url_for(entry: dict) -> str:
    """Linear URL from the issue if we have it, else a slugless URL Linear resolves."""
    if entry["linear_url"]:
        return entry["linear_url"]
    ident = entry["ident"]
    return f"https://linear.app/podia/issue/{ident}"


def build_note(entry: dict, target_date: str) -> str:
    """Render a fresh DKS task note for a ticket."""
    status = compute_status(entry["state_type"], entry["prs"])
    prs = entry["prs"]
    primary_url = prs[0].get("url") if prs else ""
    merged = next((p for p in prs if p.get("state") == "merged"), None)
    end_on = pr_date(merged, target_date) if (status == "done" and merged) else ""
    project = note_name(entry["project"])
    project_line = f'project: "[[{project}]]"' if project else "project:"
    title = entry["title"] or entry["ident"]

    lines = [
        "---",
        "type: task",
        f"status: {status}",
        "priority:",
        "tags:",
        "  - domain/work",
        project_line,
        "up:",
        f"start_on: {target_date}",
        f"end_on: {end_on}",
        f"github_url: {primary_url or ''}",
        f"linear_id: {entry['ident']}",
        "---",
        "",
        f"## {entry['ident']} {title}",
        "",
        f"[Linear]({linear_url_for(entry)})",
        "",
        "### PRs",
    ]
    lines += [pr_bullet(pr, target_date) for pr in prs] if prs else ["- _none yet_"]
    lines.append("")
    return "\n".join(lines)


def split_frontmatter(text: str):
    """Return (fm_lines, body_lines). fm_lines excludes the fence `---` markers."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, lines
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return lines[1:i], lines[i + 1:]
    return None, lines


def set_fm(fm_lines: list, key: str, value: str, only_if_empty: bool = False) -> list:
    """Set a `key:` frontmatter line. only_if_empty leaves a populated value alone."""
    prefix = f"{key}:"
    for idx, line in enumerate(fm_lines):
        if line.startswith(prefix):
            current = line[len(prefix):].strip()
            if only_if_empty and current:
                return fm_lines
            fm_lines[idx] = f"{key}: {value}".rstrip()
            return fm_lines
    fm_lines.append(f"{key}: {value}".rstrip())
    return fm_lines


def append_prs(body_lines: list, new_bullets: list) -> list:
    """Insert PR bullets into the `### PRs` list, preserving any later sections."""
    if not new_bullets:
        return body_lines
    heading_idx = next(
        (i for i, ln in enumerate(body_lines) if ln.strip() == "### PRs"), None
    )
    if heading_idx is None:
        tail = body_lines + [""] if (body_lines and body_lines[-1].strip()) else body_lines
        return tail + ["### PRs"] + new_bullets + [""]

    insert_at = heading_idx + 1
    while insert_at < len(body_lines):
        stripped = body_lines[insert_at].strip()
        if stripped == "" or stripped.startswith("-"):
            insert_at += 1
        else:
            break
    # Drop a lone "_none yet_" placeholder now that we have real PRs.
    body_lines = [ln for ln in body_lines if ln.strip() != "- _none yet_"]
    insert_at = min(insert_at, len(body_lines))
    return body_lines[:insert_at] + new_bullets + body_lines[insert_at:]


def update_note(path: Path, entry: dict, day: str) -> int:
    """Fold today's PRs + volatile status into an existing note. Returns PRs added."""
    text = path.read_text()
    status = compute_status(entry["state_type"], entry["prs"])
    prs = entry["prs"]

    new_prs = [pr for pr in prs if f"/pull/{pr.get('number')}" not in text]
    new_bullets = [pr_bullet(pr, day) for pr in new_prs]

    fm_lines, body_lines = split_frontmatter(text)
    if fm_lines is None:
        # No frontmatter to touch; only append PRs to the body.
        body_lines = append_prs(text.splitlines(), new_bullets)
        path.write_text("\n".join(body_lines).rstrip() + "\n")
        return len(new_bullets)

    set_fm(fm_lines, "status", status)
    if prs:
        set_fm(fm_lines, "github_url", prs[0].get("url") or "", only_if_empty=True)
    merged = next((p for p in prs if p.get("state") == "merged"), None)
    if status == "done" and merged:
        set_fm(fm_lines, "end_on", pr_date(merged, day), only_if_empty=True)

    body_lines = append_prs(body_lines, new_bullets)
    rebuilt = ["---", *fm_lines, "---", *body_lines]
    path.write_text("\n".join(rebuilt).rstrip() + "\n")
    return len(new_bullets)


def load_data(argv: list) -> tuple:
    """Resolve (linear, github) dicts from --date, explicit JSON files, or stdin."""
    if "--date" in argv:
        date_str = argv[argv.index("--date") + 1]

        def run(name):
            out = subprocess.run(
                [sys.executable, str(SCRIPT_DIR / name), date_str],
                capture_output=True, text=True, check=True,
            )
            return json.loads(out.stdout)

        return run("linear_activity.py"), run("github_activity.py")

    if "--linear-json" in argv or "--github-json" in argv:
        linear = json.loads(Path(argv[argv.index("--linear-json") + 1]).read_text()) if "--linear-json" in argv else {}
        github = json.loads(Path(argv[argv.index("--github-json") + 1]).read_text()) if "--github-json" in argv else {}
        return linear, github

    data = json.loads(sys.stdin.read())
    return data.get("linear", {}), data.get("github", {})


def target_date(argv: list, linear: dict) -> str:
    if "--date" in argv:
        return argv[argv.index("--date") + 1]
    return linear.get("date_pt", "")


def main() -> None:
    argv = sys.argv[1:]
    linear, github = load_data(argv)
    day = target_date(argv, linear)
    tickets = collect_tickets(linear, github)

    created, updated, skipped = [], [], []
    TASKS_DIR.mkdir(parents=True, exist_ok=True)

    for ident, entry in sorted(tickets.items()):
        path = TASKS_DIR / f"{ident}.md"
        record = {"ticket": ident, "note": ident, "path": str(path), "prs_added": 0}
        if path.exists():
            added = update_note(path, entry, day)
            record["prs_added"] = added
            (updated if added else skipped).append(record)
        else:
            path.write_text(build_note(entry, day))
            record["prs_added"] = len(entry["prs"])
            created.append(record)

    print(json.dumps({"created": created, "updated": updated, "skipped": skipped}, indent=2))


if __name__ == "__main__":
    main()
