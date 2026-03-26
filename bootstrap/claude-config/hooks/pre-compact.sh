#!/usr/bin/env bash
set -euo pipefail

# PreCompact hook — fires before context compaction.
# Logs the event so you can correlate context resets with session activity.

INPUT=$(cat)
LOG="${HOME}/.claude/logs/compaction.log"
[[ -d "$(dirname "$LOG")" ]] || mkdir -p "$(dirname "$LOG")"

SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TRIGGER=$(echo "$INPUT" | jq -r '.matcher // "unknown"')

printf '%s\tpre-compact\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$TRIGGER" "$SESSION" >> "$LOG"
