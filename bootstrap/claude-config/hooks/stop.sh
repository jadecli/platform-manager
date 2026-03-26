#!/usr/bin/env bash
set -euo pipefail

# Stop hook — fires every time Claude finishes a turn successfully.
# Logs turn completions for audit and cost tracking.

INPUT=$(cat)
LOG="${HOME}/.claude/logs/stop.log"
[[ -d "$(dirname "$LOG")" ]] || mkdir -p "$(dirname "$LOG")"

IFS=$'\t' read -r SESSION CWD <<< \
  "$(echo "$INPUT" | jq -r '[.session_id // "unknown", .cwd // ""] | join("\t")')"

printf '%s\tStop\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SESSION" "$CWD" >> "$LOG"
