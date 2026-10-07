#!/bin/bash
# Logs skill and MCP tool usage to ~/.claude/tool-usage.log

set -euo pipefail

input=$(cat)
log_file="$HOME/.claude/tool-usage.log"

tool_name=$(echo "$input" | jq -r '.tool_name // "unknown"')
hook_event=$(echo "$input" | jq -r '.hook_event_name // "unknown"')
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# For Skill tool, log the skill name from tool_input
if [ "$tool_name" = "Skill" ]; then
  skill_name=$(echo "$input" | jq -r '.tool_input.skill // "unknown"')
  echo "$timestamp [$hook_event] Skill: $skill_name" >> "$log_file"
else
  # MCP tool — log the tool name directly
  echo "$timestamp [$hook_event] MCP: $tool_name" >> "$log_file"
fi

exit 0
