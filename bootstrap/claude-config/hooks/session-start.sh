#!/usr/bin/env bash
set -euo pipefail

# SessionStart hook — fires when a new session begins.
# Uses $CLAUDE_ENV_FILE to inject persistent env vars for the session.

INPUT=$(cat)
LOG="${HOME}/.claude/logs/session-lifecycle.log"
[[ -d "$(dirname "$LOG")" ]] || mkdir -p "$(dirname "$LOG")"

SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

printf '%s\tSessionStart\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SESSION" "$CWD" >> "$LOG"

# Inject session-scoped env vars via CLAUDE_ENV_FILE
# These persist across all bash commands in the session
if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
  {
    # Ensure common tool paths are available
    echo 'export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"'
    # Homebrew (macOS Apple Silicon)
    [[ -x /opt/homebrew/bin/brew ]] && echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
    # mise — use shims PATH (simpler than full activation, avoids bash/zsh mismatch)
    [[ -x /opt/homebrew/bin/mise ]] && echo 'export PATH="${HOME}/.local/share/mise/shims:${PATH}"'
    # fnm (fast node manager — fallback if mise not handling node)
    [[ -x /opt/homebrew/bin/fnm ]] && echo 'eval "$(fnm env 2>/dev/null)"'
  } >> "$CLAUDE_ENV_FILE"

  # Activate python venv if present in project
  if [[ -f "${CWD}/.venv/bin/activate" ]]; then
    echo "source '${CWD}/.venv/bin/activate'" >> "$CLAUDE_ENV_FILE"
  fi
  echo "export SESSION_START_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$CLAUDE_ENV_FILE"
fi

# Drift check: once per day, compare ~/.claude/ against repo source of truth
DRIFT_STAMP="${HOME}/.claude/.drift-check-last"
DRIFT_SCRIPT="${HOME}/platform-manager/bootstrap/scripts/drift-check.sh"
if [[ -f "$DRIFT_SCRIPT" ]]; then
  TODAY=$(date +%Y-%m-%d)
  LAST=$(cat "$DRIFT_STAMP" 2>/dev/null || echo "")
  if [[ "$LAST" != "$TODAY" ]]; then
    echo "$TODAY" > "$DRIFT_STAMP"
    bash "$DRIFT_SCRIPT" 2>/dev/null | grep -E '^(DIFF|MISS|LINK)' || true
  fi
fi
