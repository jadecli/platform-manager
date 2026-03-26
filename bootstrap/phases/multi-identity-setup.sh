#!/usr/bin/env bash
# Setup a secondary Claude config dir with shared config but separate auth.
# Usage: bash multi-identity-setup.sh <config-dir-name>
# Example: bash multi-identity-setup.sh .claude-jade
set -euo pipefail

CONFIG_NAME="${1:-.claude-jade}"
PRIMARY="$HOME/.claude"
SECONDARY="$HOME/$CONFIG_NAME"

if [[ ! -d "$PRIMARY" ]]; then
  echo "Primary Claude config not found at $PRIMARY" >&2
  exit 1
fi

mkdir -p "$SECONDARY"

# Shared config — symlinked (same settings, hooks, commands, etc.)
SHARED=(
  agents CLAUDE.md commands hooks keybindings.json output-styles
  plugins projects rules settings.json settings.local.json
  shell-helpers.sh skills statusline-command.sh tasks teams
)

for item in "${SHARED[@]}"; do
  src="$PRIMARY/$item"
  dst="$SECONDARY/$item"
  if [[ -e "$src" ]]; then
    # Remove existing file/dir and replace with symlink
    /bin/rm -rf "$dst"
    ln -s "$src" "$dst"
  fi
done

# Per-identity (NOT symlinked — separate per user):
# - credentials (managed by `claude auth login`)
# - sessions/ (separate session history)
# - mcp-needs-auth-cache.json
# - .claude.json (session metadata)
# - history.jsonl (separate command history)

echo "Secondary config at $SECONDARY"
echo "Shared: ${#SHARED[@]} items symlinked from $PRIMARY"
echo ""
echo "Next: CLAUDE_CONFIG_DIR=$SECONDARY claude auth login"
