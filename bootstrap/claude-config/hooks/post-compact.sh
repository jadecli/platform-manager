#!/usr/bin/env bash
set -euo pipefail

# PostCompact hook — fires after context compaction completes.
# Useful for awareness that context was trimmed.

INPUT=$(cat)
LOG="${HOME}/.claude/logs/compaction.log"
[[ -d "$(dirname "$LOG")" ]] || mkdir -p "$(dirname "$LOG")"

SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

printf '%s\tcompacted\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SESSION" >> "$LOG"

# Subtle notification — tput bell as a terminal alert
printf '\a' 2>/dev/null || true
