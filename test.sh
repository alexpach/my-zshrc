#!/usr/bin/env zsh
# Smoke test for zshrc: launch it in an isolated $HOME and confirm the features
# load — PATH, env, aliases, prompt, hooks, lazy nvm, venv auto-activate.
#
#   ./test.sh
#
# Sets up a throwaway $HOME under ./tmp (symlinking the repo's zshrc + my-aliases
# in), sources zshrc there, then asserts. Exits non-zero if any check fails.
emulate -L zsh
setopt extended_glob

REPO="${0:A:h}"
cd "$REPO"

# 1. Syntax must parse before we bother sourcing.
if zsh -n zshrc; then
  print "  ok  zsh -n zshrc (syntax)"
else
  print "FAIL  zsh -n zshrc (syntax)"; exit 1
fi

# 2. Isolated $HOME so ~/.my-aliases etc. resolve to this repo, not the real home.
mkdir -p tmp
TEST_HOME="$(mktemp -d "$REPO/tmp/home.XXXXXX")"
trap 'command rm -rf "$TEST_HOME"' EXIT
ln -s "$REPO/zshrc"      "$TEST_HOME/.zshrc"
ln -s "$REPO/my-aliases" "$TEST_HOME/.my-aliases"

# Fake nvm node installs to test "newest node bin prepended to PATH".
mkdir -p "$TEST_HOME/.nvm/versions/node/v18.20.0/bin" \
         "$TEST_HOME/.nvm/versions/node/v20.11.0/bin"
NEWEST_NODE_BIN="$TEST_HOME/.nvm/versions/node/v20.11.0/bin"

# Fake project venv to test auto-activate on cd.
mkdir -p "$TEST_HOME/proj/.venv/bin"
print 'export VIRTUAL_ENV="'"$TEST_HOME"'/proj/.venv"; deactivate(){ unset VIRTUAL_ENV; unfunction deactivate }' \
  > "$TEST_HOME/proj/.venv/bin/activate"

# 3. Source zshrc with the isolated HOME (subshell-style: override then source).
export HOME="$TEST_HOME"
export ZDOTDIR="$TEST_HOME"
source "$TEST_HOME/.zshrc"

# Snapshot the hook arrays now, then drop the title hooks. zshrc emits
# terminal-title OSC escapes (\e]0;...\a); a real terminal consumes them as
# title changes, but they show as stray "]0;" if you pipe this output to a file.
# Dropping the hooks stops further ones. Assertions below use the snapshots.
snap_precmd=("${precmd_functions[@]}")
snap_preexec=("${preexec_functions[@]}")
snap_chpwd=("${chpwd_functions[@]}")
snap_zshexit=("${zshexit_functions[@]}")
add-zsh-hook -d precmd  _title_precmd
add-zsh-hook -d preexec _title_preexec

# --- assertions -------------------------------------------------------------
fail=0
chk() { local d=$1; shift
  if eval "$@"; then print "  ok  $d"; else print "FAIL  $d"; (( fail++ )); fi
}

print "\n-- env --"
chk "EDITOR set"                  '[[ -n $EDITOR ]]'
chk "PAGER set"                   '[[ -n $PAGER ]]'
chk "LANG set"                    '[[ -n $LANG ]]'
chk "VIRTUAL_ENV_DISABLE_PROMPT"  '[[ $VIRTUAL_ENV_DISABLE_PROMPT == 1 ]]'

print "\n-- options --"
chk "AUTO_CD"        '[[ -o auto_cd ]]'
chk "INC_APPEND_HISTORY_TIME"  '[[ -o inc_append_history_time && ! -o share_history ]]'
chk "PROMPT_SUBST"   '[[ -o prompt_subst ]]'
chk "CORRECT off"    '[[ ! -o correct ]]'

print "\n-- aliases (base + my-aliases) --"
chk "ls"   'alias ls >/dev/null'
chk "l"    'alias l  >/dev/null'
chk "ll"   'alias ll >/dev/null'
chk "la"   'alias la >/dev/null'
chk "gs"   'alias gs >/dev/null'

print "\n-- functions --"
for f in _zshlex_left _zshlex_accept _zshlex_restore claude \
         nvm node npm npx _venv_auto _title_preexec _farewell; do
  chk "function $f" "(( \$+functions[$f] ))"
done
chk "trash NOT a function (binary wins)" '(( ! $+functions[trash] ))'

print "\n-- prompt --"
chk "PROMPT non-empty"   '[[ -n $PROMPT ]]'
chk "SPROMPT non-empty"  '[[ -n $SPROMPT ]]'

print "\n-- hooks registered --"
chk "precmd: vcs_info"      '(( ${snap_precmd[(I)vcs_info]} ))'
chk "precmd: _title_precmd" '(( ${snap_precmd[(I)_title_precmd]} ))'
chk "preexec: _title_preexec" '(( ${snap_preexec[(I)_title_preexec]} ))'
chk "chpwd: _venv_auto"     '(( ${snap_chpwd[(I)_venv_auto]} ))'
chk "zshexit: _farewell"    '(( ${snap_zshexit[(I)_farewell]} ))'

print "\n-- PATH --"
typeset -a uniq_path=("${(@u)path}")
chk "path is deduped (typeset -gU)" '(( ${#path} == ${#uniq_path} ))'
for d in /usr/local/bin /opt/homebrew/bin; do
  [[ -d $d ]] && chk "$d present" "(( \${path[(I)$d]} ))"
done
chk "newest node bin on PATH"       "(( \${path[(I)$NEWEST_NODE_BIN]} ))"
chk "node bin before /usr/local/bin" \
  '(( ${path[(i)'"$NEWEST_NODE_BIN"']} < ${path[(i)/usr/local/bin]} ))'

print "\n-- venv auto-activate --"
cd "$TEST_HOME/proj"
chk "activates on cd into project" '[[ $VIRTUAL_ENV == "'"$TEST_HOME"'/proj/.venv" ]]'
cd "$REPO"
chk "deactivates on cd out"        '[[ -z $VIRTUAL_ENV ]]'

# --- result -----------------------------------------------------------------
print ""
if (( fail )); then
  print "FAILED: $fail check(s)"; exit 1
else
  print "All checks passed."
fi
