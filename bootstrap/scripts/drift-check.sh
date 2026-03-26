#!/usr/bin/env bash
# drift-check.sh — compare bootstrap/claude-config/ against live ~/.claude/
# Reports only differences. Never modifies files.
#
# Usage:
#   bash bootstrap/scripts/drift-check.sh
#   bash bootstrap/scripts/drift-check.sh --identity ~/.claude-jade
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_SRC="$REPO_ROOT/bootstrap/claude-config"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --identity) CLAUDE_DIR="$2"; shift 2 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

# Colors (auto-detect TTY)
if [[ -t 1 ]]; then
  RED='\033[31m'; YLW='\033[33m'; GRN='\033[32m'; DIM='\033[2m'; RST='\033[0m'
else
  RED=''; YLW=''; GRN=''; DIM=''; RST=''
fi

DIFFS=0; MISSING=0

check_file() {
  local src="$1" dst="$2" label="$3"
  if [[ ! -f "$dst" ]]; then
    printf "${RED}MISS${RST}  %s\n" "$label"; ((MISSING++)) || true
  elif [[ -L "$dst" ]]; then
    printf "${DIM}LINK${RST}  %s  (still symlinked — re-run phase 07)\n" "$label"; ((DIFFS++)) || true
  elif ! diff -q "$src" "$dst" &>/dev/null; then
    printf "${YLW}DIFF${RST}  %s\n" "$label"; ((DIFFS++)) || true
  fi
}

check_dir() {
  local src="$1" dst="$2" prefix="$3"
  if [[ ! -d "$dst" ]]; then
    printf "${RED}MISS${RST}  %s/ (entire dir)\n" "$prefix"; ((MISSING++)) || true; return
  fi
  if [[ -L "$dst" ]]; then
    printf "${DIM}LINK${RST}  %s/  (still symlinked — re-run phase 07)\n" "$prefix"; ((DIFFS++)) || true; return
  fi
  while IFS= read -r -d '' src_file; do
    local rel="${src_file#$src/}"
    check_file "$src_file" "$dst/$rel" "$prefix/$rel"
  done < <(find "$src" -type f -print0 2>/dev/null | sort -z)
}

echo "Drift: $CONFIG_SRC → $CLAUDE_DIR"

for f in CLAUDE.md settings.json settings.local.json keybindings.json statusline-command.sh shell-helpers.sh; do
  [[ -f "$CONFIG_SRC/$f" ]] && check_file "$CONFIG_SRC/$f" "$CLAUDE_DIR/$f" "$f"
done

for d in hooks commands rules agents output-styles skills; do
  [[ -d "$CONFIG_SRC/$d" ]] && check_dir "$CONFIG_SRC/$d" "$CLAUDE_DIR/$d" "$d"
done

DESKTOP_SRC="$CONFIG_SRC/claude-desktop/claude_desktop_config.json"
DESKTOP_DST="$HOME/.config/claude-desktop/claude_desktop_config.json"
[[ -f "$DESKTOP_SRC" ]] && check_file "$DESKTOP_SRC" "$DESKTOP_DST" "claude-desktop/claude_desktop_config.json"

TOTAL=$((DIFFS + MISSING))
if [[ $TOTAL -eq 0 ]]; then
  printf "${GRN}OK${RST}  No drift.\n"; exit 0
else
  printf "${YLW}%d diff(s)${RST}, ${RED}%d missing${RST}\n" "$DIFFS" "$MISSING"
  echo "Redeploy: bash bootstrap/install.sh --phase 07"
  exit 1
fi
