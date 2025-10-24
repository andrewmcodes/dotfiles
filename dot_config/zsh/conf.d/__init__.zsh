#
# __init__: This runs prior to any other conf.d contents.
#

# Apps
export EDITOR=${EDITOR:-nvim}
export VISUAL=${VISUAL:-code}
export PAGER=${PAGER:-less}

# Set the list of directories that cd searches.
cdpath=(
  $XDG_PROJECTS_DIR(N/)
  $cdpath
)

# Set the list of directories that Zsh searches for programs.
path=(
  # core
  $prepath
  $path

  # Homebrew prefix was set in .zshenv
  $HOMEBREW_PREFIX/opt/curl/bin(N)
  $HOMEBREW_PREFIX/share/npm/bin(N)
  $HOMEBREW_PREFIX/opt/ruby/bin(N)
  $HOMEBREW_PREFIX/lib/ruby/gems/*/bin(N)
  $HOME/.gem/ruby/*/bin(N)
)
