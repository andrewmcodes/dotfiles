#!/bin/zsh

## Prompt

# autoload -Uz compinit
# compinit

# TODO: this isn't using the correct zi functionality - but it works
# eval "$(oh-my-posh completion zsh)"
# eval "$(oh-my-posh init zsh --config ~/.config/zsh/theme/andrewmcodes.omp.json)"

zi ice as"command" from"gh-r" \
  atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
  atpull"%atclone" src"init.zsh"
zi light starship/starship
