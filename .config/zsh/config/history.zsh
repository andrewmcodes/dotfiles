#
# History
#

# Remove older command from the history if a duplicate is to be added.
if [[ $VENDOR == apple ]]; then
  HISTFILE=$DATA_DIR/zsh_history
  setopt extendedglob
  # Sometimes when the histfile is kept in iCloud, it is empty when Zsh starts up.
  [[ -z $HISTFILE(#qL+0N) && -r "$HISTFILE 2" ]] && mv "$HISTFILE 2" "$HISTFILE"
else
  HISTFILE=$XDG_DATA_HOME/zsh/history
fi

SAVEHIST=$(( 100 * 1000 ))
HISTSIZE=$(echo "1.2 * $SAVEHIST" | bc)

setopt appendhistory notify
unsetopt beep nomatch

setopt bang_hist                # Treat The '!' Character Specially During Expansion.
setopt inc_append_history       # Write To The History File Immediately, Not When The Shell Exits.
setopt share_history            # Share History Between All Sessions.
setopt hist_expire_dups_first   # Expire A Duplicate Event First When Trimming History.
setopt hist_ignore_dups         # Do Not Record An Event That Was Just Recorded Again.
setopt hist_ignore_all_dups     # Delete An Old Recorded Event If A New Event Is A Duplicate.
setopt hist_find_no_dups        # Do Not Display A Previously Found Event.
setopt hist_ignore_space        # Do Not Record An Event Starting With A Space.
setopt hist_save_no_dups        # Do Not Write A Duplicate Event To The History File.
setopt hist_verify              # Do Not Execute Immediately Upon History Expansion.
setopt extended_history         # Show Timestamp In History.
setopt hist_reduce_blanks     # Remove superfluous blanks from history items.if [[ $VENDOR == apple ]]; then
