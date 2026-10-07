#!/bin/bash

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir')
model_id=$(echo "$input" | jq -r '.model.id')
version=$(echo "$input" | jq -r '.version')
output_style=$(echo "$input" | jq -r '.output_style.name // "default"')
context_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
agent_name=$(echo "$input" | jq -r '.agent.name // empty')
effort_level=$(echo "$input" | jq -r '.effort.level // empty')
rl_5h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_7d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

ICON_FOLDER="󰉋"
ICON_HOME="󰋜"
ICON_WORKTREE="󰙅"
ICON_SERVER="󰒋"
ICON_BRANCH="󰘬"
ICON_PR="󰓂"
ICON_MODEL="󰚩"
ICON_LIMIT="󰔟"
ICON_TOKENS="󰆼"
ICON_PLUG="󰚥"
ICON_AGENT="󰀄"
ICON_STYLE="󰏫"

RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[38;5;246m'
FAINT=$'\033[38;5;240m'
CYAN=$'\033[38;5;81m'
ORANGE=$'\033[38;5;215m'
PURPLE=$'\033[38;5;141m'
BLUE=$'\033[38;5;75m'
SKY=$'\033[38;5;117m'
LAVENDER=$'\033[38;5;183m'
PINK=$'\033[38;5;211m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
SEP=" ${FAINT}│${RESET} "

state_color() {
  local value="$1" warn="$2" crit="$3"
  if [ "$value" -ge "$crit" ]; then
    printf "%s" "$RED"
  elif [ "$value" -ge "$warn" ]; then
    printf "%s" "$YELLOW"
  else
    printf "%s" "$GREEN"
  fi
}

join() {
  local out="" part
  for part in "$@"; do
    [ -n "$part" ] || continue
    out="${out:+$out }$part"
  done
  printf "%s" "$out"
}

cd "$cwd" 2>/dev/null || exit 0
if [ "$cwd" = "$project_dir" ]; then
  dir_label=$(basename "$cwd")
else
  dir_label="${cwd#"$project_dir"/}"
fi
dir_display="${BOLD}${CYAN}${ICON_FOLDER} ${dir_label}${RESET}"

worktree_display=""
slot_display=""
git_display=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  git_dir=$(cd "$(git rev-parse --git-dir)" && pwd -P)
  git_common_dir=$(cd "$(git rev-parse --git-common-dir)" && pwd -P)
  toplevel=$(git rev-parse --show-toplevel)

  slot="0"
  ssl_port="3001"
  if [ "$git_dir" != "$git_common_dir" ]; then
    worktree_display=$'\033[1;30;48;5;214m'" ${ICON_WORKTREE} WORKTREE ${RESET}"
    mise_local="$toplevel/.mise.local.toml"
    if [ -f "$mise_local" ]; then
      slot=$(sed -n 's/^WT_SLOT *= *"\{0,1\}\([0-9]*\)"\{0,1\}.*/\1/p' "$mise_local")
      ssl_port=$(sed -n 's/^DEV_SSL_PORT *= *"\{0,1\}\([0-9]*\)"\{0,1\}.*/\1/p' "$mise_local")
    fi
  else
    worktree_display="${BOLD}${GREEN}${ICON_HOME}${RESET}"
  fi

  if [ -f "$toplevel/bin/rails" ] && [ -n "$slot" ] && [ -n "$ssl_port" ]; then
    if nc -z -G 1 127.0.0.1 "$ssl_port" 2>/dev/null; then
      server_dot="${GREEN}●${RESET}"
    else
      server_dot="${FAINT}○${RESET}"
    fi
    slot_display="${ORANGE}${ICON_SERVER} ${slot}${RESET} ${DIM}:${ssl_port}${RESET} ${server_dot}"
  fi

  branch=$(git -c core.useBuiltinFSMonitor=false -c advice.waitingForLock=false branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    git_opts=(-c core.useBuiltinFSMonitor=false -c advice.waitingForLock=false)
    staged=$(git "${git_opts[@]}" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    modified=$(git "${git_opts[@]}" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git "${git_opts[@]}" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    sync_status=""
    if git "${git_opts[@]}" rev-parse --abbrev-ref @{u} > /dev/null 2>&1; then
      ahead=$(git "${git_opts[@]}" rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
      behind=$(git "${git_opts[@]}" rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
      if [ "$ahead" != "0" ] && [ "$behind" != "0" ]; then
        sync_status="${YELLOW}⇅${ahead}/${behind}${RESET}"
      elif [ "$ahead" != "0" ]; then
        sync_status="${YELLOW}⇡${ahead}${RESET}"
      elif [ "$behind" != "0" ]; then
        sync_status="${RED}⇣${behind}${RESET}"
      else
        sync_status="${GREEN}✓${RESET}"
      fi
    fi

    changes=""
    [ "$staged" != "0" ] && changes=$(join "$changes" "${GREEN}+${staged}${RESET}")
    [ "$modified" != "0" ] && changes=$(join "$changes" "${YELLOW}~${modified}${RESET}")
    [ "$untracked" != "0" ] && changes=$(join "$changes" "${RED}?${untracked}${RESET}")

    if [ -n "$changes" ]; then
      branch_color="$YELLOW"
    else
      branch_color="$GREEN"
    fi
    git_display=$(join "${branch_color}${ICON_BRANCH}${RESET} ${BOLD}${branch}${RESET}" "$sync_status" "$changes")

    pr_cache_dir="$HOME/.claude/cache/statusline-pr"
    mkdir -p "$pr_cache_dir"
    pr_cache="$pr_cache_dir/$(printf '%s|%s' "$toplevel" "$branch" | md5 -q).json"
    pr_lock="$pr_cache.lock"
    pr_age=999999
    [ -f "$pr_cache" ] && pr_age=$(( $(date +%s) - $(stat -f %m "$pr_cache") ))
    if [ -d "$pr_lock" ] && [ $(( $(date +%s) - $(stat -f %m "$pr_lock") )) -ge 120 ]; then
      rmdir "$pr_lock" 2>/dev/null
    fi
    if [ "$pr_age" -ge 60 ] && mkdir "$pr_lock" 2>/dev/null; then
      (
        gh pr view "$branch" --json number,state,isDraft,reviewDecision,statusCheckRollup \
          -q '{number, state, isDraft, reviewDecision,
               checks: ([.statusCheckRollup[] | (if (.conclusion // "") != "" then .conclusion else (.state // .status) end)]
                        | {pass: map(select(. == "SUCCESS" or . == "NEUTRAL" or . == "SKIPPED")) | length,
                           fail: map(select(. == "FAILURE" or . == "ERROR" or . == "CANCELLED" or . == "TIMED_OUT" or . == "ACTION_REQUIRED" or . == "STARTUP_FAILURE")) | length,
                           total: length})}' \
          > "$pr_cache.tmp" 2>/dev/null || echo '{}' > "$pr_cache.tmp"
        mv "$pr_cache.tmp" "$pr_cache"
        rmdir "$pr_lock"
      ) > /dev/null 2>&1 &
      disown 2>/dev/null
    fi

    if [ -s "$pr_cache" ]; then
      pr_fields=$(jq -r 'if .number then [.state, .isDraft, (.reviewDecision // ""), .checks.pass, .checks.fail, .checks.total] | @tsv else empty end' "$pr_cache" 2>/dev/null)
      if [ -n "$pr_fields" ]; then
        IFS=$'\t' read -r pr_state pr_draft pr_review pr_pass pr_fail pr_total <<< "$pr_fields"
        pr_pending=$(( pr_total - pr_pass - pr_fail ))
        pr_parts=""

        case "$pr_state" in
          MERGED) pr_parts="${PURPLE}merged${RESET}" ;;
          CLOSED) pr_parts="${DIM}closed${RESET}" ;;
          *)
            [ "$pr_draft" = "true" ] && pr_parts="${DIM}draft${RESET}"
            if [ "$pr_total" -gt 0 ]; then
              [ "$pr_fail" -gt 0 ] && pr_parts=$(join "$pr_parts" "${RED}✗${pr_fail}${RESET}")
              [ "$pr_pending" -gt 0 ] && pr_parts=$(join "$pr_parts" "${YELLOW}●${pr_pending}${RESET}")
              pr_parts=$(join "$pr_parts" "${GREEN}✓${pr_pass}${RESET}")
            fi
            case "$pr_review" in
              APPROVED) pr_parts=$(join "$pr_parts" "${GREEN}approved${RESET}") ;;
              CHANGES_REQUESTED) pr_parts=$(join "$pr_parts" "${RED}changes${RESET}") ;;
              REVIEW_REQUIRED) pr_parts=$(join "$pr_parts" "${DIM}review${RESET}") ;;
            esac
            ;;
        esac
        git_display="${git_display}${SEP}${BLUE}${ICON_PR}${RESET} ${pr_parts}"
      fi
    fi
  fi
fi

model_short=$(echo "$model_id" | sed -e 's/^claude-//' -e 's/-20[0-9]*$//' -e 's/-\([0-9]\)-\([0-9]\)/ \1.\2/')
model_display="${PURPLE}${ICON_MODEL} ${model_short}${RESET}"
case "$effort_level" in
  low) effort_color="$DIM" ;;
  medium) effort_color="$SKY" ;;
  high) effort_color="$ORANGE" ;;
  xhigh|max) effort_color="${BOLD}${PINK}" ;;
  *) effort_color="$DIM" ;;
esac
[ -n "$effort_level" ] && model_display="${model_display} ${effort_color}${effort_level}${RESET}"

context_display=""
if [ -n "$context_used" ]; then
  used_int=$(printf "%.0f" "$context_used")
  filled=$(( (used_int + 5) / 10 ))
  [ "$filled" -gt 10 ] && filled=10
  bar_on=""
  bar_off=""
  for ((i = 0; i < 10; i++)); do
    if [ "$i" -lt "$filled" ]; then bar_on="${bar_on}━"; else bar_off="${bar_off}━"; fi
  done
  color=$(state_color "$used_int" 50 80)
  context_display="${DIM}ctx${RESET} ${color}${bar_on}${RESET}${FAINT}${bar_off}${RESET} ${color}${used_int}%${RESET}"
fi

format_limit() {
  local label="$1" pct="$2" reset_ts="$3" pct_int color reset_str=""
  [ -n "$pct" ] || return 0
  pct_int=$(printf "%.0f" "$pct")
  color=$(state_color "$pct_int" 70 90)
  if [ "$pct_int" -ge 70 ] && [ -n "$reset_ts" ]; then
    reset_str=" ${DIM}↻$(date -r "${reset_ts%.*}" "+%-I:%M%p" | tr 'APM' 'apm')${RESET}"
  fi
  printf "%s" "${DIM}${label}${RESET} ${color}${pct_int}%${RESET}${reset_str}"
}

limits_display=""
limit_5h=$(format_limit "5h" "$rl_5h_pct" "$rl_5h_reset")
limit_7d=$(format_limit "7d" "$rl_7d_pct" "$rl_7d_reset")
if [ -n "$limit_5h" ] || [ -n "$limit_7d" ]; then
  limits_display="${SKY}${ICON_LIMIT}${RESET} $(join "$limit_5h" "$limit_7d")"
fi

token_display=""
total_tokens=$(( total_input + total_output ))
if [ "$total_tokens" -ge 1000000 ]; then
  token_display="${PINK}${ICON_TOKENS} $(awk "BEGIN { printf \"%.1fM\", $total_tokens / 1000000 }")${RESET}"
elif [ "$total_tokens" -ge 1000 ]; then
  token_display="${PINK}${ICON_TOKENS} $(awk "BEGIN { printf \"%.1fK\", $total_tokens / 1000 }")${RESET}"
elif [ "$total_tokens" -gt 0 ]; then
  token_display="${PINK}${ICON_TOKENS} ${total_tokens}${RESET}"
fi

mcp_display=""
if [ -f "$HOME/.claude/mcp_settings.json" ]; then
  mcp_count=$(jq -r '.mcpServers | length' "$HOME/.claude/mcp_settings.json" 2>/dev/null || echo "0")
  [ "$mcp_count" != "0" ] && mcp_display="${PINK}${ICON_PLUG} ${mcp_count}${RESET}"
fi

agent_display=""
[ -n "$agent_name" ] && agent_display="${ORANGE}${ICON_AGENT} ${agent_name}${RESET}"

style_display=""
[ "$output_style" != "default" ] && style_display="${LAVENDER}${ICON_STYLE} ${output_style}${RESET}"

version_display="${DIM}v${version}${RESET}"

where=$(join "$dir_display" "$worktree_display" "$slot_display")
usage=$(join "$model_display" "$context_display" "$limits_display")
session=$(join "$token_display" "$mcp_display" "$style_display" "$agent_display" "$version_display")

printf "%s%s%s%s%s" "$where" "$SEP" "$usage" "$SEP" "$session"
if [ -n "$git_display" ]; then
  printf "\n%s" "$git_display"
fi
