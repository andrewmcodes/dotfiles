#!/usr/bin/env zsh

## Plugins ##

#* zsh-users/zsh-autosuggestions
# ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=()
# ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=( forward-char forward-word end-of-line )
ZSH_AUTOSUGGEST_STRATEGY=( history )
ZSH_AUTOSUGGEST_HISTORY_IGNORE=$'(*\n*|?(#c80,)|*\\#:hist:push-line:)'

ZSH_HIGHLIGHT_HIGHLIGHTERS=( main brackets )

#? Add the plugins you want to use here. -a sets the variable's type to array.
local -a plugins=(
  asdf-vm/asdf
  marlonrichert/zcolors             # Colors for completions and Git
  marlonrichert/zsh-autocomplete    # Real-time type-ahead completion. https://github.com/marlonrichert/zsh-autocomplete
  agkozak/zsh-z                     # Quickly jump to previously visited directories.
  marlonrichert/zsh-hist            # Edit history from the command line.
  zsh-users/zsh-autosuggestions     # Inline suggestions. https://github.com/zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting # Command-line syntax highlighting
)

#? Auto-installed by Brew, but far worse than the one supplied by Zsh
rm -f $HOMEBREW_PREFIX/share/zsh/site-functions/_git{,.zwc}

# ¬ https://github.com/marlonrichert/zsh-autocomplete/blob/main/.zshrc
zstyle ':autocomplete:*' min-input 3

#? Speed up the first startup by cloning all plugins in parallel, except the plugins that we already have.
znap clone $plugins

#? Load each plugin, one at a time.
local p=
for p in $plugins; do
  znap source $p
done

# FZF Auto-completion
source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
# FZF Key bindings
source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"

#? `znap eval <name> '<command>'` is like `eval "$( <command> )"` but with caching and compilation of <command>'s output

# ¬ https://github.com/marlonrichert/zcolors/tree/main#installation
# znap eval zcolors "zcolors ${(q)LS_COLORS}" # eval zcolors zcolors
# ¬ https://github.com/nvbn/thefuck
znap function _fuck fuck 'eval "$(thefuck --alias)"'
compctl -K _fuck fuck
# ¬ https://github.com/asdf-community/asdf-direnv
znap eval direnv "asdf exec $(asdf which direnv) hook zsh"
# ¬ https://www.npmjs.com/package/@githubnext/github-copilot-cli && https://githubnext.com/projects/copilot-cli
znap eval github-copilot-cli 'github-copilot-cli alias -- zsh'
