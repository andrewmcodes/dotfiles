#!/usr/bin/env zsh

## Plugins ##

#* zsh-users/zsh-autosuggestions
# ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=()
# ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=( forward-char forward-word end-of-line )
# ZSH_AUTOSUGGEST_STRATEGY=( history )
# ZSH_AUTOSUGGEST_HISTORY_IGNORE=$'(*\n*|?(#c80,)|*\\#:hist:push-line:)'

zi ice as'null' sbin'bin/*'
zi light z-shell/zsh-diff-so-fancy

zi pack"bgn+keys" for fzf
zi pack for ls_colors
zi wait pack atload=+"zicompinit; zicdreplay" for brew-completions

zi load asdf-vm/asdf

# https://wiki.zshell.dev/ecosystem/plugins/zbrowse
zi load z-shell/zui
zi load z-shell/zbrowse

zi load z-shell/zi-console
zi light z-shell/zzcomplete

zi light-mode for \
  marlonrichert/zsh-autocomplete \
  agkozak/zsh-z \
  marlonrichert/zsh-hist

zi wait lucid for \
  atinit"ZI[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
  z-shell/F-Sy-H \
  blockf \
  zsh-users/zsh-completions \
  atload"!_zsh_autosuggest_start" \
  zsh-users/zsh-autosuggestions

# ¬ https://github.com/marlonrichert/zsh-autocomplete/blob/main/.zshrc
zstyle ':autocomplete:*' min-input 3

zi ice as'program' from'gh-r' mv'direnv* -> direnv'
zi light direnv/direnv

zi ice from'gh-r' as'program' mv'fd* fd' sbin'**/fd(.exe|) -> fd'
zi light @sharkdp/fd
# ¬ https://www.npmjs.com/package/@githubnext/github-copilot-cli && https://githubnext.com/projects/copilot-cli
# znap eval github-copilot-cli 'github-copilot-cli alias -- zsh'

# autoload -Uz compinit
# compinit
zi cdreplay -q # <- execute compdefs provided by rest of plugins
zi cdlist      # look at gathered compdefs
