#!/usr/bin/env zsh

## Plugin manager

local znap=$gitdir/zsh-snap/znap.zsh

if ! [[ -r $znap ]]; then #? Check if Znap is installed and install it if not
  mkdir -p $gitdir
  git -C $gitdir clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git
fi

. $znap #? Load Znap
