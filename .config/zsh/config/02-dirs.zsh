#!/bin/zsh

## Named directories
#! Set these early, because it affects how dirs are displayed and printed
#? `hash -d <name>=<path>` makes ~<name> a shortcut for <path>.

hash -d zsh=$ZDOTDIR
hash -d git=$gitdir
hash -d brain=$gitdir/andrewmcodes/digital-brain
hash -d podia=$gitdir/work/podia
hash -d config=$HOME/.config
