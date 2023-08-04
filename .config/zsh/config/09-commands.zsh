#!/usr/bin/env zsh

## Functions
#? Lazy load the functions that we use most often.
autoload -Uz pg_switch
autoload -Uz init
autoload -Uz mkcd
autoload -Uz toggle_desktop_icons
autoload -Uz update_shell
autoload -Uz ghlabels
autoload -Uz os
autoload -Uz gg
autoload -Uz colormap
autoload -Uz zsh-list-keybindings
autoload -Uz import_obsidian_plugins

## Vendor Specific
if [[ $VENDOR == apple ]]; then
  autoload -Uz trash
  # alias rm="trash"
else
  # alias rm="rm --preserve-root"
fi

## Aliases
#! Always set aliases _last,_ so they don"t class with function definitions.
alias "...."="cd ../../"
alias "..."="cd cd ../.."
alias ".."="cd .."
alias "~"="cd ~"
alias %= \$= #? Define the % symbol as an alias for the $= symbol
alias b="bundle"
alias be="bundle exec"
alias bi="brew install"
alias bic="brew install --cask"
alias bl="brew list"
alias blc="brew list --cask"
alias bt="bin/bridgetown"
alias bup="brew update && brew upgrade --greedy && brew cleanup"
alias c="code ."
alias cat="bat" #? Use bat by default
alias ci="code-insiders"
alias diff="diff --color"
alias dotfiles="code-insiders $HOME/git/andrewmcodes/dotfiles"
alias brain="code-insiders $HOME/git/andrewmcodes/digital-brain"
alias g="git"
alias ga="git add"
alias gb="git branch"
alias gb9='git for-each-ref --sort=-committerdate --count=9 --format='\''%(refname:short)'\'' refs/heads/'
alias gbd="git branch -d"
alias gc="git commit"
alias gcm="git commit -m"
alias gco="git checkout"
alias gd="git diff"
alias gi="gem install"
alias gl="git log"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias gpl="git pull"
alias gr="git rebase"
alias grbc="git rebase --continue"
alias grep="grep --color"
alias gs="git status"
alias gundo="git reset --soft HEAD~1"
alias gup="git pull --rebase"
alias gupm="git pull --rebase origin main"
alias gwip="git add -A; git commit -m 'chore: wip'"
alias h="history | tail"
alias hg="history | grep"
alias hk="heroku"
alias hkc="heroku config"
alias hrc=" heroku run rails c"
alias hrrcap="heroku run rails c -a podia -- -- --noautocomplete" # Courtesty of @wafflewitch
alias jason="pbpaste -Prefer txt | jq . | pbcopy"
alias la="exa -la" #? List all files, including hidden files, formerly "ls -A"
alias ll="exa -l" #? List files in long format
alias lr="exa -lr" #? List files in reverse order
alias ls="exa" #? Use exa by default
alias lt="exa -lt" #? List files sorted by modification time
alias oc="overmind connect"
alias ocw="overmind connect web"
alias ok="overmind kill"
alias orw="overmind restart web"
alias podia="code-insiders ~/git/work/podia"
alias r="rails"
alias rc="rails console"
alias rcd="rails dbconsole"
alias rdb="rails db"
alias rdbm="rails db:migrate"
alias redis_start="redis-server --daemonize yes"
alias rg="rails generate"
alias rr="rails routes"
alias rrg="rails routes -g"
alias rs="rails server"
alias sr="shortcuts run"
alias ta="tmux attach -t"
alias tk="tmux kill-session -t"
alias tl="tmux ls"
alias tn="tmux new-session -s"
alias tree="exa --tree" #? Display directory tree
alias ts="tmux switch -t"
alias up="git pull && bundle check || bundle && yarn && rails db:migrate"
alias y="yarn"
alias ya="yarn add"
alias yad="yarn add -D"
alias zr="znap restart"

#* Stop Zsh from evaluating the value of our $expansion as a command.
#? `:` is a builtin command that does nothing.
: ${PAGER:="code-insiders --wait"}

#* Associate file .extensions with programs.
#? This lets you open a file just by typing its name and pressing enter.
#? Note that the dot is implicit. So, `gz` below stands for files ending in .gz
alias -s {css,gradle,html,js,json,md,patch,properties,txt,xml,yml}=$PAGER
alias -s gz="gzip -l"
alias -s {log,out}="tail -F"

#* Use `< file` to quickly view the contents of any file.
READNULLCMD=$PAGER
