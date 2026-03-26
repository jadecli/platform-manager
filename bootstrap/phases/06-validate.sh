#!/usr/bin/env bash
# Phase 06: Validate all installed versions match versions.json.
set -uo pipefail

PASS=0
FAIL=0
SKIP=0

check() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$actual" == "none" || -z "$actual" ]]; then
    printf "  %-30s ${YLW:-}SKIP${RST:-} (not installed)\n" "$name"
    ((SKIP++))
  elif [[ "$actual" == "$expected" ]]; then
    printf "  %-30s ${GRN:-}PASS${RST:-} %s\n" "$name" "$actual"
    ((PASS++))
  else
    printf "  %-30s ${RED:-}FAIL${RST:-} expected=%s actual=%s\n" "$name" "$expected" "$actual"
    ((FAIL++))
  fi
}

GRN='\033[32m'; YLW='\033[33m'; RED='\033[31m'; RST='\033[0m'

echo "  Validating against $VERSIONS"
echo ""

# Runtimes
check "claude-cli" \
  "$(jq -r '.runtime."claude-cli"' "$VERSIONS")" \
  "$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo none)"

check "node" \
  "$(jq -r '.runtime.node' "$VERSIONS")" \
  "$(node --version 2>/dev/null | tr -d 'v' || echo none)"

check "python" \
  "$(jq -r '.runtime.python' "$VERSIONS")" \
  "$(python3 --version 2>/dev/null | awk '{print $2}' || echo none)"

check "rustc" \
  "$(jq -r '.runtime.rustc' "$VERSIONS")" \
  "$(rustc --version 2>/dev/null | awk '{print $2}' || echo none)"

check "uv" \
  "$(jq -r '.runtime.uv' "$VERSIONS")" \
  "$(uv --version 2>/dev/null | awk '{print $2}' || echo none)"

# LSPs
check "typescript-language-server" \
  "$(jq -r '.lsp."typescript-language-server"' "$VERSIONS")" \
  "$(npm list -g typescript-language-server 2>/dev/null | grep 'typescript-language-server@' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo none)"

check "pyright" \
  "$(jq -r '.lsp.pyright' "$VERSIONS")" \
  "$(uv tool list 2>/dev/null | grep '^pyright ' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo none)"

check "bash-language-server" \
  "$(jq -r '.lsp."bash-language-server"' "$VERSIONS")" \
  "$(npm list -g bash-language-server 2>/dev/null | grep 'bash-language-server@' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo none)"

check "yaml-language-server" \
  "$(jq -r '.lsp."yaml-language-server"' "$VERSIONS")" \
  "$(npm list -g yaml-language-server 2>/dev/null | grep 'yaml-language-server@' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo none)"

echo ""
echo "  Results: ${PASS} pass, ${FAIL} fail, ${SKIP} skip"

if [[ $FAIL -gt 0 ]]; then
  echo "  Run: bash bootstrap/install.sh to fix mismatches"
  exit 1
fi
