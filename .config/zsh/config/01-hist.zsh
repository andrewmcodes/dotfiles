#!/usr/bin/env zsh

## History settings
#! Always set these first, so history is preserved, no matter what happens.

if [[ $VENDOR == apple ]]; then
  HISTFILE=~/Library/Mobile\ Documents/com\~apple\~CloudDocs/zsh_history
  setopt extendedglob
  #? Sometimes when the histfile is kept in iCloud, it is empty when Zsh starts up.
  [[ -z $HISTFILE(#qL+0N) && -r "$HISTFILE 2" ]] && mv "$HISTFILE 2" "$HISTFILE"
else
  HISTFILE=$XDG_DATA_HOME/zsh/history
fi

#? Max number of entries to keep in history file.
SAVEHIST=$(( 100 * 1000 ))
#? Max number of history entries to keep in memory. Zsh recommended value
HISTSIZE=$(echo "1.2 * $SAVEHIST" | bc)
#? Use modern file-locking mechanisms, for better safety & performance.
setopt HIST_FCNTL_LOCK
setopt append_history         # Allow multiple sessions to append to one Zsh command history.
setopt extended_history       # Show timestamp in history.
setopt hist_expire_dups_first # Expire A duplicate event first when trimming history.
setopt hist_find_no_dups      # Do not display a previously found event.
setopt hist_ignore_all_dups   # Remove older duplicate entries from history.
setopt hist_ignore_dups       # Do not record an event that was just recorded again.
setopt hist_ignore_space      # Do not record an Event Starting With A Space.
setopt hist_reduce_blanks     # Remove superfluous blanks from history items.
setopt hist_save_no_dups      # Do not write a duplicate event to the history file.
setopt hist_verify            # Do not execute immediately upon history expansion.
setopt inc_append_history     # Write to the history file immediately, not when the shell exits.
setopt share_history          # Share history between different instances of the shell.
