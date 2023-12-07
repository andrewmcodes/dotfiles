#!/usr/bin/env zsh

# Add the functions directory to the path
fpath=("${0:h:h}/functions" "${fpath[@]}")
# Autoload all of the functions in the functions directory
autoload -Uz $fpath[1]/*(.:t)

#* Creates a directory and then changes into it
function mkcd() { mkdir -p "$@" && cd "$_"; }

#* Stops the running PostgreSQL server
function pg_stop {
  local currently_running_version=$(psql --no-psqlrc -t -c 'show server_version;' postgres | xargs)
  $HOME/.asdf/installs/postgres/$currently_running_version/bin/pg_ctl -D $HOME/.asdf/installs/postgres/$currently_running_version/data stop
}

#* Starts the PostgreSQL server defined by asdf
function pg_start {
  local version_to_run=$(asdf which postgres | awk -F/ '{print $7}')
  $HOME/.asdf/installs/postgres/$version_to_run/bin/pg_ctl -D $HOME/.asdf/installs/postgres/$version_to_run/data start
}

# * Switches the running PostgreSQL server based on the version passed in
# @param $1 - The version of PostgreSQL to switch to
function pg_switch {
  local version_to_run=$1
  local currently_running_version=$(psql --no-psqlrc -t -c 'show server_version;' postgres | xargs)

  # check if you're erroneously switching to the same version
  if [ "$version_to_run" = "$currently_running_version" ]; then
    echo "Postgres $version_to_run is already running."
    return 1
  fi

  echo Switching from $currently_running_version to $version_to_run
  # stop the currently running postgres server
  $HOME/.asdf/installs/postgres/$currently_running_version/bin/pg_ctl \
    -D $HOME/.asdf/installs/postgres/$currently_running_version/data \
    stop
  # start the server to be started
  $HOME/.asdf/installs/postgres/$version_to_run/bin/pg_ctl \
    -D $HOME/.asdf/installs/postgres/$version_to_run/data \
    start
  # switch the global asdf version, this ensures that `psql` is shimmed to the right version-directory
  asdf global postgres $version_to_run
}

#* Rails function that will run the rails command in the correct context
function rails() {
  if [[ -f bin/rails ]]; then
    bin/rails $@
  elif [[ -f Gemfile && -f Gemfile.lock ]]; then
    bundle exec rails $@
  elif [[ -n $(which rails) ]]; then
    command rails $@
  else
    echo "Rails not found"
  fi
}
