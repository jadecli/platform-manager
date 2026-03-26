#!/usr/bin/env bash
# Phase 02: Install Claude Code CLI + plugins + managed settings.
set -euo pipefail

CLAUDE_VER=$(jq -r '.runtime."claude-cli"' "$VERSIONS")

# --- Claude Code CLI (native installer, NOT npm — npm path is deprecated) ---
CURRENT_CLAUDE=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "none")
if [[ "$CURRENT_CLAUDE" != "$CLAUDE_VER" ]]; then
  echo "Installing Claude Code CLI $CLAUDE_VER via native installer..."
  $DRY_RUN || curl -fsSL https://claude.ai/install.sh | bash -s "$CLAUDE_VER"
  # Migrate from npm if still installed
  if npm list -g @anthropic-ai/claude-code &>/dev/null 2>&1; then
    echo "  Removing deprecated npm install..."
    $DRY_RUN || npm uninstall -g @anthropic-ai/claude-code
  fi
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
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "env": {
    "CLAUDE_CODE_SUBPROCESS_ENV_SCRUB": "1",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "DISABLE_AUTOUPDATER": "1"
  },
  "sandbox": {
    "failIfUnavailable": true
  }
}
POLICY

# Linux: install sandbox deps
if [[ "$PLATFORM" == "linux" ]]; then
  if ! command -v bwrap &>/dev/null; then
    echo "  Installing sandbox deps (bubblewrap + socat)..."
    $DRY_RUN || sudo apt-get install -y -qq bubblewrap socat
  fi
fi

echo "  Claude: $(claude --version 2>/dev/null || echo 'not installed')"
echo "  Config: ${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
echo "  Managed settings: $MANAGED_DIR"
