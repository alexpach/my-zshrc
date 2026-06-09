#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Link dotfiles
FILES=(zshrc my-aliases)

for f in "${FILES[@]}"; do
  src="$REPO_DIR/$f"
  dst="$HOME/.$f"

  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "ok: $dst"
  elif [[ -L "$dst" ]]; then
    echo "relinking: $dst"
    ln -sf "$src" "$dst"
  elif [[ -e "$dst" ]]; then
    bak="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    echo "backing up: $dst -> $bak"
    mv "$dst" "$bak"
    ln -s "$src" "$dst"
  else
    echo "linking: $dst"
    ln -s "$src" "$dst"
  fi
done

# Remove symlinks left over from the old Prezto-based setup
for f in zprofile zpreztorc zshenv zlogin zlogout; do
  dst="$HOME/.$f"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$REPO_DIR/$f" ]]; then
    echo "removing stale link: $dst"
    rm "$dst"
  fi
done

# Apply private config via chezmoi
if command -v chezmoi &>/dev/null; then
  echo "Applying private config via chezmoi..."
  chezmoi apply
else
  echo "chezmoi not installed — skipping private config"
  echo "  Install:  brew install chezmoi"
  echo "  Init:     chezmoi init"
  echo "  Add file: chezmoi add ~/.my-private"
fi
