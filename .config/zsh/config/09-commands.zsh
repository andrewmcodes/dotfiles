#!/usr/bin/env zsh

##
# Commands, funtions and aliases
#
# Always set aliases _last,_ so they don't class with function definitions.
#

# These aliases enable us to paste example code into the terminal without the
# shell complaining about the pasted prompt symbol.
alias %= \$=

alias cat="bat"            # Use bat by default
alias ls="exa"             # Use exa by default
alias ll='exa -l'          # List files in long format
alias la='exa -la'         # List all files, including hidden files
alias lt='exa -lt'         # List files sorted by modification time
alias lr='exa -lr'         # List files in reverse order
alias tree='exa --tree'    # Display directory tree

# Aliases for Git commands
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gr='git rebase'
alias grbc='git rebase --continue'
alias gs='git status'
alias gpl='git pull'
alias gup='git pull --rebase'
alias gupm='git pull --rebase origin main'

# Other Git aliases
alias gb='git branch'
alias gbd='git branch -d'
alias gb9='git for-each-ref --sort=-committerdate --count=9 --format='\''%(refname:short)'\'' refs/heads/'
alias gwip="git add -A; git commit -m 'WIP!'"
alias gundo="git reset --soft HEAD~1"

# VS Code
alias c='code .'
alias ci='code-insiders'
alias dotfiles='code-insiders ~/git/andrewmcodes/dotfiles'

# Bundler
alias b='bundle'
alias be='bundle exec'

# Yarn
alias y='yarn'
alias yad='yarn add -D'
alias ya='yarn add'

# Redis
alias redis_start='redis-server --daemonize yes'

# Overmind
alias oc="overmind connect"
alias ocw="overmind connect web"
alias ok="overmind kill"
alias oe="overmind echo"
alias orw="overmind restart web"

# Nav
alias '~'='cd ~'
alias '..'='cd ..'
alias '...'='cd cd ../..'
alias '....'='cd ../../'


alias r='rails'
alias rc='rails console'
alias rs='rails server'
alias rg='rails generate'
alias rd='rails dbconsole'
alias rdb='rails db'
alias rdm='rails db:migrate'
alias rds='rails db:seed'
alias up="git pull && bundle check || bundle && yarn && rails db:migrate"
alias rr='rails routes'
alias rrg='rails routes -g'

# Heroku
alias hk="heroku"
alias hkc="heroku config"
alias hrc=" heroku run rails c"
## Courtesty of @wafflewitch
alias hrrcap='heroku run rails c -a podia -- -- --noautocomplete'

# LS
alias la='ls -A'
alias l='ls -alFtr'
alias ls='ls -G'

# History
alias h='history | tail'
alias hg='history | grep'

# Diff
alias diff='diff --color'

# Grep
alias grep='grep --color'

# Ruby gems
alias {gi,gemi}='gem install'

# Bridgetown
alias bt='bin/bridgetown'

# Homebrew
alias bi='brew install'
alias {bic,bci}='brew install --cask'
alias bup='brew update && brew upgrade --greedy && brew cleanup'
alias blc='brew list --cask'
alias bl='brew list'

# Shortcuts
alias sr='shortcuts run'

# Znap
alias zr='znap restart'

# JSON
alias jason='pbpaste -Prefer txt | jq . | pbcopy'

# tmux
alias tn="tmux new-session -s"
alias tk="tmux kill-session -t"
alias ta="tmux attach -t"
alias ts="tmux switch -t"
alias tl="tmux ls"

# `:` is a builtin command that does nothing. We use it here to stop Zsh from
# evaluating the value of our $expansion as a command.
: ${PAGER:='code-insiders --wait'}

# Associate file .extensions with programs.
# This lets you open a file just by typing its name and pressing enter.
# Note that the dot is implicit. So, `gz` below stands for files ending in .gz
alias -s {css,gradle,html,js,json,md,patch,properties,txt,xml,yml}=$PAGER
alias -s gz='gzip -l'
alias -s {log,out}='tail -F'

# Use `< file` to quickly view the contents of any file.
READNULLCMD=$PAGER

# Print the number of characters in the PATH variable
# echo $PATH | wc -c

# Safer alternatives to `rm`
if [[ $VENDOR == apple ]]; then
  alias rm='trash'
else
  alias rm='rm --preserve-root'
fi
