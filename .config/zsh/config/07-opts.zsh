#!/usr/bin/env zsh

## Shell options
#! Set these after sourcing plugins, because those might set options, too.

#? Don't let > overwrite files. To overwrite, use >| instead.
# setopt NO_CLOBBER

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

setopt auto_cd              # Use cd by typing directory name if it's not a command.
setopt auto_list            # Automatically list choices on ambiguous completion.
setopt auto_pushd           # Make cd push the old directory onto the directory stack.
setopt bang_hist            # Treat the '!' character, especially during Expansion.
setopt interactive_comments # Comments even in interactive shells.
setopt multios              # Implicit tees or cats when multiple redirections are attempted.
setopt no_beep              # Don't beep on error.
setopt prompt_subst         # Substitution of parameters inside the prompt each time the prompt is drawn.
setopt pushd_ignore_dups    # Don't push multiple copies directory onto the directory stack.
setopt pushd_minus          # Swap the meaning of cd +1 and cd -1 to the opposite.
