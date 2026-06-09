# ~/.zshrc — single self-contained config, no external dependencies.
# Optional tools (zoxide, fzf, nvm, fortune) are detected and silently skipped.

# PATH
typeset -gU path
path=(
  $HOME/{,s}bin(N)
  $HOME/.local/bin(N)
  $HOME/.lmstudio/bin(N)
  /opt/{homebrew,local}/{,s}bin(N)
  /usr/local/{,s}bin(N)
  $path
)

# Environment
[[ -z "$EDITOR" ]]   && export EDITOR='vim'
[[ -z "$VISUAL" ]]   && export VISUAL='vim'
[[ -z "$PAGER" ]]    && export PAGER='less'
[[ -z "$LANG" ]]     && export LANG='en_US.UTF-8'
[[ -z "$LESS" ]]     && export LESS='-g -i -M -R -S -w -X -z-4'
[[ "$OSTYPE" == darwin* && -z "$BROWSER" ]] && export BROWSER='open'
export HOMEBREW_NO_ENV_HINTS=1

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt BANG_HIST EXTENDED_HISTORY SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS HIST_IGNORE_SPACE HIST_SAVE_NO_DUPS HIST_VERIFY

# Directory
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

# Completion: full compinit (with security audit) at most once a day,
# otherwise trust the existing dump (-C); compile the dump in the background.
() {
  setopt LOCAL_OPTIONS EXTENDED_GLOB
  autoload -Uz compinit
  local dump="${ZDOTDIR:-$HOME}/.zcompdump"
  if [[ -n $dump(#qN.mh-24) ]]; then
    compinit -C -d "$dump"
  else
    compinit -d "$dump"
  fi
  { [[ -s "$dump" && (! -s "$dump.zwc" || "$dump" -nt "$dump.zwc") ]] && zcompile "$dump" } &!
}
setopt COMPLETE_IN_WORD ALWAYS_TO_END PATH_DIRS AUTO_MENU

# Colors and hooks
autoload -Uz colors && colors
autoload -Uz add-zsh-hook

# Key bindings (emacs)
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search   # up arrow
bindkey '^[[B' down-line-or-beginning-search # down arrow
bindkey '^[OA' up-line-or-beginning-search   # up arrow (alt)
bindkey '^[OB' down-line-or-beginning-search # down arrow (alt)

# ls colors — base alias; my-aliases builds l/ll/la/etc. on top of it
if [[ "$OSTYPE" == darwin* ]]; then
  export CLICOLOR=1
  alias ls='ls -Fv'
else
  alias ls='ls --color=auto -Fv'
fi

# Prompt: user@host path (git branch) [exit code] %
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %F{green}%b%f'
add-zsh-hook precmd vcs_info
setopt PROMPT_SUBST
PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f${vcs_info_msg_0_}%(?.. %F{red}%?%f) %# '

# Terminal title
_title_precmd()  { print -Pn '\e]0;%n@%m: %~\a' }
_title_preexec() { print -n "\e]0;${(V)1}\a" }
add-zsh-hook precmd  _title_precmd
add-zsh-hook preexec _title_preexec

# aliases
[ -f ~/.my-aliases ] && source ~/.my-aliases

# private config (managed by chezmoi, not in git)
[ -f ~/.my-private ] && source ~/.my-private

# zoxide (cd replacement)
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# fzf fuzzy search
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# NVM - lazy load
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

# Greeting (login shells only)
if [[ -o LOGIN && -o INTERACTIVE && -t 2 ]] && (( $+commands[fortune] )); then
  { fortune -s; print } >&2
fi

# Farewell (login shells only)
_farewell() {
  [[ -o LOGIN && -o INTERACTIVE && -t 2 ]] || return 0
  local sayings=(
    "So long and thanks for all the fish.\n  -- Douglas Adams"
    "Good morning! And in case I don't see ya, good afternoon, good evening and goodnight.\n  -- Truman Burbank"
  )
  print -- "$sayings[RANDOM % $#sayings + 1]" >&2
}
add-zsh-hook zshexit _farewell
