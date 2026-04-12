# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/src/prezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/src/prezto/init.zsh"
fi

# add stuff to path
export PATH="$HOME/.local/bin:$HOME/.lmstudio/bin:$PATH"

# Homebrew prefs
export HOMEBREW_NO_ENV_HINTS=1

# zoxide (cd replacement)
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# fzf fuzzy search
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# aliases
[ -f ~/.my-aliases ] && source ~/.my-aliases

# private config (managed by chezmoi, not in git)
[ -f ~/.my-private ] && source ~/.my-private

# Node Version Manager - lazy load
export NVM_DIR="$HOME/.nvm"

_load_nvm() {
 unset -f nvm node npm npx _load_nvm
 [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
 [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

nvm()  { _load_nvm; nvm  "$@"; }
node() { _load_nvm; node "$@"; }
npm()  { _load_nvm; npm  "$@"; }
npx()  { _load_nvm; npx  "$@"; }
