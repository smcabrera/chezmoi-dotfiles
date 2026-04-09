#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEZMOI_DIR="$HOME/.local/share/chezmoi"

echo "Setting up chezmoi symlink..."

# Check if chezmoi dir exists and is not already a symlink to this repo
if [ -e "$CHEZMOI_DIR" ] || [ -L "$CHEZMOI_DIR" ]; then
  if [ -L "$CHEZMOI_DIR" ]; then
    current_target=$(readlink "$CHEZMOI_DIR")
    if [ "$current_target" = "$REPO_DIR" ]; then
      echo "✓ Symlink already correctly configured"
      exit 0
    fi
  fi
  echo "Removing existing chezmoi directory at $CHEZMOI_DIR"
  rm -rf "$CHEZMOI_DIR"
fi

# Create symlink
mkdir -p "$(dirname "$CHEZMOI_DIR")"
ln -s "$REPO_DIR" "$CHEZMOI_DIR"

echo "✓ Symlink created: $CHEZMOI_DIR -> $REPO_DIR"
echo "✓ Chezmoi source path: $(chezmoi source-path)"
