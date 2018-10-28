export ZSH=/Users/andrew.mason/.oh-my-zsh

ZSH_THEME="spaceship"

SPACESHIP_PROMPT_ADD_NEWLINE="true"
SPACESHIP_PROMPT_DEFAULT_PREFIX="$SPACESHIP_CHAR_SYMBOL"

SPACESHIP_GIT_BRANCH_COLOR="yellow"
SPACESHIP_GIT_STATUS_COLOR="yellow"
SPACESHIP_PROMPT_ORDER=(
  time          # Time stampts section
  user          # Username section
  dir           # Current directory section
  host          # Hostname section
  hg            # Mercurial section (hg_branch  + hg_status)
  package       # Package version
  node          # Node.js section
  ruby          # Ruby section
  elixir        # Elixir section
  xcode         # Xcode section
  swift         # Swift section
  golang        # Go section
  php           # PHP section
  rust          # Rust section
  haskell       # Haskell Stack section
  julia         # Julia section
  docker        # Docker section
  aws           # Amazon Web Services section
  venv          # virtualenv section
  conda         # conda virtualenv section
  pyenv         # Pyenv section
  dotnet        # .NET section
  ember         # Ember.js section
  kubecontext   # Kubectl context section
  git           # Git section (git_branch + git_status)
  line_sep      # Line break
  battery       # Battery level and status
  vi_mode       # Vi-mode indicator
  jobs          # Background jobs indicator
  exit_code     # Exit code section
  char          # Prompt character
)

COMPLETION_WAITING_DOTS="true"

plugins=(
  docker
  docker-compose
  git
  rails
  zsh-syntax-highlighting
  z
)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

function code {
    if [[ $# = 0 ]]
    then
        open -a "Visual Studio Code"
    else
        local argPath="$1"
        [[ $1 = /* ]] && argPath="$1" || argPath="$PWD/${1#./}"
        open -a "Visual Studio Code" "$argPath"
    fi
}

source $ZSH/oh-my-zsh.sh

alias zshconfig="code ~/.zshrc"
alias ohmyzsh="code ~/.oh-my-zsh"

alias mysql="/usr/local/bin/mysql"
alias mysqladmin="/usr/local/bin/mysqladmin"

alias dcrc="docker-compose run app bin/rails c"
alias dcrr="docker-compose run app bin/rails"
alias dcrt="docker-compose run app bin/rails test"
alias dcab="docker-compose exec app bash"

alias b="bundle"

# add Homebrew `/usr/local/bin` and User `~/bin` to the `$PATH`
PATH=/usr/local/bin:$PATH
PATH=$HOME/bin:$PATH
export PATH="$(brew --prefix coreutils)/libexec/gnubin:/usr/local/bin:$PATH"
export PATH="$(brew --prefix gnu-tar)/libexec/gnubin:/usr/local/bin:$PATH"
export PATH="$(brew --prefix gnu-sed)/libexec/gnubin:/usr/local/bin:$PATH"

eval "$(rbenv init -)"
eval "$(pyenv init -)"
export PATH="/usr/local/opt/qt@5.5/bin:$PATH"

# added by travis gem
[ -f /Users/andrew.mason/.travis/travis.sh ] && source /Users/andrew.mason/.travis/travis.sh
export PATH="/usr/local/opt/openssl/bin:$PATH"
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
