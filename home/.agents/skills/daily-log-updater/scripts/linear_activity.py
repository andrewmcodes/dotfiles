#!/usr/bin/env python3
"""Print Andrew's Linear activity for a given Pacific-time date, as compact JSON.

Consolidates the three Linear lookups the daily-log skill needs into one call and
trims everything to the PT day boundary, so callers never load the full
`linear issue query --all-teams` firehose (~57 KB of unused fields) or run an
ad-hoc parse afterwards.

All three lookups go through the `linear api` GraphQL endpoint (preferred over
the MCP per Andrew's CLAUDE.local.md) and request ONLY the fields the log needs:

  1. issues   - issues assigned to Andrew whose updatedAt falls in the PT day.
                Requesting server-side by assignee avoids pulling every team's
                issues. Comments (below) are the safety net for issues Andrew
                touched but isn't assigned to.
  2. created  - issues Andrew created that day (creator is null in `query --json`,
                so this must go through the API).
  3. comments - comments Andrew wrote that day.

It also collects a `projects` map keyed by project name, holding the metadata
the daily-log skill needs to create a matching project note in the vault
(id, url, state, dates, lead). This is derived from the project attached to the
issues/created above, so no extra API round-trips are needed.

Linear only accepts UTC-bounded filters, so each query is given a generous UTC
window (day-start UTC) and the results are then trimmed to the true PT day here.

Usage:
    python linear_activity.py YYYY-MM-DD

Prints JSON: {"date_pt", "issues": [...], "created": [...], "comments": [...],
"projects": {name: {...}}}.
"""
import json
import subprocess
import sys
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

PT = ZoneInfo("America/Los_Angeles")
UTC = ZoneInfo("UTC")
ANDREW_ID = "f84f3997-690e-4238-9e22-ca1c7c5f0583"

# Project sub-selection reused by the issue/created queries. Everything here is
# needed to build a vault project note (see ensure_project_notes.py).
PROJECT_FIELDS = "id name url state startDate targetDate lead { name displayName }"


def _project_meta(project: dict | None) -> dict | None:
    """Trim a raw Linear project object down to the fields a note needs."""
    if not project:
        return None
    return {
        "id": project.get("id"),
        "name": project.get("name"),
        "url": project.get("url"),
        "state": project.get("state"),
        "startDate": project.get("startDate"),
        "targetDate": project.get("targetDate"),
        "lead": (project.get("lead") or {}).get("name"),
    }


def pt_day_bounds_utc(date_str: str) -> tuple[datetime, datetime, str]:
    """Return (start_utc, end_utc, query_gte) for the PT day.

    start/end are the PT-day boundaries expressed in UTC (used to trim results);
    query_gte is a slightly-earlier UTC midnight passed to Linear so nothing on
    the PT day is filtered out server-side.
    """
    day = datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=PT)
    start_utc = day.astimezone(UTC)
    end_utc = (day + timedelta(days=1)).astimezone(UTC)
    # Linear filters are UTC; use the UTC calendar date of the PT-day start so we
    # never miss early-PT-morning activity that lands on the prior UTC date.
    query_gte = start_utc.strftime("%Y-%m-%dT00:00:00Z")
    return start_utc, end_utc, query_gte


def run_linear_api(query: str) -> dict:
    result = subprocess.run(
        ["linear", "api", query],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


def in_pt_day(ts: str, start_utc: datetime, end_utc: datetime) -> bool:
    """True if an ISO-8601 UTC timestamp falls inside the PT day."""
    if not ts:
        return False
    dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
    return start_utc <= dt < end_utc


def fetch_issues(gte: str, start_utc, end_utc, projects: dict) -> list[dict]:
    q = (
        'query { issues(filter: { assignee: { id: { eq: "%s" } }, '
        'updatedAt: { gte: "%s" } }, first: 100) { nodes { '
        "identifier title url updatedAt completedAt startedAt "
        "state { name type } project { %s } } } }" % (ANDREW_ID, gte, PROJECT_FIELDS)
    )
    nodes = run_linear_api(q).get("data", {}).get("issues", {}).get("nodes", [])
    out = []
    for n in nodes:
        # Keep if any of the meaningful timestamps land in the PT day.
        if any(
            in_pt_day(n.get(f, ""), start_utc, end_utc)
            for f in ("updatedAt", "completedAt", "startedAt")
        ):
            _collect_project(n.get("project"), projects)
            out.append(
                {
                    "identifier": n["identifier"],
                    "title": n["title"],
                    "url": n["url"],
                    "state": (n.get("state") or {}).get("name"),
                    "state_type": (n.get("state") or {}).get("type"),
                    "project": (n.get("project") or {}).get("name"),
                    "completedAt": n.get("completedAt"),
                    "updatedAt": n.get("updatedAt"),
                }
            )
    return out


def fetch_created(gte: str, start_utc, end_utc, projects: dict) -> list[dict]:
    q = (
        'query { issues(filter: { creator: { id: { eq: "%s" } }, '
        'createdAt: { gte: "%s" } }, first: 50) { nodes { '
        "identifier title url createdAt project { %s } } } }"
        % (ANDREW_ID, gte, PROJECT_FIELDS)
    )
    nodes = run_linear_api(q).get("data", {}).get("issues", {}).get("nodes", [])
    out = []
    for n in nodes:
        if not in_pt_day(n.get("createdAt", ""), start_utc, end_utc):
            continue
        _collect_project(n.get("project"), projects)
        out.append(
            {
                "identifier": n["identifier"],
                "title": n["title"],
                "url": n["url"],
                "project": (n.get("project") or {}).get("name"),
                "createdAt": n.get("createdAt"),
            }
        )
    return out


def _collect_project(project: dict | None, projects: dict) -> None:
    """Add a project's metadata to the shared map, keyed by name."""
    meta = _project_meta(project)
    if meta and meta.get("name"):
        projects.setdefault(meta["name"], meta)


def fetch_comments(gte: str, start_utc, end_utc) -> list[dict]:
    q = (
        'query { comments(filter: { user: { id: { eq: "%s" } }, '
        'createdAt: { gte: "%s" } }, first: 50) { nodes { '
        "body createdAt issue { identifier title url } } } }" % (ANDREW_ID, gte)
    )
    nodes = run_linear_api(q).get("data", {}).get("comments", {}).get("nodes", [])
    out = []
    for n in nodes:
        if not in_pt_day(n.get("createdAt", ""), start_utc, end_utc):
            continue
        issue = n.get("issue") or {}
        out.append(
            {
                "body": n.get("body", ""),
                "createdAt": n.get("createdAt"),
                "issue_identifier": issue.get("identifier"),
                "issue_title": issue.get("title"),
                "issue_url": issue.get("url"),
            }
        )
    return out


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python linear_activity.py YYYY-MM-DD", file=sys.stderr)
        sys.exit(1)
    date_str = sys.argv[1]
    start_utc, end_utc, gte = pt_day_bounds_utc(date_str)
    projects: dict = {}
    issues = fetch_issues(gte, start_utc, end_utc, projects)
    created = fetch_created(gte, start_utc, end_utc, projects)
    payload = {
        "date_pt": date_str,
        "issues": issues,
        "created": created,
        "comments": fetch_comments(gte, start_utc, end_utc),
        "projects": projects,
    }
    print(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
