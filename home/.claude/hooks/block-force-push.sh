#!/usr/bin/env bash
# PreToolUse (Bash) — hard-deny force pushes that target a protected branch (main/master).
# Force pushing feature branches (e.g. after a rebase) is allowed.
# Andrew force-pushes protected branches himself via `! git push --force` when he really means it.
set -uo pipefail

PROTECTED_RE='^(main|master)$'

payload=$(cat)
cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[[ -z $cmd ]] && exit 0
cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)
[[ -z $cwd ]] && cwd=$PWD

deny() {
  jq -n --arg r "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

REASON='Force pushing to main/master is blocked by a global hook (~/.claude/hooks/block-force-push.sh) — this includes --force, -f, --force-with-lease, --force-if-includes, +refspec, --all, and --mirror. Do not try to work around it. Tell the user what you wanted to force push and why, and let them run it themselves with `! git push --force ...`.'

protected() {
  local ref=${1#+}
  ref=${ref#refs/heads/}
  [[ $ref =~ $PROTECTED_RE ]]
}

current_branch() {
  git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null
}

check_segment() {
  local -a words
  read -ra words <<<"$1"

  local i=0 n=${#words[@]}
  dir=$cwd
  while ((i < n)) && [[ ${words[i]} != git ]]; do
    [[ ${words[i]} == cd ]] && ((i + 1 < n)) && cwd=${words[i + 1]/#\~/$HOME} && dir=$cwd
    ((i++))
  done
  ((i < n)) || return 0
  ((i++))

  while ((i < n)) && [[ ${words[i]} != push ]]; do
    [[ ${words[i]} == -C ]] && ((i + 1 < n)) && dir=${words[i + 1]/#\~/$HOME} && ((i++))
    ((i++))
  done
  ((i < n)) || return 0
  ((i++))

  local force=0 all=0 w
  local -a positional=()
  while ((i < n)); do
    w=${words[i]}
    case $w in
      --force | --force=* | --force-with-lease | --force-with-lease=* | --force-if-includes) force=1 ;;
      --all | --mirror | --branches) all=1 ;;
      -o | --push-option | --repo | --receive-pack | --exec) ((i++)) ;;
      --*) ;;
      -*) [[ $w =~ ^-[A-Za-z]*f[A-Za-z]*$ ]] && force=1 ;;
      *)
        positional+=("$w")
        [[ ${#positional[@]} -gt 1 && $w == +* ]] && force=1
        ;;
    esac
    ((i++))
  done

  ((force)) || return 0
  ((all)) && deny "$REASON"

  local -a refspecs=("${positional[@]:1}")
  if ((${#refspecs[@]} == 0)); then
    protected "$(current_branch "$dir")" && deny "$REASON"
    return 0
  fi

  local spec src dst
  for spec in "${refspecs[@]}"; do
    spec=${spec#+}
    if [[ $spec == *:* ]]; then
      src=${spec%%:*}
      dst=${spec#*:}
    else
      src=$spec
      dst=$spec
    fi
    [[ $dst == HEAD || $dst == @ ]] && dst=$(current_branch "$dir")
    [[ -z $src && -z $dst ]] && continue
    protected "$dst" && deny "$REASON"
  done
  return 0
}

while IFS= read -r seg; do
  check_segment "$seg"
done < <(printf '%s\n' "$cmd" | tr ';&|' '\n')

exit 0
