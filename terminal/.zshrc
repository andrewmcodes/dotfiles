export ZSH=/Users/andrew.mason/.oh-my-zsh

# ZSH auto-complete
fpath=(/usr/local/share/zsh-completions $fpath)

ZSH_THEME="spaceship"

SPACESHIP_PROMPT_ADD_NEWLINE="true"
SPACESHIP_PROMPT_DEFAULT_PREFIX="$SPACESHIP_CHAR_SYMBOL"

SPACESHIP_GIT_BRANCH_COLOR="yellow"
SPACESHIP_GIT_STATUS_COLOR="yellow"
SPACESHIP_PROMPT_ORDER=(
  time # Time stampts section
  user # Username section
  dir # Current directory section
  host # Hostname section
  hg # Mercurial section (hg_branch  + hg_status)
  package # Package version
  node # Node.js section
  ruby # Ruby section
  elixir # Elixir section
  xcode # Xcode section
  swift # Swift section
  golang # Go section
  php # PHP section
  rust # Rust section
  haskell # Haskell Stack section
  docker # Docker section
  aws # Amazon Web Services section
  venv # virtualenv section
  pyenv # Pyenv section
  dotnet # .NET section
  ember # Ember.js section
  kubecontext # Kubectl context section
  git # Git section (git_branch + git_status)
  line_sep # Line break
  battery # Battery level and status
  vi_mode # Vi-mode indicator
  jobs # Background jobs indicator
  exit_code # Exit code section
  char # Prompt character
)

COMPLETION_WAITING_DOTS="true"

plugins=(
  ruby
  rails
  docker-compose
  git
  vscode
  z
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# VS Code
function code() {
  if [[ $# == 0 ]]; then
    open -a "Visual Studio Code"
  else
    local argPath="$1"
    [[ $1 == /* ]] && argPath="$1" || argPath="$PWD/${1#./}"
    open -a "Visual Studio Code" "$argPath"
  fi
}

# VS Code is default editor
export EDITOR="code -w"
export GITHUB_TOKEN="XXXXX"
# Default ZSH
source $ZSH/oh-my-zsh.sh

# ENV vars
export DISABLE_SPRING=1

# Aliases
dappattach() {
  appId=$(docker ps | grep app | awk '{print $NF}')
  docker attach $appId
}

alias zshconfig="code ~/.zshrc" # Alias
alias ohmyzsh="code ~/.oh-my-zsh"
alias mysql="/usr/local/bin/mysql"
alias mysqladmin="/usr/local/bin/mysqladmin"
alias drrc="docker-compose run app bin/rails c"
alias drrt="docker-compose run app bin/rails test"
alias drc="docker-compose exec app bin/rails c"
alias drt="docker-compose exec app bin/rails test"
alias drst="docker-compose exec app bin/rails test:system"
alias dcm="docker-compose exec app bin/rails db:migrate"
alias dcab="docker-compose exec app bash"
alias dctb="docker-compose exec test bash"
alias b="bundle"
alias dcbundle="docker-compose exec app bundle"
alias dcyarn="docker-compose exec app yarn"
alias drbundle="docker-compose run app bundle"
alias dryarn="docker-compose run app yarn"
alias bwds="./bin/webpack-dev-server"
alias daid="docker-compose ps -q app"
alias dtid="docker-compose ps -q test"
alias da="docker attach"
alias gbrd="git branch | grep -v "master" | xargs git branch -D"
alias add_dock_spacer="defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="spacer-tile";}'; killall Dock"
alias show_mysql_db="mysql -u root -p$MYSQL_ROOT_PASSWORD -e 'show databases;'"
alias clean_branches="git branch -vv | grep 'origin/.*: gone]' | awk '{print $1}' | xargs git branch -d"
alias lzd='lazydocker'
alias besk='redis-cli flushall && bundle exec sidekiq -C config/sidekiq.yml'

# add Homebrew `/usr/local/bin` and User `~/bin` to the `$PATH`
PATH=/usr/local/bin:$PATH
PATH=$HOME/bin:$PATH

export PATH="/usr/local/opt/openssl/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"

# GPG
export GPG_TTY=$(tty)

# Rbenv
eval "$(rbenv init -)"

# Pyenv
eval "$(pyenv init -)"

# thefuck
eval $(thefuck --alias)
