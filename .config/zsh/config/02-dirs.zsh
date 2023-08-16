#!/bin/zsh

## Named directories

#? Create shortcuts for your favorite directories.
#! Set these early, because it affects how dirs are displayed and printed.
#? `hash -d <name>=<path>` makes ~<name> a shortcut for <path>.
#! You can use this ~name anywhere you would specify a dir, not just with `cd`!

# hash -d zsh=$ZDOTDIR
hash -d git=$gitdir
hash -d brain=$gitdir/andrewmcodes/digital-brain
hash -d podia=$gitdir/work/podia
hash -d config=$HOME/.config
