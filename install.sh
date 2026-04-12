#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check Prezto
if [[ ! -f "$HOME/src/prezto/init.zsh" ]]; then
  echo "Prezto not found at ~/src/prezto"
  printf "Clone it now? [y/N] " && read yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/src/prezto"
  else
    echo "Skipping. Use zshrc-portable for a standalone config."
    exit 1
  fi
fi
echo "ok: Prezto found at ~/src/prezto"

# Link dotfiles
FILES=(zshrc zprofile zpreztorc zshenv zlogin zlogout)

for f in "${FILES[@]}"; do
  src="$REPO_DIR/$f"
  dst="$HOME/.$f"

  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "ok: $dst"
  elif [[ -L "$dst" ]]; then
    echo "relinking: $dst"
    ln -sf "$src" "$dst"
  elif [[ -e "$dst" ]]; then
    echo "backing up: $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
    ln -s "$src" "$dst"
  else
    echo "linking: $dst"
    ln -s "$src" "$dst"
  fi
done
