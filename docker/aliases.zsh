#!/bin/zsh

alias da="docker attach"
alias daid="docker-compose ps -q app"
alias dcab="docker-compose exec app bash"
alias dcbundle="docker-compose exec app bundle"
alias dcm="docker-compose exec app bin/rails db:migrate"
alias dctb="docker-compose exec test bash"
alias dcyarn="docker-compose exec app yarn"
alias drbundle="docker-compose run app bundle"
alias drc="docker-compose exec app bin/rails c"
alias drrc="docker-compose run app bin/rails c"
alias drrt="docker-compose run app bin/rails test"
alias drst="docker-compose exec app bin/rails test:system"
alias drt="docker-compose exec app bin/rails test"
alias dryarn="docker-compose run app yarn"
alias dtid="docker-compose ps -q test"
alias lzd='lazydocker'
