#!/usr/bin/env bash
# Create a secondary Claude config dir with copies of shared config.
# Auth credentials and session history stay separate per identity.
#
# Why: CLAUDE_CONFIG_DIR replaces the ENTIRE ~/.claude/ path.
# Without shared config, the secondary identity has no hooks, settings,
# commands, rules, or statusline.
#
# Usage: bash multi-identity-setup.sh [config-name]
# Example: bash multi-identity-setup.sh .claude-jade
set -euo pipefail

CONFIG_NAME="${1:-.claude-jade}"
PRIMARY="$HOME/.claude"
SECONDARY="$HOME/$CONFIG_NAME"

[[ -d "$PRIMARY" ]] || { echo "error: $PRIMARY not found. Run phase 07 first." >&2; exit 1; }

# Preserve auth + session state before rebuild
PRESERVE_TMP="/tmp/claude-identity-$$"
mkdir -p "$PRESERVE_TMP"
if [[ -d "$SECONDARY" ]]; then
  for keep in sessions credentials.json .credentials.json .claude.json; do
    [[ -e "$SECONDARY/$keep" && ! -L "$SECONDARY/$keep" ]] && \
      /bin/cp -R "$SECONDARY/$keep" "$PRESERVE_TMP/" 2>/dev/null || true
  done
  /bin/rm -rf "$SECONDARY"
fi

mkdir -p "$SECONDARY"

# Restore preserved items
for keep in sessions credentials.json .credentials.json .claude.json; do
  [[ -e "$PRESERVE_TMP/$keep" ]] && /bin/cp -R "$PRESERVE_TMP/$keep" "$SECONDARY/" 2>/dev/null || true
done
/bin/rm -rf "$PRESERVE_TMP"

# Copy shared config (not symlinks — fully independent)
SHARED_FILES=(CLAUDE.md settings.json settings.local.json keybindings.json statusline-command.sh shell-helpers.sh)
SHARED_DIRS=(agents commands hooks output-styles rules skills)

COPIED=0
for f in "${SHARED_FILES[@]}"; do
  [[ -f "$PRIMARY/$f" ]] && { /bin/cp "$PRIMARY/$f" "$SECONDARY/$f"; ((COPIED++)); }
done
for d in "${SHARED_DIRS[@]}"; do
  [[ -d "$PRIMARY/$d" ]] && { /bin/cp -R "$PRIMARY/$d" "$SECONDARY/$d"; ((COPIED++)); }
done

echo "Created $SECONDARY ($COPIED items copied from $PRIMARY)"
echo "Next: CLAUDE_CONFIG_DIR=$SECONDARY claude auth login"
