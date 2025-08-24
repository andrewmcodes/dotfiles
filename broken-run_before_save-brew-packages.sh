#!/bin/bash

if [ "$(uname)" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
  echo "Updating Brewfile..."
  brew bundle dump --force --file="$HOME/.config/brew/Brewfile"
fi
