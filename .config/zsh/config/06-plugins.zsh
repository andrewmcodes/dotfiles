#!/usr/bin/env zsh

##
# Plugins
#

# zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=()
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=( forward-char forward-word end-of-line )
ZSH_AUTOSUGGEST_STRATEGY=( history )
ZSH_AUTOSUGGEST_HISTORY_IGNORE=$'(*\n*|?(#c80,)|*\\#:hist:push-line:)'

ZSH_HIGHLIGHT_HIGHLIGHTERS=( main brackets )

# Add the plugins you want to use here.
# -a sets the variable's type to array.
local -a plugins=(
  asdf-vm/asdf
  marlonrichert/zsh-autocomplete    # Real-time type-ahead completion. https://github.com/marlonrichert/zsh-autocomplete
  agkozak/zsh-z                     # Quickly jump to previously visited directories.
  marlonrichert/zsh-hist            # Edit history from the command line.
  marlonrichert/zcolors             # Colors for completions and Git
  zsh-users/zsh-autosuggestions     # Inline suggestions. https://github.com/zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting # Command-line syntax highlighting
)

# Auto-installed by Brew, but far worse than the one supplied by Zsh
rm -f $HOMEBREW_PREFIX/share/zsh/site-functions/_git{,.zwc}

# https://github.com/marlonrichert/zsh-autocomplete/blob/main/.zshrc
zstyle ':autocomplete:*' min-input 2

# Speed up the first startup by cloning all plugins in parallel, except the plugins that we already have.
znap clone $plugins

# Load each plugin, one at a time.
local p=
for p in $plugins; do
  znap source $p
done

# znap source ~/.config/op/plugins.sh

autoload -Uz pg_switch
autoload -Uz init
autoload -Uz mkcd
autoload -Uz toggle_desktop_icons
autoload -Uz update_shell
autoload -Uz ghlabels

# `znap eval <name> '<command>'` is like `eval "$( <command> )"` but with
# caching and compilation of <command>'s output, making it ~10 times faster.
znap eval zcolors zcolors

znap function _fuck fuck 'eval "$(thefuck --alias)"'
compctl -K _fuck fuck

znap eval direnv "asdf exec $(asdf which direnv) hook zsh"
# Add GitHub CoPilot CLI Aliases
znap eval github-copilot-cli 'github-copilot-cli alias -- zsh'
