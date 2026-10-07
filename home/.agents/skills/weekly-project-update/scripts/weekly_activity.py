#!/usr/bin/env python3
"""Aggregate a week of Andrew's activity, grouped by Linear project.

Reuses the three tested daily fetchers from the daily-log-updater skill (git,
GitHub, Linear) by running each across every Pacific-time day in the week, then
merges the results and buckets everything under the Linear project it belongs to.
Podia git commits and PRs are mapped to a project by resolving their PODIA-NNNN
ticket ref against Linear; personal-repo work is grouped by repo instead.

Week resolution (all in America/Los_Angeles):
  - no args            -> current calendar week, Monday 00:00 through today
  - --last-week        -> the previous complete Monday..Sunday
  - --since D [--until D]  -> explicit range (inclusive of both days)
  - D1 D2 (positional) -> explicit range

Output: JSON on stdout — {week, projects, personal, reviews_other, unmatched}.
Each project bucket holds {issues, created, comments, prs, commits, reviews}.
"""
import argparse
import json
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

PT = ZoneInfo("America/Los_Angeles")
DAILY_SCRIPTS = "/Users/andrew.mason/.agents/skills/daily-log-updater/scripts"
PERSONAL_OWNER = "andrewmcodes"
TICKET_RE = re.compile(r"podia[-\s]?(\d+)", re.IGNORECASE)


def run_cmd(cmd: list[str], label: str) -> object:
    out = subprocess.run(cmd, capture_output=True, text=True)
    if out.returncode != 0:
        return {"__error__": out.stderr.strip().splitlines()[-1] if out.stderr.strip()
                else f"{label} exited {out.returncode}"}
    return json.loads(out.stdout) if out.stdout.strip() else None


def run_daily(script: str, day: str) -> object:
    return run_cmd(["python3", os.path.join(DAILY_SCRIPTS, script), day], f"{script} {day}")


def days_in_range(since: date, until: date) -> list[str]:
    out, cur = [], since
    while cur <= until:
        out.append(cur.isoformat())
        cur += timedelta(days=1)
    return out


def resolve_week(args) -> tuple[date, date]:
    today = datetime.now(PT).date()
    if args.since:
        since = date.fromisoformat(args.since)
        until = date.fromisoformat(args.until) if args.until else today
        return since, until
    if args.range:
        return date.fromisoformat(args.range[0]), date.fromisoformat(args.range[1])
    monday = today - timedelta(days=today.weekday())
    if args.last_week:
        last_monday = monday - timedelta(days=7)
        return last_monday, last_monday + timedelta(days=6)
    return monday, today


def gather(since: str, until: str, days: list[str]) -> tuple[dict, list[str]]:
    github_cmd = ["python3", os.path.join(os.path.dirname(__file__), "github_week.py"),
                  "--since", since, "--until", until]
    with ThreadPoolExecutor(max_workers=8) as pool:
        git_futs = {pool.submit(run_daily, "git_activity.py", d): d for d in days}
        lin_futs = {pool.submit(run_daily, "linear_activity.py", d): d for d in days}
        gh_fut = pool.submit(run_cmd, github_cmd, "github_week.py")
        git_res = {d: f.result() for f, d in git_futs.items()}
        lin_res = {d: f.result() for f, d in lin_futs.items()}
        gh = gh_fut.result()

    warnings: list[str] = []
    commits, issues, created, comments, projects = {}, {}, {}, [], {}

    for day, data in sorted(git_res.items()):
        if isinstance(data, dict) and "__error__" in data:
            warnings.append(f"git_activity.py {day}: {data['__error__']}")
        elif data:
            for c in data:
                commits.setdefault(c["sha"], c)

    for day, data in sorted(lin_res.items()):
        if isinstance(data, dict) and "__error__" in data:
            warnings.append(f"linear_activity.py {day}: {data['__error__']}")
        elif data:
            for i in data.get("issues", []):
                issues[i["identifier"]] = i
            for i in data.get("created", []):
                created[i["identifier"]] = i
            comments.extend(data.get("comments", []))
            for name, meta in (data.get("projects") or {}).items():
                projects.setdefault(name, meta)

    if isinstance(gh, dict) and "__error__" in gh:
        warnings.append(f"github_week.py: {gh['__error__']}")
        gh = {}
    gh = gh or {}

    merged = {
        "commits": list(commits.values()),
        "prs": gh.get("authored_prs", []),
        "reviews": gh.get("reviews", []),
        "pr_comments": gh.get("pr_comments", []),
        "created_repos": gh.get("created_repos", []),
        "issues": list(issues.values()),
        "created": list(created.values()),
        "comments": comments,
        "projects": projects,
    }
    return merged, warnings


def tickets_in(text: str) -> list[str]:
    return [f"PODIA-{m}" for m in TICKET_RE.findall(text or "")]


def resolve_ticket_projects(idents: set[str]) -> dict[str, str]:
    numbers = sorted({int(i.split("-")[1]) for i in idents})
    if not numbers:
        return {}
    q = (
        'query { issues(filter: { number: { in: [%s] }, '
        'team: { key: { eq: "PODIA" } } }, first: 250) { nodes { '
        "identifier project { name } } } }" % ",".join(str(n) for n in numbers)
    )
    out = subprocess.run(["linear", "api", q], capture_output=True, text=True)
    if out.returncode != 0:
        return {}
    nodes = json.loads(out.stdout).get("data", {}).get("issues", {}).get("nodes", [])
    return {
        n["identifier"]: (n.get("project") or {}).get("name")
        for n in nodes
        if n.get("project")
    }


def new_bucket() -> dict:
    return {"issues": [], "created": [], "comments": [], "prs": [], "commits": [],
            "reviews": [], "pr_comments": []}


def group_by_project(merged: dict) -> dict:
    idents: set[str] = set()
    for i in merged["issues"] + merged["created"]:
        idents.add(i["identifier"])
    for cm in merged["comments"]:
        if cm.get("issue_identifier"):
            idents.add(cm["issue_identifier"])
    for c in merged["commits"]:
        idents.update(tickets_in(c.get("subject", "")))
        idents.update(tickets_in(c.get("branches", "")))
    for pr in merged["prs"] + merged["reviews"] + merged["pr_comments"]:
        idents.update(tickets_in(pr.get("title", "")))

    ticket_project = resolve_ticket_projects(idents)
    for i in merged["issues"] + merged["created"]:
        if i.get("project"):
            ticket_project.setdefault(i["identifier"], i["project"])

    projects: dict[str, dict] = {}
    personal: dict[str, dict] = {}
    reviews_other: list[dict] = []
    unmatched = new_bucket()

    def proj(name: str) -> dict:
        return projects.setdefault(name, new_bucket())

    def first_project(idents_list: list[str]) -> str | None:
        for ident in idents_list:
            if ticket_project.get(ident):
                return ticket_project[ident]
        return None

    for i in merged["issues"]:
        (proj(i["project"]) if i.get("project") else unmatched)["issues"].append(i)
    for i in merged["created"]:
        (proj(i["project"]) if i.get("project") else unmatched)["created"].append(i)
    for cm in merged["comments"]:
        name = ticket_project.get(cm.get("issue_identifier"))
        (proj(name) if name else unmatched)["comments"].append(cm)

    for pc in merged["pr_comments"]:
        if pc["repo"].split("/")[0] == PERSONAL_OWNER:
            personal.setdefault(pc["repo"], new_bucket())["pr_comments"].append(pc)
            continue
        name = first_project(tickets_in(pc.get("title", "")))
        (proj(name) if name else unmatched)["pr_comments"].append(pc)

    for c in merged["commits"]:
        if c.get("mechanical"):
            continue
        if c.get("repo") != "podia":
            personal.setdefault(c["repo"], new_bucket())["commits"].append(c)
            continue
        name = first_project(tickets_in(c.get("subject", "")) + tickets_in(c.get("branches", "")))
        (proj(name) if name else unmatched)["commits"].append(c)

    for pr in merged["prs"]:
        if pr["repo"].split("/")[0] == PERSONAL_OWNER:
            personal.setdefault(pr["repo"], new_bucket())["prs"].append(pr)
            continue
        name = first_project(tickets_in(pr.get("title", "")))
        (proj(name) if name else unmatched)["prs"].append(pr)

    for r in merged["reviews"]:
        name = first_project(tickets_in(r.get("title", "")))
        if name:
            proj(name)["reviews"].append(r)
        else:
            reviews_other.append(r)

    return {
        "projects": projects,
        "personal": personal,
        "reviews_other": reviews_other,
        "unmatched": unmatched,
        "created_repos": merged["created_repos"],
        "project_meta": merged["projects"],
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("range", nargs="*", help="optional SINCE UNTIL (YYYY-MM-DD)")
    ap.add_argument("--since")
    ap.add_argument("--until")
    ap.add_argument("--last-week", action="store_true")
    args = ap.parse_args()
    if args.range and len(args.range) != 2:
        print("Positional range needs exactly two dates: SINCE UNTIL", file=sys.stderr)
        return 2

    since, until = resolve_week(args)
    days = days_in_range(since, until)
    merged, warnings = gather(since.isoformat(), until.isoformat(), days)
    grouped = group_by_project(merged)
    grouped["week"] = {"since": since.isoformat(), "until": until.isoformat(), "days": days}
    grouped["warnings"] = warnings
    print(json.dumps(grouped, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
