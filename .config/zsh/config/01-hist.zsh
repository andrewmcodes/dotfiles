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
#? Keep only the most recent copy of each duplicate entry in history.
setopt HIST_IGNORE_ALL_DUPS
#? Auto-sync history between concurrent sessions.
setopt SHARE_HISTORY
