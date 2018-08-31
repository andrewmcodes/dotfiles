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

source $ZSH/oh-my-zsh.sh

alias zshconfig="code ~/.zshrc"
alias ohmyzsh="code ~/.oh-my-zsh"
alias mysql="/usr/local/mysql/bin/mysql"
alias mysqladmin="/usr/local/mysql/bin/mysqladmin"
alias dcrc="docker-compose run app bin/rails c"
alias dcrr="docker-compose run app bin/rails"
alias dcrt="docker-compose run app bin/rails test"
alias dcab="docker-compose exec app bash"

export PATH="/usr/local/opt/qt/bin:$PATH"
export PATH="/usr/local/opt/sqlite/bin:$PATH"
export PATH="\$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export PATH="/usr/local/opt/openssl/bin:$PATH"
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export PATH="/usr/local/opt/qt@5.5/bin:$PATH"
export PATH="/usr/local/opt/icu4c/bin:$PATH"
export PATH="/usr/local/opt/icu4c/sbin:$PATH"
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"
PATH=/bin:/usr/bin:/usr/local/bin:${PATH}
eval "$(rbenv init -)"
eval "$(pyenv init -)"
export PATH="/usr/local/sbin:$PATH"
export GITHUB_TOKEN="c461ec8dfc1eb5f1b28533a9eecaaf5e20eba1ca"
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"

export PATH
