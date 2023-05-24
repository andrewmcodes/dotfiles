#
# This file is the entry point for your Zsh configuration. It's the first file
# that is sourced when Zsh starts up, and it's loaded only once.
#


# If M1 Mac, eval brew shellenv
[[ $(uname -m) == arm64 ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
