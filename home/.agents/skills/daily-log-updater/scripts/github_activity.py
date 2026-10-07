#!/usr/bin/env python3
"""Fetch Andrew's GitHub PR + repo activity for a given Pacific-time date.

Buckets:
- authored_prs:  PRs Andrew opened or had merged that PT day across all owners
- reviews:       PRs Andrew submitted a review on that PT day (with inline comments)
- pr_comments:   top-level (issue-style) PR comments Andrew left that PT day
- created_repos: brand-new repos Andrew created on his personal account that PT day

We always search a wider UTC range (PT day -1 .. PT day +1) and then post-filter
to the actual PT-day window so a PR opened at 23:00 PT (06:00 UTC next day)
still ends up on the right log.

Usage:
    python github_activity.py YYYY-MM-DD [github_login] [owner1,owner2,...]

Defaults: github_login=andrewmcodes, owners=podia,andrewmcodes
"""
import json
import subprocess
import sys
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

PT = ZoneInfo("America/Los_Angeles")
UTC = ZoneInfo("UTC")
DEFAULT_LOGIN = "andrewmcodes"
DEFAULT_OWNERS = ["podia", "andrewmcodes"]


def pt_day_bounds_utc(date_str: str) -> tuple[datetime, datetime]:
    start_pt = datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=PT)
    end_pt = start_pt + timedelta(days=1)
    return start_pt.astimezone(UTC), end_pt.astimezone(UTC)


def search_range(date_str: str) -> str:
    d = datetime.strptime(date_str, "%Y-%m-%d").date()
    return f"{d - timedelta(days=1)}..{d + timedelta(days=1)}"


def in_window(iso_z: str, start_utc: datetime, end_utc: datetime) -> bool:
    if not iso_z or iso_z.startswith("0001-"):
        return False
    dt = datetime.fromisoformat(iso_z.replace("Z", "+00:00"))
    return start_utc <= dt < end_utc


def gh_json(args: list[str]) -> object:
    out = subprocess.check_output(["gh"] + args, text=True)
    return json.loads(out) if out.strip() else None


def authored_prs(date_str: str, owners: list[str], start_utc, end_utc) -> list[dict]:
    rng = search_range(date_str)
    fields = "number,title,url,createdAt,closedAt,state,repository"

    by_key: dict[tuple[str, int], dict] = {}
    for owner in owners:
        opened = gh_json([
            "search", "prs",
            "--author", "@me",
            "--owner", owner,
            "--created", rng,
            "--json", fields,
            "--limit", "100",
        ]) or []

        # `--merged` isn't a date flag; use the inline `merged:RANGE` qualifier.
        merged = gh_json([
            "search", "prs",
            "--author", "@me",
            "--owner", owner,
            "--json", fields,
            "--limit", "100",
            f"merged:{rng}",
        ]) or []

        for pr in opened + merged:
            key = (pr["repository"]["nameWithOwner"], pr["number"])
            opened_today = in_window(pr.get("createdAt", ""), start_utc, end_utc)
            merged_today = (
                in_window(pr.get("closedAt", "") or "", start_utc, end_utc)
                and pr.get("state") == "merged"
            )
            if not (opened_today or merged_today):
                continue
            by_key[key] = {
                "number": pr["number"],
                "repo": pr["repository"]["nameWithOwner"],
                "title": pr["title"],
                "url": pr["url"],
                "state": pr.get("state"),
                "createdAt": pr.get("createdAt"),
                "mergedAt": pr.get("closedAt") if pr.get("state") == "merged" else None,
                "opened_today": opened_today,
                "merged_today": merged_today,
            }
    return sorted(by_key.values(), key=lambda p: p.get("createdAt") or "")


def reviewed_prs(date_str: str, login: str, owners: list[str], start_utc, end_utc) -> list[dict]:
    rng = search_range(date_str)
    by_key: dict[tuple[str, int], dict] = {}
    for owner in owners:
        prs = gh_json([
            "search", "prs",
            "--reviewed-by", "@me",
            "--owner", owner,
            "--updated", rng,
            "--json", "number,title,url,author,repository",
            "--limit", "100",
        ]) or []

        for pr in prs:
            repo = pr["repository"]["nameWithOwner"]
            number = pr["number"]
            key = (repo, number)
            if key in by_key:
                continue
            reviews = gh_json([
                "api", f"repos/{repo}/pulls/{number}/reviews", "--paginate",
            ]) or []
            my_reviews = [
                {
                    "state": r.get("state"),
                    "submittedAt": r.get("submitted_at"),
                    "url": r.get("html_url"),
                }
                for r in reviews
                if r.get("user", {}).get("login") == login
                and in_window(r.get("submitted_at", ""), start_utc, end_utc)
            ]
            review_comments = gh_json([
                "api", f"repos/{repo}/pulls/{number}/comments", "--paginate",
            ]) or []
            my_review_comments = [
                {
                    "path": c.get("path"),
                    "body": c.get("body", "")[:500],
                    "createdAt": c.get("created_at"),
                    "url": c.get("html_url"),
                }
                for c in review_comments
                if c.get("user", {}).get("login") == login
                and in_window(c.get("created_at", ""), start_utc, end_utc)
            ]
            if not my_reviews and not my_review_comments:
                continue
            by_key[key] = {
                "number": number,
                "repo": repo,
                "title": pr["title"],
                "url": pr["url"],
                "author": (pr.get("author") or {}).get("login"),
                "review_states": [r["state"] for r in my_reviews],
                "inline_comments": my_review_comments,
            }
    return list(by_key.values())


def pr_comments(date_str: str, login: str, owners: list[str], start_utc, end_utc) -> list[dict]:
    rng = search_range(date_str)
    by_key: dict[tuple[str, int], dict] = {}
    for owner in owners:
        prs = gh_json([
            "search", "prs",
            "--commenter", "@me",
            "--owner", owner,
            "--updated", rng,
            "--json", "number,title,url,author,repository",
            "--limit", "100",
        ]) or []

        for pr in prs:
            repo = pr["repository"]["nameWithOwner"]
            number = pr["number"]
            key = (repo, number)
            if key in by_key:
                continue
            comments = gh_json([
                "api", f"repos/{repo}/issues/{number}/comments", "--paginate",
            ]) or []
            mine = [
                {
                    "body": c.get("body", "")[:500],
                    "createdAt": c.get("created_at"),
                    "url": c.get("html_url"),
                }
                for c in comments
                if c.get("user", {}).get("login") == login
                and in_window(c.get("created_at", ""), start_utc, end_utc)
            ]
            if mine:
                by_key[key] = {
                    "number": number,
                    "repo": repo,
                    "title": pr["title"],
                    "url": pr["url"],
                    "author": (pr.get("author") or {}).get("login"),
                    "comments": mine,
                }
    return list(by_key.values())


def created_repos(date_str: str, login: str, start_utc, end_utc) -> list[dict]:
    # 3-day UTC window matches the other searches; post-filter to the PT day.
    rng = search_range(date_str)
    repos = gh_json([
        "search", "repos",
        "--owner", login,
        "--created", rng,
        "--json", "name,fullName,description,createdAt,url",
        "--limit", "100",
    ]) or []

    out: list[dict] = []
    for r in repos:
        if not in_window(r.get("createdAt", ""), start_utc, end_utc):
            continue
        out.append({
            "name": r.get("name"),
            "full_name": r.get("fullName"),
            "description": r.get("description"),
            "createdAt": r.get("createdAt"),
            "url": r.get("url"),
        })
    return sorted(out, key=lambda r: r.get("createdAt") or "")


def main() -> int:
    if len(sys.argv) < 2:
        print(
            "Usage: github_activity.py YYYY-MM-DD [login] [owner1,owner2,...]",
            file=sys.stderr,
        )
        return 2

    date_str = sys.argv[1]
    login = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_LOGIN
    owners = (
        [o.strip() for o in sys.argv[3].split(",") if o.strip()]
        if len(sys.argv) > 3
        else DEFAULT_OWNERS
    )

    start_utc, end_utc = pt_day_bounds_utc(date_str)

    result = {
        "date_pt": date_str,
        "login": login,
        "owners": owners,
        "authored_prs": authored_prs(date_str, owners, start_utc, end_utc),
        "reviews": reviewed_prs(date_str, login, owners, start_utc, end_utc),
        "pr_comments": pr_comments(date_str, login, owners, start_utc, end_utc),
        "created_repos": created_repos(date_str, login, start_utc, end_utc),
    }
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
