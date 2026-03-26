#!/usr/bin/env bash
# Phase 07: Deploy ~/.claude/ config from repo source of truth.
# Copies repo files into ~/.claude/ — one-time deploy, not symlinks.
# To check for drift later: bash bootstrap/scripts/drift-check.sh
set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CONFIG_SRC="$REPO_ROOT/bootstrap/claude-config"

[[ -d "$CONFIG_SRC" ]] || { echo "error: $CONFIG_SRC not found" >&2; exit 1; }

mkdir -p "$CLAUDE_DIR"

copy_file() {
  local src="$1" dst="$2"
  $DRY_RUN || {
    [[ -L "$dst" ]] && /bin/rm "$dst"
    if [[ -f "$dst" ]] && ! diff -q "$src" "$dst" &>/dev/null; then
      /bin/cp "$dst" "${dst}.bak"
    fi
    /bin/cp "$src" "$dst"
  }
  echo "  $(basename "$dst")"
}

copy_dir() {
  local src="$1" dst="$2"
  $DRY_RUN || {
    [[ -L "$dst" ]] && /bin/rm "$dst"
    mkdir -p "$dst"
    /bin/cp -R "$src/." "$dst/"
  }
  echo "  $(basename "$dst")/"
}

echo "  Deploying config from $CONFIG_SRC → $CLAUDE_DIR"

# Top-level files
for f in CLAUDE.md settings.json settings.local.json keybindings.json statusline-command.sh shell-helpers.sh; do
  [[ -f "$CONFIG_SRC/$f" ]] && copy_file "$CONFIG_SRC/$f" "$CLAUDE_DIR/$f"
done

# Directories — merge into existing dir (preserves user-added files)
for d in hooks commands rules agents output-styles skills; do
  [[ -d "$CONFIG_SRC/$d" ]] && copy_dir "$CONFIG_SRC/$d" "$CLAUDE_DIR/$d"
done

# Claude Desktop config
DESKTOP_SRC="$CONFIG_SRC/claude-desktop/claude_desktop_config.json"
DESKTOP_DIR="$HOME/.config/claude-desktop"
if [[ -f "$DESKTOP_SRC" ]]; then
  mkdir -p "$DESKTOP_DIR"
  copy_file "$DESKTOP_SRC" "$DESKTOP_DIR/claude_desktop_config.json"
  echo "  claude-desktop config"
fi

echo "  Done: config deployed from repo"
echo "  Drift check: bash bootstrap/scripts/drift-check.sh"
