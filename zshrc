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
# Prompt glyphs ($'\uXXXX') die with "character not in range" unless the
# *effective* locale is UTF-8; LANG may be unset, or set to a locale this box
# never generated. `locale charmap` reports what the libc actually resolved.
() {
  [[ ${(U)$(locale charmap 2>/dev/null)} == *UTF*8* ]] && return
  local l
  for l in C.UTF-8 en_US.UTF-8; do
    if [[ ${(U)$(LC_ALL=$l locale charmap 2>/dev/null)} == *UTF*8* ]]; then
      export LC_ALL=$l LANG=$l
      print -ru2 "zshrc: locale was not UTF-8; using $l for this session."
      print -ru2 "zshrc: fix this host (Debian/Ubuntu): sudo locale-gen en_US.UTF-8 && sudo update-locale LANG=en_US.UTF-8, then re-login."
      return
    fi
  done
  print -ru2 "zshrc: no UTF-8 locale available; prompt glyphs will be broken."
  print -ru2 "zshrc: fix this host: install locales (Debian/Ubuntu: sudo apt-get install locales && sudo locale-gen en_US.UTF-8), then re-login."
}
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
# INC_APPEND_HISTORY_TIME (not SHARE_HISTORY): every window writes to the file
# right away, but arrow-up only walks this window's own commands.
setopt BANG_HIST EXTENDED_HISTORY INC_APPEND_HISTORY_TIME
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS HIST_IGNORE_SPACE HIST_SAVE_NO_DUPS HIST_VERIFY

# Directory
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

# Completion: full compinit (with security audit) at most once a day,
# otherwise trust the existing dump (-C); compile the dump in the background.
() {
  setopt LOCAL_OPTIONS EXTENDED_GLOB
  fpath=($HOME/.docker/completions(N) $fpath)   # Docker Desktop CLI completions
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
  [[ -n $(git ls-files --others --exclude-standard --directory 2>/dev/null | head -1) ]] && hook_com[unstaged]+=' %F{cyan}?'
}

# Glyphs (Nerd Font).
_zshlex_lcap=$'\ue0b6'; _zshlex_rcap=$'\ue0b4'   # rounded pill caps
_zshlex_lsep=$'\ue0b1'                            # thin separator >
_zshlex_py=$'\ue73c'                                # python
_zshlex_bg=236; _zshlex_sep=244; _zshlex_fg=252   # 256-color palette

# Host-specific icon, matched on short hostname. Add cases as needed.
case "${HOST%%.*}" in
  aMac5)      _zshlex_host=$'\ueea7' ;;   # laptop
  aMac1)      _zshlex_host=$'\uef89' ;;   # swiss laptop
  aMac27)     _zshlex_host=$'\uf015' ;;   # home
  hive-alex)  _zshlex_host=$'\udb85\ude9e' ;;  # beehive
  hive*)      _zshlex_host=$'\uf10ce' ;;  # beehive
  *)          _zshlex_host='%m' ;;        # fallback: hostname text  (f08c0)
esac

# Left pill, rebuilt each render so git/venv/resize reflow.
_zshlex_left() {
  local out="%F{$_zshlex_bg}${_zshlex_lcap}%K{$_zshlex_bg} %F{blue}${_zshlex_host} %F{$_zshlex_sep}${_zshlex_lsep} %F{$_zshlex_fg}%n@%m %F{$_zshlex_sep}${_zshlex_lsep} %F{cyan}%~"
  [[ -n "$vcs_info_msg_0_" ]] && out+=" %F{$_zshlex_sep}${_zshlex_lsep} %F{green}${vcs_info_msg_0_}"
  if [[ -n "$VIRTUAL_ENV" ]]; then
    local venv="${VIRTUAL_ENV:t}"
    case "$venv" in .venv|venv|env|.env) venv="${VIRTUAL_ENV:h:t}" ;; esac
    out+=" %F{$_zshlex_sep}${_zshlex_lsep} %F{yellow}${_zshlex_py} ${venv}"
  fi
  out+=" %k%F{$_zshlex_bg}${_zshlex_rcap}%f"
  print -rn -- "$out"
}

add-zsh-hook precmd vcs_info
PROMPT='$(_zshlex_left)'$'\n'' ❯ '

# Transient prompt: on accept, repaint the line as plain text so scrollback
# (and anything copied from it) reads alex@host:~/dir ❯ cmd — no glyphs.
# Ctrl-C'd lines skip accept-line and keep the pill; cosmetic, ignore.
_zshlex_accept() {
  PROMPT='%F{$_zshlex_fg}%n@%m%f:%F{cyan}%~%f ❯ '
  zle reset-prompt
  zle .accept-line
}
zle -N accept-line _zshlex_accept
_zshlex_restore() { PROMPT='$(_zshlex_left)'$'\n'' ❯ ' }
add-zsh-hook precmd _zshlex_restore
SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Terminal title
#   idle            -> user@host: cwd
#   running a cmd   -> the command line
#   running codex   -> "[codex] <folder>"  (codex sets no title of its own, so
#                      this sticks and stays identifiable in the iTerm tab list)
# claude sets its own "✳ <name>" title and overwrites anything we emit; it's
# fed the folder via the claude() wrapper below (--name), giving "✳ <folder>".
# Add other no-title TUIs to the case as needed.
_title_set() { print -rn -- $'\e]0;'"$1"$'\a' }
_title_precmd()  { print -Pn '\e]0;%n@%m: %~\a' }
_title_preexec() {
  local cmd="${(V)1}" first="${${(V)1}%%[[:space:]]*}"
  case "${first:t}" in
    codex) _title_set "[codex] ${PWD:t}" ;;
    *)     _title_set "$cmd" ;;
  esac
}
add-zsh-hook precmd  _title_precmd
add-zsh-hook preexec _title_preexec

# claude-code: name the session after its project folder so the tab reads
# "✳ <folder>". Skip if you pass your own --name. Want literal "[claude] …"
# instead? change the injected value to "[claude] ${PWD:t}" (claude keeps the ✳).
claude() {
  if [[ "$*" == *--name* ]]; then command claude "$@"
  else command claude --name "${PWD:t}" "$@"; fi
}

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

# Put the newest installed node's bin on PATH up front, so globally-installed
# CLIs (npm i -g …) resolve in a fresh shell without sourcing nvm.sh. Once nvm
# loads (or after `nvm use`), it prepends the active version ahead of this.
# ponytail: tracks newest installed, not the `default` alias (which may be
# lts/*); switch to honoring the alias only if you pin default to an older node.
# (Nn[-1]) yields nothing when no node is installed, so the prepend is a no-op.
path=( $NVM_DIR/versions/node/*/bin(Nn[-1]) $path )

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

# Indigo HQ managed toolchain
export PATH="$HOME/Library/Application Support/Indigo HQ/toolchain/node/bin:$HOME/Library/Application Support/Indigo HQ/toolchain/npm-global/bin:$HOME/Library/Application Support/Indigo HQ/toolchain/git-shim:$HOME/.local/bin:$PATH"
