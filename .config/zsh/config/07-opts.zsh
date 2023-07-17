#!/usr/bin/env zsh

## Shell options
#! Set these after sourcing plugins, because those might set options, too.

#? Don't let > overwrite files. To overwrite, use >| instead.
setopt NO_CLOBBER

#? Allow comments to be pasted into the command line.
setopt INTERACTIVE_COMMENTS

#? Don't treat non-executable files in your $path as commands.
setopt HASH_EXECUTABLES_ONLY

#? Enable additional glob operators. (Globbing = pattern matching)
#¬ https://zsh.sourceforge.io/Doc/Release/Expansion.html#Filename-Generation
setopt EXTENDED_GLOB

#? Enable ** and *** as shortcuts for **/* and ***, respectively.
#¬ https://zsh.sourceforge.io/Doc/Release/Expansion.html#Recursive-Globbing
setopt GLOB_STAR_SHORT

#? Sort numbers numerically, not lexicographically.
setopt NUMERIC_GLOB_SORT

#? Disable mail checking
setopt no_mailwarn

# TODO: Disable automatic pushd when changing directories. This can improve performance when changing directories frequently, but I am not sure if I actually want this.
# setopt no_auto_pushd
