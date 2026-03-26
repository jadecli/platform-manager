#!/usr/bin/env bash
# Phase 03: Install language servers from versions.json.
set -euo pipefail

# Read LSP versions
TS_LSP=$(jq -r '.lsp."typescript-language-server"' "$VERSIONS")
PYRIGHT=$(jq -r '.lsp.pyright' "$VERSIONS")
BASH_LSP=$(jq -r '.lsp."bash-language-server"' "$VERSIONS")
YAML_LSP=$(jq -r '.lsp."yaml-language-server"' "$VERSIONS")
TAPLO=$(jq -r '.lsp.taplo' "$VERSIONS")
GOPLS=$(jq -r '.lsp.gopls' "$VERSIONS")
LUA_LSP=$(jq -r '.lsp."lua-language-server"' "$VERSIONS")

# --- npm-based LSPs ---
install_npm_lsp() {
  local name="$1" pkg="$2" ver="$3"
  local current
  current=$(npm list -g "$pkg" 2>/dev/null | grep "$pkg@" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "none")
  if [[ "$current" != "$ver" ]]; then
    echo "  Installing $name@$ver (current: $current)..."
    $DRY_RUN || npm install -g "${pkg}@${ver}"
  else
    echo "  $name@$ver ✓"
  fi
}

install_npm_lsp "typescript-language-server" "typescript-language-server" "$TS_LSP"
install_npm_lsp "bash-language-server" "bash-language-server" "$BASH_LSP"
install_npm_lsp "yaml-language-server" "yaml-language-server" "$YAML_LSP"

# --- uv-based LSPs ---
install_uv_lsp() {
  local name="$1" pkg="$2" ver="$3"
  local current
  current=$(uv tool list 2>/dev/null | grep "^$pkg " | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "none")
  if [[ "$current" != "$ver" ]]; then
    echo "  Installing $name@$ver via uv (current: $current)..."
    $DRY_RUN || uv tool install "${pkg}==${ver}"
  else
    echo "  $name@$ver ✓"
  fi
}

install_uv_lsp "pyright" "pyright" "$PYRIGHT"

# --- Rust-based LSPs ---
# rust-analyzer comes with rustup
echo "  rust-analyzer: via rustup component"
$DRY_RUN || rustup component add rust-analyzer 2>/dev/null

# taplo (TOML LSP) via cargo
CURRENT_TAPLO=$(taplo --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "none")
if [[ "$CURRENT_TAPLO" != "$TAPLO" ]]; then
  echo "  Installing taplo@$TAPLO via cargo..."
  $DRY_RUN || cargo install "taplo-cli@$TAPLO"
else
  echo "  taplo@$TAPLO ✓"
fi

# --- Go LSP (gopls) ---
if command -v go &>/dev/null; then
  CURRENT_GOPLS=$(gopls version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "none")
  if [[ "$CURRENT_GOPLS" != "$GOPLS" ]]; then
    echo "  Installing gopls@$GOPLS..."
    $DRY_RUN || go install "golang.org/x/tools/gopls@v${GOPLS}"
  else
    echo "  gopls@$GOPLS ✓"
  fi
else
  echo "  gopls: skipped (Go not installed)"
fi

# --- Lua LSP ---
if [[ "$PLATFORM" == "darwin" ]]; then
  brew list lua-language-server &>/dev/null || {
    echo "  Installing lua-language-server via brew..."
    $DRY_RUN || brew install lua-language-server
  }
else
  echo "  lua-language-server: install manually on Linux"
fi

# --- TypeScript compiler (for typecheck) ---
TS_VER=$(npm list -g typescript 2>/dev/null | grep "typescript@" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "none")
echo "  typescript@$TS_VER (for typecheck)"
