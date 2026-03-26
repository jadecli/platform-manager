#!/usr/bin/env bash
set -euo pipefail

# StopFailure hook — fires when a turn ends due to API error (rate limit, auth, etc.)
# Receives JSON on stdin with session_id, cwd, hook_event_name, error details.

INPUT=$(cat)
LOG="${HOME}/.claude/logs/stop-failure.log"
[[ -d "$(dirname "$LOG")" ]] || mkdir -p "$(dirname "$LOG")"

SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
ERROR=$(echo "$INPUT" | jq -r '.error // .stop_reason // "unknown"')

printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SESSION" "$ERROR" >> "$LOG"

# macOS desktop notification — sanitize ERROR to prevent AppleScript injection
SAFE_ERROR="${ERROR//\"/\'}"
SAFE_ERROR="${SAFE_ERROR//\\/}"
osascript -e "display notification \"Session stopped: ${SAFE_ERROR}\" with title \"Claude Code\" subtitle \"StopFailure\"" 2>/dev/null || true
