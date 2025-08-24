fpath+=( $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-mattmc3-SLASH-ez-compinit )
source $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-mattmc3-SLASH-ez-compinit/ez-compinit.plugin.zsh
fpath+=( $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-completions/src )
fpath+=( $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-aloxaf-SLASH-fzf-tab )
source $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-aloxaf-SLASH-fzf-tab/fzf-tab.plugin.zsh
fpath+=( $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-belak-SLASH-zsh-utils/completion/functions )
builtin autoload -Uz $fpath[-1]/*(N.:t)
compstyle_zshzoo_setup
fpath+=( $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-belak-SLASH-zsh-utils/editor )
source $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-belak-SLASH-zsh-utils/editor/editor.plugin.zsh
fpath+=( $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-belak-SLASH-zsh-utils/history )
source $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-belak-SLASH-zsh-utils/history/history.plugin.zsh
fpath+=( $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-powerlevel10k )
source $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-powerlevel10k/powerlevel10k.zsh-theme
source $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-powerlevel10k/powerlevel9k.zsh-theme
if is-macos; then
  fpath+=( $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zshzoo-SLASH-macos )
  source $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zshzoo-SLASH-macos/macos.plugin.zsh
fi
fpath+=( $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-belak-SLASH-zsh-utils/utility )
source $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-belak-SLASH-zsh-utils/utility/utility.plugin.zsh
export PATH="$HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-bench:$PATH"
fpath+=( $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/extract )
source $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/extract/extract.plugin.zsh
fpath+=( $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting )
source $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fpath+=( $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions )
source $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
fpath+=( $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search )
source $HOME/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
