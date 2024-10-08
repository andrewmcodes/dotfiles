#!/usr/bin/env zsh

export SHELL="$(which zsh)"

# 1Password
export OP_BIOMETRIC_UNLOCK_ENABLED=true

# Homebrew
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_COLOR=1
export HOMEBREW_BAT=1

# Ruby
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$HOMEBREW_PREFIX/opt/openssl@1.1"
export DISABLE_SPRING=true

export RUBY_DEBUG_HISTORY_FILE="$DATA_DIR/rdbg_history"
# Sometimes when the histfile is kept in iCloud, it is empty when Zsh starts up.
[[ -z $RUBY_DEBUG_HISTORY_FILE(#qL+0N) && -r "$RUBY_DEBUG_HISTORY_FILE 2" ]] && mv "$RUBY_DEBUG_HISTORY_FILE 2" "$RUBY_DEBUG_HISTORY_FILE"
# Use a local gemrc if it exists.
[[ -f $HOME/.gemrc.local ]] && export GEMRC=$HOME/.gemrc.local

# Shell
export VISUAL="code-insiders --wait"
export EDITOR="nvim"
export MANPAGER="less -X"

# FZF
export FZF_DEFAULT_OPTS="--history='$DATA_DIR/.fzf-history' \
            --ansi \
            --height 50% \
            --layout=reverse \
            --preview-window=right:60% \
            --preview 'bat --color=always --style=header,grid --line-range :500 {}' \
            --color=fg:#fbf1c7,bg:#282828,hl:#83a598 \
            --inline-info \
            --prompt='FZF > '"
# export FZF_DEFAULT_OPTS="--history=$HOME/.fzf-history --height=40% --layout=reverse --ansi --preview-window=right:60% --color=fg:#fbf1c7,bg:#282828,hl:#83a598 --inline-info --prompt='FZF > '"
