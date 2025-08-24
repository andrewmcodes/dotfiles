alias "...."="cd ../../"
alias "..."="cd ../.." # Corrected alias
alias ".."="cd .."
alias "~"="cd ~"
alias %= \$= #? Define the % symbol as an alias for the $= symbol
# New
# Chezmoi
alias {cz.apply,chezA}="chezmoi apply"
alias {cz.diff,chezd}="chezmoi diff"
alias {cz.edit,cheze}="chezmoi edit"
alias {cz.readd,chezR}="chezmoi re-add"
# TMUX
alias tmA="tmux attach -t"
alias tmK="tmux kill-session -t"
alias tmL="tmux ls"
alias tmN="tmux new-session -s"
alias tmS="tmux switch -t"
# Yarn
alias y="yarn"
alias yA="yarn add"
alias yAd="yarn add -D"
# brew
alias brewd="brew doctor"
alias brewi="brew install"
alias brewI="brew info"
alias brewl="brew list"
alias brewL="brew leaves"
alias brewo="brew outdated"
alias brewr="brew reinstall"
alias brews="brew search"
alias brewS="brew services"
alias brewu="brew update"
alias brewU="brew upgrade"
alias brewUp="brew update && brew upgrade && brew cleanup"
alias brewx="brew uninstall"
alias brewX="brew uninstall --force"
# Casks
alias caski="brew install --cask"
alias caskl="brew list --cask"
alias casko="brew outdated --cask"
alias caskr="brew reinstall --cask"
alias casks="brew search --cask"
alias caskU="brew upgrade --cask"
alias caskx="brew uninstall --cask"
alias caskX="brew uninstall --cask --force"
alias caskz="brew uninstall --cask --zap"
# History
alias hisT="history | tail"
alias hisG="history | grep"
# Rails
alias r="rails"
alias rc="rails console"
alias rDbc="rails dbconsole"
alias rT="rails -T | awk '{print $2}' | fzf --preview 'rails {1} --help' | xargs -I {} rails {}"
alias rdm="rails db:migrate"
alias rG="rails generate"
alias rR="rails routes"
alias rRg="rails routes -g"
alias rRc="rails routes -c"
alias rs="rails server"
# Redis
alias redis.s="redis-server --daemonize yes"
# LS
alias tree="eza --tree --git --group-directories-first"          #? Display directory tree - replaces `tree` cli
alias ls='eza --icons --group-directories-first'
alias lsa='eza -a --icons --group-directories-first'
alias lt='eza -T --group-directories-first --icons --git'
alias lta='eza -Ta --group-directories-first --icons --git'
alias ll='eza -lmh --group-directories-first --color-scale --icons'
alias la='eza -lamhg --group-directories-first --color-scale --icons --git'
alias laa='eza -lamhg@ --group-directories-first --color-scale --icons --git'
alias lx='eza -lbhHigUmuSa@ --group-directories-first --color-scale --icons --git --time-style=long-iso'
# Cat
alias cat="bat" #? Use bat by default
# Find
alias fDir='fd -H --type d | fzf || echo .' # This alias is used to find directories using the 'fd' command and filter the results using 'fzf'. If no directory is selected, it will default to the current directory.
# Duti
alias dutiA='duti -v "${XDG_CONFIG_HOME:-$HOME/.config}/duti"'
# Overmind
alias {oC,oc}='overmind connect'
alias {oCw,ocw}='overmind connect web'
alias {oK,ok}='overmind kill'
alias oRw='overmind restart web'
# Heroku
alias heroRc='heroku run rails c'
alias heroRC='heroku run rails c -a podia -- -- --noautocomplete' # Courtesty of @wafflewitch
# VS code
alias c="code ."
alias ci="code-insiders"
alias "ci."="code-insiders ."
####################
# Old
####################
alias b="bundle"
alias be="bundle exec"
alias up="git pull && bundle check || bundle && yarn && rails db:migrate"

alias diff="diff --color"
alias g="git"
alias ga="git add"
alias gb="git branch"
alias gb9='git for-each-ref --sort=-committerdate --count=9 --format='\''%(refname:short)'\'' refs/heads/'
alias gbd="git branch -d"
alias gc="git commit"
alias gcm="git commit -m"
alias gco="git checkout"
alias gcom="git checkout main"
alias gd="git diff"
alias gi="gem install"
alias gl="git log"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias gpl="git pull"
alias gr="git rebase"
alias grbc="git rebase --continue"
alias gs="git status"
alias gundo="git reset --soft HEAD~1"
alias gup="git pull --rebase"
alias gupm="git pull --rebase origin main"
alias gwip="git add -A; git commit -m 'chore: wip'"

# Copy and pretty print JSON data from clipboard using jq
alias jason="pbpaste -Prefer txt | jq . | pbcopy"
