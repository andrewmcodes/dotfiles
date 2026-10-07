#!/usr/bin/env python3
"""Ensure a vault project note exists for each Podia Linear project seen in a day.

The daily log links projects as Obsidian wikilinks (e.g. `[[Shop Project]]`). For
those links to resolve, a note must exist at `projects/<Name> Project.md`. This
script reads the `projects` map emitted by linear_activity.py, and for any project
that has no matching note yet, creates one from the DKS project template
(util/obj_tmpl/project.tmpl.md) filled with the Linear metadata.

Existing notes are never overwritten — this is create-if-missing only, so it is
safe to re-run for the same day.

Usage:
    python linear_activity.py YYYY-MM-DD | python ensure_project_notes.py
    python ensure_project_notes.py --linear-json path/to/linear.json
    python ensure_project_notes.py --date YYYY-MM-DD   # runs linear_activity itself

Prints JSON: {"created": [...], "skipped": [...]} where each entry is
{"project", "note", "path"}.
"""
import json
import subprocess
import sys
from pathlib import Path

VAULT = Path("/Users/andrew.mason/git/andrewmcodes/digital-brain")
PROJECTS_DIR = VAULT / "projects"
SCRIPT_DIR = Path(__file__).resolve().parent

# Linear project state -> DKS project status (schema.json `status` options).
STATE_TO_STATUS = {
    "backlog": "backlog",
    "planned": "planned",
    "started": "in_progress",
    "paused": "in_progress",
    "completed": "completed",
    "canceled": "canceled",
}


def note_name(project_name: str) -> str:
    """Vault note name for a Linear project, matching Andrew's existing notes.

    Existing notes carry a " Project" suffix (e.g. "Hub Spaces Project.md"), which
    is also how the daily log links them (`[[Shop Project]]`). Names that already
    end in "Project" are left as-is.
    """
    name = project_name.strip()
    if name.lower().endswith("project"):
        return name
    return f"{name} Project"


def linear_id_from_url(url: str) -> str:
    """The trailing slug of a Linear project URL, e.g. shop-8230faaa9efb."""
    if not url:
        return ""
    return url.rstrip("/").rsplit("/project/", 1)[-1]


def project_url(url: str) -> str:
    """Normalize to the /overview URL Andrew's existing notes use."""
    if not url:
        return ""
    base = url.rstrip("/")
    return base if base.endswith("/overview") else f"{base}/overview"


def build_note(project: dict) -> str:
    """Render the DKS project template for a Linear project."""
    title = note_name(project["name"])
    status = STATE_TO_STATUS.get(project.get("state") or "", "backlog")
    url = project.get("url") or ""
    lines = [
        "---",
        "type: project",
        "project_type: initiative",
        f"status: {status}",
        "priority:",
        "tags:",
        "  - domain/work",
        "up:",
        '  - "[[@work]]"',
        f"start_on: {project.get('startDate') or ''}",
        f"end_on: {project.get('targetDate') or ''}",
        f"project_url: {project_url(url)}",
        f"linear_id: {linear_id_from_url(url)}",
        "---",
        "",
        f"## {title}",
        "",
        "![[Project Views.base]]",
        "",
    ]
    return "\n".join(lines)


def load_projects(argv: list[str]) -> dict:
    """Resolve the `projects` map from stdin, a JSON file, or a date."""
    if "--linear-json" in argv:
        path = Path(argv[argv.index("--linear-json") + 1])
        data = json.loads(path.read_text())
    elif "--date" in argv:
        date_str = argv[argv.index("--date") + 1]
        result = subprocess.run(
            [sys.executable, str(SCRIPT_DIR / "linear_activity.py"), date_str],
            capture_output=True,
            text=True,
            check=True,
        )
        data = json.loads(result.stdout)
    else:
        data = json.loads(sys.stdin.read())
    return data.get("projects", {})


def main() -> None:
    projects = load_projects(sys.argv[1:])
    created, skipped = [], []
    for name, meta in sorted(projects.items()):
        title = note_name(name)
        path = PROJECTS_DIR / f"{title}.md"
        entry = {"project": name, "note": title, "path": str(path)}
        if path.exists():
            skipped.append(entry)
            continue
        path.write_text(build_note(meta))
        created.append(entry)
    print(json.dumps({"created": created, "skipped": skipped}, indent=2))


if __name__ == "__main__":
    main()
