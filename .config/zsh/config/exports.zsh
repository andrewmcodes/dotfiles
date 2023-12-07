#!/usr/bin/env zsh

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
[[ -f $HOME/.gemrc.local ]] && export GEMRC=$HOME/.gemrc.local #? Use a local gemrc if it exists.

# Shell
export EDITOR="code --wait"
export SHELL="$(which zsh)"
export MANPAGER="less -X"
