#!/usr/bin/env bash
# Phase 02: Install Claude Code CLI + plugins + managed settings.
set -euo pipefail

CLAUDE_VER=$(jq -r '.runtime."claude-cli"' "$VERSIONS")

# --- Claude Code CLI ---
CURRENT_CLAUDE=$(claude --version 2>/dev/null || echo "none")
if [[ "$CURRENT_CLAUDE" != *"$CLAUDE_VER"* ]]; then
  echo "Installing Claude Code CLI $CLAUDE_VER..."
  $DRY_RUN || npm install -g "@anthropic-ai/claude-code@$CLAUDE_VER"
fi

# --- Auth check ---
if ! claude auth status &>/dev/null 2>&1; then
  echo ""
  echo "  Claude Code requires authentication."
  echo "  Run: claude auth login"
  echo "  Then re-run this phase: bash bootstrap/install.sh --phase 02"
  echo ""
fi

# --- Security: scrub subprocess credentials (2.1.83+) ---
# This prevents hooks, MCP servers, and Bash tools from seeing API tokens
if [[ -z "${CLAUDE_CODE_SUBPROCESS_ENV_SCRUB:-}" ]]; then
  echo "  Recommend: export CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1"
fi

# --- Plugins ---
# Plugins are enabled via settings.json, not CLI install.
# The global settings.json should have enabledPlugins configured.
# Verify the expected plugins are available:
EXPECTED_PLUGINS=(
  "document-skills@anthropic-agent-skills"
  "example-skills@anthropic-agent-skills"
  "neon-postgres@neon"
  "pyright-lsp@claude-plugins-official"
  "netlify-skills@netlify-context-and-tools"
)

echo "  Plugins (configured via ~/.claude/settings.json):"
for plugin in "${EXPECTED_PLUGINS[@]}"; do
  echo "    - $plugin"
done

# --- managed-settings.d (2.1.83+) ---
# Team policy fragments. Each file merges alphabetically.
MANAGED_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/managed-settings.d"
if [[ ! -d "$MANAGED_DIR" ]]; then
  echo "  Creating managed-settings.d/ for team policy..."
  $DRY_RUN || mkdir -p "$MANAGED_DIR"
fi

# Deploy jadecli team policy
$DRY_RUN || cat > "$MANAGED_DIR/00-jadecli-security.json" << 'POLICY'
{
  "env": {
    "CLAUDE_CODE_SUBPROCESS_ENV_SCRUB": "1"
  }
}
POLICY

echo "  Claude: $(claude --version 2>/dev/null || echo 'not installed')"
echo "  Config: ${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
echo "  Managed settings: $MANAGED_DIR"
