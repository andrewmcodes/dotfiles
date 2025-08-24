# ZSH Aliases Documentation

This document provides a comprehensive list of all available aliases organized by category.

## Navigation Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `....` | `cd ../../` | Navigate up two directory levels |
| `...` | `cd ../..` | Navigate up two directory levels |
| `..` | `cd ..` | Navigate up one directory level |
| `~` | `cd ~` | Navigate to home directory |

## Chezmoi Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `cz.apply`, `chezA` | `chezmoi apply` | Apply chezmoi changes |
| `cz.diff`, `chezd` | `chezmoi diff` | Show chezmoi differences |
| `cz.edit`, `cheze` | `chezmoi edit` | Edit chezmoi files |
| `cz.readd`, `chezR` | `chezmoi re-add` | Re-add files to chezmoi |

## TMUX Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `tmA` | `tmux attach -t` | Attach to a tmux session |
| `tmK` | `tmux kill-session -t` | Kill a tmux session |
| `tmL` | `tmux ls` | List tmux sessions |
| `tmN` | `tmux new-session -s` | Create new tmux session |
| `tmS` | `tmux switch -t` | Switch tmux session |

## Yarn Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `y` | `yarn` | Yarn shortcut |
| `yA` | `yarn add` | Add package |
| `yAd` | `yarn add -D` | Add dev dependency |

## Homebrew Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `brewd` | `brew doctor` | Check system for potential problems |
| `brewi` | `brew install` | Install package |
| `brewI` | `brew info` | Show package info |
| `brewl` | `brew list` | List installed packages |
| `brewL` | `brew leaves` | List installed packages not dependencies |
| `brewo` | `brew outdated` | Show outdated packages |
| `brewr` | `brew reinstall` | Reinstall package |
| `brews` | `brew search` | Search packages |
| `brewS` | `brew services` | Manage brew services |
| `brewu` | `brew update` | Update brew |
| `brewU` | `brew upgrade` | Upgrade packages |
| `brewUp` | `brew update && brew upgrade && brew cleanup` | Full system update |
| `brewx` | `brew uninstall` | Uninstall package |
| `brewX` | `brew uninstall --force` | Force uninstall package |

## Cask Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `caski` | `brew install --cask` | Install cask |
| `caskl` | `brew list --cask` | List installed casks |
| `casko` | `brew outdated --cask` | Show outdated casks |
| `caskr` | `brew reinstall --cask` | Reinstall cask |
| `casks` | `brew search --cask` | Search casks |
| `caskU` | `brew upgrade --cask` | Upgrade casks |
| `caskx` | `brew uninstall --cask` | Uninstall cask |
| `caskX` | `brew uninstall --cask --force` | Force uninstall cask |
| `caskz` | `brew uninstall --cask --zap` | Zap uninstall cask |

## History Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `hisT` | `history | tail` | Show last few commands |
| `hisG` | `history | grep` | Search command history |

## Rails Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `r` | `rails` | Rails shortcut |
| `rc` | `rails console` | Rails console |
| `rDbc` | `rails dbconsole` | Database console |
| `rT` | `rails -T | awk '{print $2}' | fzf --preview 'rails {1} --help' | xargs -I {} rails {}` | Interactive task runner |
| `rdm` | `rails db:migrate` | Run pending migrations |
| `rG` | `rails generate` | Rails generator |
| `rR` | `rails routes` | List all routes |
| `rRg` | `rails routes -g` | Filter routes by grep |
| `rRc` | `rails routes -c` | Filter routes by controller |
| `rs` | `rails server` | Start Rails server |

## File Management Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `tree` | `eza --tree --git --group-directories-first` | Display directory tree |
| `ls` | `eza --icons --group-directories-first` | List files |
| `lsa` | `eza -a --icons --group-directories-first` | List all files |
| `lt` | `eza -T --group-directories-first --icons --git` | Tree view |
| `lta` | `eza -Ta --group-directories-first --icons --git` | Tree view (all files) |
| `ll` | `eza -lmh --group-directories-first --color-scale --icons` | Long list format |
| `la` | `eza -lamhg --group-directories-first --color-scale --icons --git` | Long list all files |
| `laa` | `eza -lamhg@ --group-directories-first --color-scale --icons --git` | Long list with extended attributes |
| `lx` | `eza -lbhHigUmuSa@ --group-directories-first --color-scale --icons --git --time-style=long-iso` | Detailed list |

## Git Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `g` | `git` | Git shortcut |
| `ga` | `git add` | Stage changes |
| `gb` | `git branch` | List branches |
| `gbd` | `git branch -d` | Delete branch |
| `gc` | `git commit` | Commit changes |
| `gcm` | `git commit -m` | Commit with message |
| `gco` | `git checkout` | Checkout |
| `gd` | `git diff` | Show changes |
| `gl` | `git log` | Show commit logs |
| `gp` | `git push` | Push changes |
| `gpf` | `git push --force-with-lease` | Force push (safely) |
| `gpl` | `git pull` | Pull changes |
| `gr` | `git rebase` | Rebase |
| `grbc` | `git rebase --continue` | Continue rebase |
| `gs` | `git status` | Show status |
| `gundo` | `git reset --soft HEAD~1` | Undo last commit |
| `gup` | `git pull --rebase` | Pull with rebase |
| `gupm` | `git pull --rebase origin main` | Pull main with rebase |
| `gwip` | `git add -A; git commit -m 'chore: wip'` | Commit work in progress |

## Utility Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `cat` | `bat` | Enhanced cat with syntax highlighting |
| `fDir` | `fd -H --type d \| fzf \|\| echo .` | Interactive directory search |
| `dutiA` | `duti -v "${XDG_CONFIG_HOME:-$HOME/.config}/duti"` | Set default applications |
| `jason` | `pbpaste -Prefer txt \| jq . \| pbcopy` | Format clipboard JSON |
| `c` | `code .` | Open VS Code in current directory |
| `ci` | `code-insiders` | Open VS Code Insiders |
| `ci.` | `code-insiders .` | Open VS Code Insiders in current directory |

## Overmind Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `oC`, `oc` | `overmind connect` | Connect to Overmind process |
| `oCw`, `ocw` | `overmind connect web` | Connect to web process |
| `oK`, `ok` | `overmind kill` | Kill Overmind processes |
| `oRw` | `overmind restart web` | Restart web process |

## Heroku Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `heroRc` | `heroku run rails c` | Run Rails console on Heroku |
| `heroRC` | `heroku run rails c -a podia -- -- --noautocomplete` | Run Rails console on Heroku (Podia) |

## Bundle Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `b` | `bundle` | Bundle shortcut |
| `be` | `bundle exec` | Execute bundled command |
| `up` | `git pull && bundle check \|\| bundle && yarn && rails db:migrate` | Update project |