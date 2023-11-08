#!/usr/bin/env zsh

## Environment variables

export OP_BIOMETRIC_UNLOCK_ENABLED=true
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_COLOR=1
export HOMEBREW_BAT=1
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$HOMEBREW_PREFIX/opt/openssl@1.1"
export DISABLE_SPRING=true
[[ -f $HOME/.gemrc.local ]] && export GEMRC=$HOME/.gemrc.local #? Use a local gemrc if it exists.
export EDITOR="code --wait"
export SHELL="$HOMEBREW_PREFIX/bin/zsh"
export MANPAGER="less -X" #* Don’t clear the screen after quitting a manual page
