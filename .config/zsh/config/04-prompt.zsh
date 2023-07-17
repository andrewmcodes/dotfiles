#!/bin/zsh

## Prompt
#? `znap prompt` can autoload our prompt function, because in 04-env.zsh, we added its parent dir to our $fpath.

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  znap eval oh-my-posh 'oh-my-posh init zsh --config ~/.config/zsh/theme/andrewmcodes.omp.json'
else
  znap prompt sindresorhus/pure
fi
