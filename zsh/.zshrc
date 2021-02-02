# Load Antigen
source "$HOME/dotfiles/antigen.zsh"

# Load Antigen configurations
antigen init ~/dotfiles/.antigenrc

export GPG_TTY=$(tty)

source $HOME/dotfiles/environment.zsh
source $HOME/dotfiles/functions.zsh
source $HOME/dotfiles/aliases.zsh
