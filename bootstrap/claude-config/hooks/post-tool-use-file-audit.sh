#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook (matcher: Edit|Write) — logs all file mutations for audit.

INPUT=$(cat)
LOG="${HOME}/.claude/logs/file-mutations.log"
[[ -d "$(dirname "$LOG")" ]] || mkdir -p "$(dirname "$LOG")"

IFS=$'\t' read -r SESSION TOOL FILE <<< \
  "$(echo "$INPUT" | jq -r '[.session_id // "unknown", .tool_name // "unknown", .tool_input.file_path // ""] | join("\t")')"

[[ -z "$FILE" ]] && exit 0

printf '%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$TOOL" "$FILE" "$SESSION" >> "$LOG"
