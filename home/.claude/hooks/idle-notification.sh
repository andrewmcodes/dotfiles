#!/bin/bash
# Notification when Claude becomes idle (waiting for user input)

/opt/homebrew/bin/terminal-notifier \
  -title "Claude Code" \
  -subtitle "Task Complete" \
  -message "Claude has finished working and is waiting for input" \
  -sound Glass
