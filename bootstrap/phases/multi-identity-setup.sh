#!/usr/bin/env bash
# Create a secondary Claude config dir that shares config with ~/.claude/.
# Only auth credentials and session history stay separate.
#
# Why: CLAUDE_CONFIG_DIR replaces the ENTIRE ~/.claude/ path.
# Without shared symlinks, the secondary identity has no hooks, settings,
# commands, rules, plugins, or statusline.
#
# Usage: bash multi-identity-setup.sh [config-name]
# Example: bash multi-identity-setup.sh .claude-jade
set -euo pipefail

CONFIG_NAME="${1:-.claude-jade}"
PRIMARY="$HOME/.claude"
SECONDARY="$HOME/$CONFIG_NAME"

[[ -d "$PRIMARY" ]] || { echo "error: $PRIMARY not found" >&2; exit 1; }

# Nuke and rebuild — avoids stale files from previous runs
if [[ -d "$SECONDARY" ]]; then
  # Preserve auth credentials and session history
  for keep in sessions; do
    [[ -d "$SECONDARY/$keep" && ! -L "$SECONDARY/$keep" ]] && \
      /bin/mv "$SECONDARY/$keep" "/tmp/claude-keep-$keep-$$" 2>/dev/null || true
  done
  /bin/rm -rf "$SECONDARY"
fi

mkdir -p "$SECONDARY"

# Restore preserved dirs
for keep in sessions; do
  [[ -d "/tmp/claude-keep-$keep-$$" ]] && \
    /bin/mv "/tmp/claude-keep-$keep-$$" "$SECONDARY/$keep" 2>/dev/null || true
done

# Symlink shared config
SHARED=(agents CLAUDE.md commands hooks keybindings.json output-styles
  plugins projects rules settings.json settings.local.json
  shell-helpers.sh skills statusline-command.sh tasks teams)

for item in "${SHARED[@]}"; do
  [[ -e "$PRIMARY/$item" ]] && ln -s "$PRIMARY/$item" "$SECONDARY/$item"
done

echo "Created $SECONDARY (${#SHARED[@]} symlinks → $PRIMARY)"
echo "Next: CLAUDE_CONFIG_DIR=$SECONDARY claude auth login"
