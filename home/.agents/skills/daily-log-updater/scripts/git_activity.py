#!/usr/bin/env python3
"""Print git commits authored by the current user on a given Pacific-time date.

Walks one or more "roots" and emits a JSON list of commits whose committed-time
falls inside the local PT day boundary. A root can be either:

  - a git repo directly (e.g. /Users/andrew.mason/git/work/podia), or
  - a parent directory whose immediate children are git repos
    (e.g. /Users/andrew.mason/git/andrewmcodes containing many personal repos).

Worktrees of each discovered repo are also walked. Commits are deduplicated by
SHA across the entire scan so a commit visible in multiple worktrees or roots
is emitted once.

Usage:
    python git_activity.py YYYY-MM-DD [root1 root2 ...]

Defaults to scanning both the Podia repo and Andrew's personal repos under
~/git/andrewmcodes.
"""
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

DEFAULT_ROOTS = [
    "/Users/andrew.mason/git/work/podia",
    "/Users/andrew.mason/git/andrewmcodes",
]
PT = ZoneInfo("America/Los_Angeles")

# Subjects that are produced by automated tooling (Mac backup script, vault
# activity tracker, etc.) and should not be treated as real work. Each commit
# is still emitted so callers can see them if desired, but it carries
# `mechanical: true` so the synthesizer can ignore the noise.
MECHANICAL_SUBJECT_PATTERNS: list[re.Pattern] = [
    re.compile(r"^chore: mac (manual )?backup on \d{4}-\d{2}-\d{2}"),
    re.compile(r"^chore: update activity$"),
]


def is_mechanical_subject(subject: str) -> bool:
    return any(p.match(subject) for p in MECHANICAL_SUBJECT_PATTERNS)


def pt_day_bounds(date_str: str) -> tuple[str, str]:
    start = datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=PT)
    end = start + timedelta(days=1)
    return start.isoformat(), end.isoformat()


def is_git_repo(path: str) -> bool:
    return os.path.isdir(os.path.join(path, ".git")) or os.path.isfile(
        os.path.join(path, ".git")
    )


def discover_repos(root: str) -> list[str]:
    if not os.path.isdir(root):
        return []
    if is_git_repo(root):
        return [root]
    repos: list[str] = []
    for entry in sorted(os.listdir(root)):
        if entry.startswith("."):
            continue
        path = os.path.join(root, entry)
        if is_git_repo(path):
            repos.append(path)
    return repos


def get_user(repo: str) -> str:
    return subprocess.check_output(
        ["git", "-C", repo, "config", "user.name"], text=True
    ).strip()


def get_worktrees(repo: str) -> list[str]:
    try:
        out = subprocess.check_output(
            ["git", "-C", repo, "worktree", "list", "--porcelain"],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError:
        return [repo]
    paths = [
        line[len("worktree "):]
        for line in out.splitlines()
        if line.startswith("worktree ")
    ]
    return paths or [repo]


def get_commits(path: str, since: str, until: str, author: str, repo_label: str) -> list[dict]:
    # Use committer date (%cI) rather than author date — when commits are rebased,
    # author date stays in the past while committer date reflects when the work
    # actually landed in this branch state. `git log --since/--until` already filters
    # on committer date, so this keeps the filter and the emitted timestamp consistent.
    fmt = "%H%x1f%h%x1f%cI%x1f%s%x1f%D"
    try:
        out = subprocess.check_output(
            [
                "git", "-C", path, "log",
                "--all", "--reflog",
                f"--since={since}", f"--until={until}",
                f"--author={author}",
                f"--pretty=format:{fmt}",
            ],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError:
        return []

    commits = []
    for line in out.splitlines():
        if not line.strip():
            continue
        parts = line.split("\x1f")
        if len(parts) < 5:
            continue
        sha, short, iso_date, subject, refs = parts
        commit_dt = datetime.fromisoformat(iso_date).astimezone(PT)
        commits.append({
            "sha": sha,
            "short": short,
            "datetime_pt": commit_dt.isoformat(),
            "subject": subject,
            "branches": refs.strip(),
            "repo": repo_label,
            "mechanical": is_mechanical_subject(subject),
        })
    return commits


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: git_activity.py YYYY-MM-DD [root1 root2 ...]", file=sys.stderr)
        return 2

    date_str = sys.argv[1]
    roots = sys.argv[2:] or DEFAULT_ROOTS

    since, until = pt_day_bounds(date_str)

    repos: list[str] = []
    for root in roots:
        repos.extend(discover_repos(root))

    if not repos:
        print(json.dumps([], indent=2))
        return 0

    # All known repos share the same human author; read once.
    author = get_user(repos[0])

    seen: set[str] = set()
    all_commits: list[dict] = []
    for repo in repos:
        repo_label = os.path.basename(repo.rstrip("/"))
        for wt in get_worktrees(repo):
            for c in get_commits(wt, since, until, author, repo_label):
                if c["sha"] in seen:
                    continue
                seen.add(c["sha"])
                all_commits.append(c)

    all_commits.sort(key=lambda c: c["datetime_pt"])
    print(json.dumps(all_commits, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
