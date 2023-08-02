#!/usr/bin/env zsh

## Environment variables

export OP_BIOMETRIC_UNLOCK_ENABLED=true
export HOMEBREW_CASK_OPTS="--appdir=/Applications --fontdir=/Library/Fonts --no-quarantine"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_COLOR=1
export HOMEBREW_BAT=1
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$HOMEBREW_PREFIX/opt/openssl@1.1"
export DISABLE_SPRING=true
[[ -f $HOME/.gemrc.local ]] && export GEMRC=$HOME/.gemrc.local #? Use a local gemrc if it exists.
export EDITOR="code --wait"
export SHELL="$HOMEBREW_PREFIX/bin/zsh"
#* Don’t clear the screen after quitting a manual page
export MANPAGER="less -X"
#* Path
export -U PATH path FPATH fpath MANPATH manpath #? -U ensures each entry in these is Unique (that is, discards duplicates).
export -UT INFOPATH infopath  #? -T creates a "tied" pair; see below.

#? $PATH and $path (and also $FPATH and $fpath, etc.) are "tied" to each other. Modifying one will also modify the other.
#? Note that each value in an array is expanded separately. Thus, we can use ~ for $HOME in each $path entry.
path=(
    /home/linuxbrew/.linuxbrew/bin(N)	# (N): null if file doesn't exist
    $HOMEBREW_PREFIX/opt/curl/bin
    $path
    ~/.local/bin
)

#* Add your functions to your $fpath, so you can autoload them.
fpath=(
    $ZDOTDIR/functions
    $fpath
    ~/.local/share/zsh/site-functions
)

if command -v brew > /dev/null; then
  znap eval brew-shellenv 'brew shellenv'

  #? Add dirs containing completion functions to your $fpath and they will be
  #? picked up automatically when the completion is initialized.
  #? Here, we add it to the end of $fpath, so that we use brew's completions
  #? only for those commands that zsh doesn't already know how to complete.
  fpath+=( $HOMEBREW_PREFIX/share/zsh/site-functions )
fi
