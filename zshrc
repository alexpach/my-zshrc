# ~/.zshrc — single self-contained config, no external dependencies.
# Optional tools (zoxide, fzf, nvm, fortune) are detected and silently skipped.

# PATH
typeset -gU path
path=(
  $HOME/{,s}bin(N)
  $HOME/.local/bin(N)
  $HOME/.lmstudio/bin(N)
  /opt/homebrew/opt/llvm/bin(N)
  /opt/homebrew/opt/flex/bin(N)
  /opt/homebrew/opt/bison/bin(N)
  /opt/homebrew/opt/trash/bin(N)
  /opt/homebrew/share/google-cloud-sdk/bin(N)
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

# Build flags for keg-only flex/bison (only when present). Both -L paths must be
# in one LDFLAGS — a second `export LDFLAGS=` would clobber the first.
[[ -d /opt/homebrew/opt/flex ]] && export CPPFLAGS="-I/opt/homebrew/opt/flex/include${CPPFLAGS:+ $CPPFLAGS}"
() {
  local f
  for f in flex bison; do [[ -d /opt/homebrew/opt/$f ]] && LDFLAGS="-L/opt/homebrew/opt/$f/lib${LDFLAGS:+ $LDFLAGS}"; done
  [[ -n $LDFLAGS ]] && export LDFLAGS
}

# Let the prompt render the venv segment; suppress the activate script's "(name) ".
export VIRTUAL_ENV_DISABLE_PROMPT=1

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
unsetopt CORRECT   # no "did you mean...?" command autocorrection

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

# Prompt: zshlex — segmented powerline prompt, ported from the Prezto theme to
# native vcs_info so it needs no framework. Requires a Nerd Font for the glyphs.
#   left:  pill[ hosticon > pwd > gitbranch+status > venv ]
#   right: pill[ exit ✓/✘ > user@host > clock ]   (right-aligned, hidden if narrow)
setopt PROMPT_SUBST

# git branch + status glyphs via vcs_info (replaces Prezto git-info).
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr   ' %F{green}✚'
zstyle ':vcs_info:git:*' unstagedstr ' %F{yellow}✱'
zstyle ':vcs_info:git:*' formats       '%b%u%c'
zstyle ':vcs_info:git:*' actionformats '%b %F{red}⁝ %a%u%c'
# append " ?" when there are untracked files (vcs_info has no native flag for it).
zstyle ':vcs_info:git*+set-message:*' hooks untracked
+vi-untracked() {
  [[ -n $(git ls-files --others --exclude-standard 2>/dev/null | head -1) ]] && hook_com[unstaged]+=' %F{cyan}?'
}

# Strip ANSI/OSC escapes so ${#...} reflects on-screen width (for right-align).
_zshlex_visible_width() {
  setopt local_options extended_glob
  local s="${(e%)1}"
  s="${s//$'\e'\[[0-9;]##[A-Za-z]/}"
  s="${s//$'\e'\][0-9]##\;*$'\a'/}"
  print -r -- ${#s}
}

# Glyphs (Nerd Font).
_zshlex_lcap=$'\ue0b6'; _zshlex_rcap=$'\ue0b4'   # rounded pill caps
_zshlex_lsep=$'\ue0b1'                            # thin separator >
_zshlex_rsep=$'\ue0b3'                            # thin separator <
_zshlex_clock=$'\uf017'                          # clock
_zshlex_py=$'\ue73c'                                # python
_zshlex_bg=236; _zshlex_sep=244; _zshlex_fg=252   # 256-color palette

# Host-specific icon, matched on short hostname. Add cases as needed.
case "${HOST%%.*}" in
  aMac5)  _zshlex_host=$'\ueea7' ;;   # laptop
  aMac27) _zshlex_host=$'\uf015' ;;   # home
  hive*)  _zshlex_host=$'\UF0B46' ;;  # beehive
  *)      _zshlex_host='%m' ;;        # fallback: hostname text
esac

# Left pill, rebuilt each render so git/venv/resize reflow.
_zshlex_left() {
  local out="%F{$_zshlex_bg}${_zshlex_lcap}%K{$_zshlex_bg} %F{blue}${_zshlex_host} %F{$_zshlex_sep}${_zshlex_lsep} %F{cyan}%~"
  [[ -n "$vcs_info_msg_0_" ]] && out+=" %F{$_zshlex_sep}${_zshlex_lsep} %F{green}${vcs_info_msg_0_}"
  if [[ -n "$VIRTUAL_ENV" ]]; then
    local venv="${VIRTUAL_ENV:t}"
    case "$venv" in .venv|venv|env|.env) venv="${VIRTUAL_ENV:h:t}" ;; esac
    out+=" %F{$_zshlex_sep}${_zshlex_lsep} %F{yellow}${_zshlex_py} ${venv}"
  fi
  out+=" %k%F{$_zshlex_bg}${_zshlex_rcap}%f"
  print -rn -- "$out"
}

# Right pill, right-aligned; hidden when the line is too narrow.
_zshlex_right() {
  local rpill="%F{$_zshlex_bg}${_zshlex_lcap}%K{$_zshlex_bg} %(?.%F{green}✓.%F{red}✘) %F{$_zshlex_sep}${_zshlex_rsep} %F{$_zshlex_fg}%n@%m %F{$_zshlex_sep}${_zshlex_rsep} %F{$_zshlex_fg}%D{%H:%M:%S} ${_zshlex_clock} %k%F{$_zshlex_bg}${_zshlex_rcap}%f"
  local pad=$(( COLUMNS - $(_zshlex_visible_width "$(_zshlex_left)") - $(_zshlex_visible_width "$rpill") ))
  (( pad < 2 )) && return
  printf '%*s' $pad ''
  print -rn -- "$rpill"
}

add-zsh-hook precmd vcs_info
TRAPWINCH() { zle && zle reset-prompt }   # force redraw on resize
PROMPT='$(_zshlex_left)$(_zshlex_right)'$'\n'' ❯ '
SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

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

# iTerm2 shell integration
[ -e ~/.iterm2_shell_integration.zsh ] && source ~/.iterm2_shell_integration.zsh

# Auto-activate a project's .venv on cd (works with uv, python -m venv, etc.).
# Walks up from $PWD for .venv/bin/activate; deactivates on leaving the tree.
# ponytail: deactivates any active venv when you cd out, even a manually-sourced
# one — fine for auto-managed project venvs; unset the hook if you hand-manage.
_venv_auto() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    case "$PWD/" in
      "${VIRTUAL_ENV:h}/"*) return ;;                       # still inside project → keep
      *) (( $+functions[deactivate] )) && deactivate ;;     # left it → drop
    esac
  fi
  local d="$PWD"
  while [[ "$d" != / ]]; do
    [[ -f "$d/.venv/bin/activate" ]] && { source "$d/.venv/bin/activate"; return }
    d="${d:h}"
  done
}
add-zsh-hook chpwd _venv_auto
_venv_auto   # run once for the directory the shell starts in

# Drop any stray `trash` shell function so the trash binary on PATH wins.
(( $+functions[trash] )) && unfunction trash

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
