#!/usr/bin/env zsh

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

: ${XDG_CACHE_HOME:=~/.cache}
: ${XDG_CONFIG_HOME:=~/.config}
: ${XDG_DATA_HOME:=~/.local/share}
: ${XDG_STATE_HOME:=~/.local/state}
: ${ICLOUD_DRIVE_HOME:=~/Library/Mobile\ Documents/com~apple~CloudDocs}
: ${DATA_DIR:=~/data}

export XDG_CONFIG_HOME \
  XDG_CACHE_HOME \
  XDG_DATA_HOME \
  XDG_STATE_HOME \
  ICLOUD_DRIVE_HOME \
  DATA_DIR

ZDOTDIR=$XDG_CONFIG_HOME/zsh
ZIM_HOME=$XDG_CONFIG_HOME/zim

# These are used in /etc/zshrc
case $VENDOR in
  ( apple )
    export SHELL_SESSIONS_DISABLE=1
  ;;
  ( ubuntu )
    export skip_global_compinit=1
  ;;
esac
