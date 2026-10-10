#!/usr/bin/env bash
set -euo pipefail

# Install zshrc to ~/.zshrc on a remote host over SSH. Existing ~/.zshrc is
# backed up to ~/.zshrc.bak (unless it's already a symlink). With --with-aliases,
# also copy my-aliases to ~/.my-aliases.
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

with_aliases=0
host=""
for arg in "$@"; do
  case "$arg" in
    --with-aliases) with_aliases=1 ;;
    -*) echo "unknown option: $arg" >&2; exit 1 ;;
    *)  host="$arg" ;;
  esac
done

if [[ -z "$host" ]]; then
  echo "usage: $0 [--with-aliases] [user@]host" >&2
  exit 1
fi

ssh "$host" '[[ -f ~/.zshrc && ! -L ~/.zshrc ]] && cp ~/.zshrc ~/.zshrc.bak && echo "backed up ~/.zshrc -> ~/.zshrc.bak"' || true
scp "$REPO_DIR/zshrc" "$host:~/.zshrc"
(( with_aliases )) && scp "$REPO_DIR/my-aliases" "$host:~/.my-aliases"

echo "done — run 'source ~/.zshrc' on $host to apply"
