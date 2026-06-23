#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  cat <<EOF
Usage: $0 [--with-aliases] [user@]host

Installs zshrc-portable to ~/.zshrc on a remote host via SSH.
An existing ~/.zshrc is backed up to ~/.zshrc.bak.

Options:
  --with-aliases  Also install my-aliases to ~/.my-aliases
EOF
  exit 1
}

WITH_ALIASES=0
HOST=""

for arg in "$@"; do
  case "$arg" in
    --with-aliases) WITH_ALIASES=1 ;;
    -*)             echo "Unknown option: $arg"; usage ;;
    *)              HOST="$arg" ;;
  esac
done

[[ -z "$HOST" ]] && usage

echo "Installing portable zshrc to ${HOST}..."

# Back up existing ~/.zshrc on remote (skip if it's already a symlink)
ssh "$HOST" '
  if [[ -f ~/.zshrc && ! -L ~/.zshrc ]]; then
    cp ~/.zshrc ~/.zshrc.bak
    echo "backed up: ~/.zshrc -> ~/.zshrc.bak"
  fi
'

scp "$REPO_DIR/zshrc-portable" "${HOST}:~/.zshrc"
echo "installed: ~/.zshrc"

if [[ $WITH_ALIASES -eq 1 ]]; then
  scp "$REPO_DIR/my-aliases" "${HOST}:~/.my-aliases"
  echo "installed: ~/.my-aliases"
fi

echo "Done. Run 'source ~/.zshrc' on ${HOST} to apply."
