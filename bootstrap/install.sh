#!/usr/bin/env bash
# Bootstrap: deterministic environment setup for jadecli ecosystem.
# Usage: bash bootstrap/install.sh [--platform darwin|linux] [--dry-run] [--phase N]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSIONS="$REPO_ROOT/versions.json"

# --- Defaults ---
PLATFORM="${BOOTSTRAP_PLATFORM:-}"
DRY_RUN=false
PHASE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform) PLATFORM="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=true; shift ;;
    --phase)    PHASE="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

# --- Detect platform ---
if [[ -z "$PLATFORM" ]]; then
  case "$(uname -s)" in
    Darwin) PLATFORM="darwin" ;;
    Linux)  PLATFORM="linux" ;;
    *) echo "Unsupported OS: $(uname -s)"; exit 1 ;;
  esac
fi

ARCH="$(uname -m)"
[[ "$ARCH" == "aarch64" ]] && ARCH="arm64"

# --- Colors ---
GRN='\033[32m'; YLW='\033[33m'; RED='\033[31m'; DIM='\033[2m'; RST='\033[0m'
log()  { printf "${GRN}[✓]${RST} %s\n" "$*"; }
warn() { printf "${YLW}[!]${RST} %s\n" "$*"; }
err()  { printf "${RED}[✗]${RST} %s\n" "$*"; }
dry()  { if $DRY_RUN; then printf "${DIM}[dry] %s${RST}\n" "$*"; return 0; fi; eval "$@"; }

# --- Read versions.json ---
if ! command -v jq &>/dev/null; then
  err "jq required. Install: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

ver() { jq -r "$1" "$VERSIONS"; }

log "Bootstrap: platform=$PLATFORM arch=$ARCH dry_run=$DRY_RUN"
log "Versions pinned: $(ver '.pinned')"
echo ""

# --- Run phases ---
run_phase() {
  local num="$1" name="$2"
  if [[ -n "$PHASE" && "$PHASE" != "$num" ]]; then return 0; fi
  local script="$SCRIPT_DIR/phases/${num}-${name}.sh"
  if [[ -f "$script" ]]; then
    log "Phase $num: $name"
    PLATFORM="$PLATFORM" ARCH="$ARCH" DRY_RUN="$DRY_RUN" \
    REPO_ROOT="$REPO_ROOT" VERSIONS="$VERSIONS" \
    bash "$script"
    echo ""
  else
    warn "Phase $num: $name — script not found, skipping"
  fi
}

run_phase 01 runtime
run_phase 02 claude
run_phase 03 lsp
run_phase 04 git
run_phase 05 shell
run_phase 06 validate
run_phase 07 claude-config

log "Bootstrap complete."
