#!/usr/bin/env bash
# Phase 07: Deploy ~/.claude/ config from repo source of truth.
# Symlinks repo files into ~/.claude/ so edits go to git, not loose files.
set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CONFIG_SRC="$REPO_ROOT/bootstrap/claude-config"

[[ -d "$CONFIG_SRC" ]] || { echo "error: $CONFIG_SRC not found" >&2; exit 1; }

mkdir -p "$CLAUDE_DIR"

link_file() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    /bin/rm "$dst"
  elif [[ -e "$dst" ]]; then
    /bin/mv "$dst" "${dst}.bak" 2>/dev/null || true
  fi
  $DRY_RUN || ln -s "$src" "$dst"
  echo "  $(basename "$dst")"
}

link_dir() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    /bin/rm "$dst"
  elif [[ -d "$dst" ]]; then
    /bin/rm -rf "${dst}.bak" 2>/dev/null || true
    /bin/mv "$dst" "${dst}.bak" 2>/dev/null || true
  fi
  $DRY_RUN || ln -s "$src" "$dst"
  echo "  $(basename "$dst")/"
}

echo "  Deploying config from $CONFIG_SRC → $CLAUDE_DIR"

# Top-level files
for f in CLAUDE.md settings.json settings.local.json keybindings.json statusline-command.sh shell-helpers.sh; do
  [[ -f "$CONFIG_SRC/$f" ]] && link_file "$CONFIG_SRC/$f" "$CLAUDE_DIR/$f"
done

# Directories
for d in hooks commands rules agents output-styles skills; do
  [[ -d "$CONFIG_SRC/$d" ]] && link_dir "$CONFIG_SRC/$d" "$CLAUDE_DIR/$d"
done

echo "  Done: ~/.claude/ config symlinked to repo"
