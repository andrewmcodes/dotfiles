#!/usr/bin/env python3
"""Fetch Andrew's GitHub PR activity for a Pacific-time week in one pass.

A range-native sibling of daily-log-updater/github_activity.py: it issues one
search per category across the whole week (not seven daily searches), which keeps
it under GitHub's search rate limit and past the 100-result-per-day cap. Each
reviewed/commented PR's detail is fetched once, so a PR touched on several days
costs a single round-trip instead of one per day.

Buckets match the daily script so the weekly driver can merge them the same way:
authored_prs, reviews, pr_comments, created_repos.

Usage:
    python github_week.py --since YYYY-MM-DD --until YYYY-MM-DD [login] [owners]
"""
import argparse
import json
import subprocess
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

PT = ZoneInfo("America/Los_Angeles")
UTC = ZoneInfo("UTC")
DEFAULT_LOGIN = "andrewmcodes"
DEFAULT_OWNERS = ["podia", "andrewmcodes"]
LIMIT = "300"


def week_bounds_utc(since: str, until: str) -> tuple[datetime, datetime]:
    start_pt = datetime.strptime(since, "%Y-%m-%d").replace(tzinfo=PT)
    end_pt = datetime.strptime(until, "%Y-%m-%d").replace(tzinfo=PT) + timedelta(days=1)
    return start_pt.astimezone(UTC), end_pt.astimezone(UTC)


def search_range(since: str, until: str) -> str:
    lo = datetime.strptime(since, "%Y-%m-%d").date() - timedelta(days=1)
    hi = datetime.strptime(until, "%Y-%m-%d").date() + timedelta(days=1)
    return f"{lo}..{hi}"


def in_window(iso_z: str, start_utc: datetime, end_utc: datetime) -> bool:
    if not iso_z or iso_z.startswith("0001-"):
        return False
    dt = datetime.fromisoformat(iso_z.replace("Z", "+00:00"))
    return start_utc <= dt < end_utc


def gh_json(args: list[str]) -> object:
    out = subprocess.check_output(["gh"] + args, text=True)
    return json.loads(out) if out.strip() else None


def authored_prs(rng, owners, start_utc, end_utc) -> list[dict]:
    fields = "number,title,url,createdAt,closedAt,state,repository"
    by_key: dict[tuple[str, int], dict] = {}
    for owner in owners:
        opened = gh_json(["search", "prs", "--author", "@me", "--owner", owner,
                          "--created", rng, "--json", fields, "--limit", LIMIT]) or []
        merged = gh_json(["search", "prs", "--author", "@me", "--owner", owner,
                          "--json", fields, "--limit", LIMIT, f"merged:{rng}"]) or []
        for pr in opened + merged:
            key = (pr["repository"]["nameWithOwner"], pr["number"])
            opened_today = in_window(pr.get("createdAt", ""), start_utc, end_utc)
            merged_today = (in_window(pr.get("closedAt", "") or "", start_utc, end_utc)
                            and pr.get("state") == "merged")
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


def reviewed_prs(rng, login, owners, start_utc, end_utc) -> list[dict]:
    by_key: dict[tuple[str, int], dict] = {}
    for owner in owners:
        prs = gh_json(["search", "prs", "--reviewed-by", "@me", "--owner", owner,
                       "--updated", rng, "--json",
                       "number,title,url,author,repository", "--limit", LIMIT]) or []
        for pr in prs:
            repo = pr["repository"]["nameWithOwner"]
            number = pr["number"]
            key = (repo, number)
            if key in by_key:
                continue
            reviews = gh_json(["api", f"repos/{repo}/pulls/{number}/reviews", "--paginate"]) or []
            my_reviews = [
                {"state": r.get("state"), "submittedAt": r.get("submitted_at"), "url": r.get("html_url")}
                for r in reviews
                if r.get("user", {}).get("login") == login
                and in_window(r.get("submitted_at", ""), start_utc, end_utc)
            ]
            comments = gh_json(["api", f"repos/{repo}/pulls/{number}/comments", "--paginate"]) or []
            my_comments = [
                {"path": c.get("path"), "body": c.get("body", "")[:500],
                 "createdAt": c.get("created_at"), "url": c.get("html_url")}
                for c in comments
                if c.get("user", {}).get("login") == login
                and in_window(c.get("created_at", ""), start_utc, end_utc)
            ]
            if not my_reviews and not my_comments:
                continue
            by_key[key] = {
                "number": number, "repo": repo, "title": pr["title"], "url": pr["url"],
                "author": (pr.get("author") or {}).get("login"),
                "review_states": [r["state"] for r in my_reviews],
                "inline_comments": my_comments,
            }
    return list(by_key.values())


def pr_comments(rng, login, owners, start_utc, end_utc) -> list[dict]:
    by_key: dict[tuple[str, int], dict] = {}
    for owner in owners:
        prs = gh_json(["search", "prs", "--commenter", "@me", "--owner", owner,
                       "--updated", rng, "--json",
                       "number,title,url,author,repository", "--limit", LIMIT]) or []
        for pr in prs:
            repo = pr["repository"]["nameWithOwner"]
            number = pr["number"]
            key = (repo, number)
            if key in by_key:
                continue
            comments = gh_json(["api", f"repos/{repo}/issues/{number}/comments", "--paginate"]) or []
            mine = [
                {"body": c.get("body", "")[:500], "createdAt": c.get("created_at"), "url": c.get("html_url")}
                for c in comments
                if c.get("user", {}).get("login") == login
                and in_window(c.get("created_at", ""), start_utc, end_utc)
            ]
            if mine:
                by_key[key] = {
                    "number": number, "repo": repo, "title": pr["title"], "url": pr["url"],
                    "author": (pr.get("author") or {}).get("login"), "comments": mine,
                }
    return list(by_key.values())


def created_repos(rng, login, start_utc, end_utc) -> list[dict]:
    repos = gh_json(["search", "repos", "--owner", login, "--created", rng,
                     "--json", "name,fullName,description,createdAt,url", "--limit", LIMIT]) or []
    out = []
    for r in repos:
        if not in_window(r.get("createdAt", ""), start_utc, end_utc):
            continue
        out.append({"name": r.get("name"), "full_name": r.get("fullName"),
                    "description": r.get("description"), "createdAt": r.get("createdAt"),
                    "url": r.get("url")})
    return sorted(out, key=lambda r: r.get("createdAt") or "")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--since", required=True)
    ap.add_argument("--until", required=True)
    ap.add_argument("login", nargs="?", default=DEFAULT_LOGIN)
    ap.add_argument("owners", nargs="?", default=",".join(DEFAULT_OWNERS))
    args = ap.parse_args()

    owners = [o.strip() for o in args.owners.split(",") if o.strip()]
    start_utc, end_utc = week_bounds_utc(args.since, args.until)
    rng = search_range(args.since, args.until)

    result = {
        "since": args.since, "until": args.until, "login": args.login, "owners": owners,
        "authored_prs": authored_prs(rng, owners, start_utc, end_utc),
        "reviews": reviewed_prs(rng, args.login, owners, start_utc, end_utc),
        "pr_comments": pr_comments(rng, args.login, owners, start_utc, end_utc),
        "created_repos": created_repos(rng, args.login, start_utc, end_utc),
    }
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
