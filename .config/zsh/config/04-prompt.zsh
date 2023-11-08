#!/bin/zsh

## Prompt

# autoload -Uz compinit
# compinit

# TODO: this isn't using the correct zi functionality - but it works
eval "$(oh-my-posh completion zsh)"
eval "$(oh-my-posh init zsh --config ~/.config/zsh/theme/andrewmcodes.omp.json)"
