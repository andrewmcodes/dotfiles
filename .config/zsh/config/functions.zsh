#!/usr/bin/env zsh

fpath=("${0:h:h}/functions" "${fpath[@]}")
autoload -Uz $fpath[1]/*(.:t)

function pg_stop {
  local currently_running_version=$(psql --no-psqlrc -t -c 'show server_version;' postgres | xargs)
  $HOME/.asdf/installs/postgres/$currently_running_version/bin/pg_ctl -D $HOME/.asdf/installs/postgres/$currently_running_version/data stop
}

function pg_start {
  local version_to_run=$(asdf which postgres | awk -F/ '{print $7}')
  $HOME/.asdf/installs/postgres/$version_to_run/bin/pg_ctl -D $HOME/.asdf/installs/postgres/$version_to_run/data start
}
