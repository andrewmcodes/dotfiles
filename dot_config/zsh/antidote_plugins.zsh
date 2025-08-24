fpath+=( $HOME/.cache/repos/mattmc3/ez-compinit )
source $HOME/.cache/repos/mattmc3/ez-compinit/ez-compinit.plugin.zsh
fpath+=( $HOME/.cache/repos/zsh-users/zsh-completions/src )
fpath+=( $HOME/.cache/repos/aloxaf/fzf-tab )
source $HOME/.cache/repos/aloxaf/fzf-tab/fzf-tab.plugin.zsh
fpath+=( $HOME/.cache/repos/MichaelAquilina/zsh-you-should-use )
source $HOME/.cache/repos/MichaelAquilina/zsh-you-should-use/zsh-you-should-use.plugin.zsh
fpath+=( $HOME/.cache/repos/belak/zsh-utils/completion/functions )
builtin autoload -Uz $fpath[-1]/*(N.:t)
compstyle_zshzoo_setup
fpath+=( $HOME/.cache/repos/belak/zsh-utils/editor )
source $HOME/.cache/repos/belak/zsh-utils/editor/editor.plugin.zsh
fpath+=( $HOME/.cache/repos/belak/zsh-utils/history )
source $HOME/.cache/repos/belak/zsh-utils/history/history.plugin.zsh
if is-macos; then
  fpath+=( $HOME/.cache/repos/zshzoo/macos )
  source $HOME/.cache/repos/zshzoo/macos/macos.plugin.zsh
fi
fpath+=( $HOME/.cache/repos/belak/zsh-utils/utility )
source $HOME/.cache/repos/belak/zsh-utils/utility/utility.plugin.zsh
export PATH="$HOME/.cache/repos/romkatv/zsh-bench:$PATH"
fpath+=( $HOME/.cache/repos/ohmyzsh/ohmyzsh/plugins/extract )
source $HOME/.cache/repos/ohmyzsh/ohmyzsh/plugins/extract/extract.plugin.zsh
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $HOME/.cache/repos/romkatv/zsh-defer )
  source $HOME/.cache/repos/romkatv/zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $HOME/.cache/repos/zdharma-continuum/fast-syntax-highlighting )
zsh-defer source $HOME/.cache/repos/zdharma-continuum/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fpath+=( $HOME/.cache/repos/zsh-users/zsh-autosuggestions )
source $HOME/.cache/repos/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
fpath+=( $HOME/.cache/repos/zsh-users/zsh-history-substring-search )
source $HOME/.cache/repos/zsh-users/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
