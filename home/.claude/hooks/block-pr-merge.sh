# #!/usr/bin/env bash
# # PreToolUse (Bash) — hard-deny any command that merges a GitHub pull request. Approving and marking ready are allowed (2026-09-11).
# # Humans merge; Andrew runs the exact `gh` command himself if he really means it.
# set -uo pipefail

# payload=$(cat)
# cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
# [[ -z $cmd ]] && exit 0

# deny() {
#   jq -n --arg r "$1" '{
#     hookSpecificOutput: {
#       hookEventName: "PreToolUse",
#       permissionDecision: "deny",
#       permissionDecisionReason: $r
#     }
#   }'
#   exit 0
# }

# REASON='Merging pull requests is blocked by a global hook (~/.claude/hooks/block-pr-merge.sh). Humans merge. Do not work around it with gh api, GraphQL, eval, a script file, or a push to a protected branch. Print the exact gh command you wanted to run and let the user run it themselves.'

# cmd=$(printf '%s' "$cmd" | awk '
# function first_word_is_wrapper(line,    s, w) {
#   s = line
#   sub(/^[ \t]+/, "", s)
#   while (match(s, /^[A-Za-z_][A-Za-z0-9_]*=[^ \t]*[ \t]+/)) {
#     s = substr(s, RSTART + RLENGTH)
#     sub(/^[ \t]+/, "", s)
#   }
#   match(s, /^[^ \t]+/)
#   w = substr(s, RSTART, RLENGTH)
#   sub(/^.*\//, "", w)
#   return (w == "eval" || w == "bash" || w == "sh" || w == "zsh" || w == "xargs" || w == "env" || w == "command" || w == "exec" || w == "time" || w == "nohup" || w == "sudo")
# }
# BEGIN { in_heredoc = 0 }
# {
#   line = $0
#   if (in_heredoc) {
#     term = line
#     if (allow_tab) sub(/^\t+/, "", term)
#     if (term == delim) {
#       in_heredoc = 0
#       next
#     }
#     if (wrapper_led) print line
#     next
#   }

#   pos = index(line, "<<")
#   if (pos > 0) {
#     rest = substr(line, pos + 2)
#     allow_tab = 0
#     if (substr(rest, 1, 1) == "-") {
#       allow_tab = 1
#       rest = substr(rest, 2)
#     }
#     q = substr(rest, 1, 1)
#     if (q == "\047" || q == "\"") {
#       rest = substr(rest, 2)
#     }
#     if (match(rest, /^[A-Za-z_][A-Za-z0-9_]*/)) {
#       delim = substr(rest, RSTART, RLENGTH)
#       wrapper_led = first_word_is_wrapper(line)
#       in_heredoc = 1
#       print line
#       next
#     }
#   }
#   print line
# }
# ')

# peel() {
#   local s="$1" firstword fw flag val
#   while true; do
#     s="${s#"${s%%[![:space:]]*}"}"
#     while [[ $s =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*)$ ]]; do
#       s="${BASH_REMATCH[1]}"
#     done
#     firstword="${s%%[[:space:]]*}"
#     fw="${firstword##*/}"
#     case "$fw" in
#       eval | bash | sh | zsh | xargs | env | command | exec | time | nohup | sudo) ;;
#       *) break ;;
#     esac
#     s="${s#"$firstword"}"
#     s="${s#"${s%%[![:space:]]*}"}"
#     while [[ $s == -* ]]; do
#       flag="${s%%[[:space:]]*}"
#       s="${s#"$flag"}"
#       s="${s#"${s%%[![:space:]]*}"}"
#       if [[ $fw == sudo && ( $flag == "-u" || $flag == "-g" || $flag == "-p" ) ]]; then
#         val="${s%%[[:space:]]*}"
#         s="${s#"$val"}"
#         s="${s#"${s%%[![:space:]]*}"}"
#       fi
#     done
#   done
#   printf '%s' "$s"
# }

# while IFS= read -r rawseg; do
#   norm=$(printf '%s' "$rawseg" | tr '(){}' '    ' | tr '`' ' ' | tr '"' ' ' | tr "'" ' ')
#   stripped=$(printf '%s' "$rawseg" | sed "s/\"[^\"]*\"//g; s/'[^']*'//g")

#   lead="${rawseg#"${rawseg%%[![:space:]]*}"}"
#   while [[ $lead =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*)$ ]]; do
#     lead="${BASH_REMATCH[1]}"
#   done
#   firstword="${lead%%[[:space:]]*}"
#   firstword="${firstword##*/}"

#   is_wrapper=0
#   case "$firstword" in
#     eval | bash | sh | zsh | xargs | env | command | exec | time | nohup | sudo) is_wrapper=1 ;;
#   esac

#   if [[ $is_wrapper -eq 1 ]]; then
#     base_text="$norm"
#   else
#     base_text="$stripped"
#   fi

#   peeled=$(peel "$base_text")

#   [[ $peeled =~ ^[[:space:]]*([^[:space:]]*/)?gh[[:space:]] ]] || continue

#   if [[ $peeled =~ (^|[[:space:]])pr[[:space:]]+merge([[:space:]]|$) ]]; then
#     deny "$REASON"
#   fi

#   if [[ $peeled =~ (^|[[:space:]])api[[:space:]] ]]; then
#     if [[ $peeled =~ /pulls/[^/[:space:]]+/merge([[:space:]]|$) ]]; then
#       deny "$REASON"
#     fi
#   fi

#   if [[ $stripped =~ graphql ]] \
#     && [[ $norm =~ (mergePullRequest|enablePullRequestAutoMerge) ]]; then
#     deny "$REASON"
#   fi
# done < <(printf '%s\n' "$cmd" | tr ';&|' '\n')

# exit 0
