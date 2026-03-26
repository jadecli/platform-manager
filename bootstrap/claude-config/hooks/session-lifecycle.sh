#!/usr/bin/env bash
set -euo pipefail

# SessionEnd hook — fires when a session ends or switches via /resume.
# Logs session end events for tracking usage patterns.

INPUT=$(cat)
LOG="${HOME}/.claude/logs/session-lifecycle.log"
[[ -d "$(dirname "$LOG")" ]] || mkdir -p "$(dirname "$LOG")"

SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

printf '%s\tSessionEnd\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SESSION" "$CWD" >> "$LOG"
