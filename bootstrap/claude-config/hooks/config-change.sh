#!/usr/bin/env bash
set -euo pipefail

# ConfigChange hook — audits settings file changes mid-session.

INPUT=$(cat)
LOG="${HOME}/.claude/logs/config-audit.log"
[[ -d "$(dirname "$LOG")" ]] || mkdir -p "$(dirname "$LOG")"

IFS=$'\t' read -r SOURCE FILE_PATH <<< \
  "$(echo "$INPUT" | jq -r '[.source // "unknown", .file_path // "unknown"] | join("\t")')"

printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SOURCE" "$FILE_PATH" >> "$LOG"
