##
# Named directories
# https://github.com/marlonrichert/zsh-launchpad/blob/main/.config/zsh/rc.d/02-dirs.zsh
#
# Create shortcuts for your favorite directories.
# Set these early, because it affects how dirs are displayed and printed.
hash -d zsh=$ZDOTDIR
hash -d conf=$HOME/.config
hash -d logs=$LOG_DIR
hash -d downloads=$HOME/Downloads
hash -d desktop=$HOME/Desktop
hash -d brain=$HOME/git/andrewmcodes/digital-brain
hash -d dotfiles=$HOME/git/andrewmcodes/dotfiles
hash -d podia=$HOME/git/work/podia
hash -d applications=/Applications
hash -d archive=$HOME/Documents/4_Archive
hash -d documents=$HOME/Documents

# `hash -d <name>=<path>` makes ~<name> a shortcut for <path>.
# You can use this ~name anywhere you would specify a dir, not just with `cd`!
