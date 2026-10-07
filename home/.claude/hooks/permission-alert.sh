#!/bin/bash
# Notification when Claude requests permission

/opt/homebrew/bin/terminal-notifier \
  -title "Claude Code" \
  -subtitle "Permission Required" \
  -message "Claude is requesting permission to perform an action" \
  -sound Ping
