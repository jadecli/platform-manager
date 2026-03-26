#!/usr/bin/env bash
set -euo pipefail

# WorktreeCreate / WorktreeRemove hook
# Receives JSON on stdin: { session_id, cwd, hook_event_name, name?, worktree_path? }
# Exit 0 = proceed, exit 2 = block (stderr fed back to Claude)

INPUT=$(cat)
IFS=$'\t' read -r EVENT SESSION CWD NAME WT_PATH <<< \
  "$(echo "$INPUT" | jq -r '[.hook_event_name // "unknown", .session_id // "", .cwd // "", .name // "", .worktree_path // ""] | join("\t")')"

LOG="${HOME}/.claude/logs/worktree-lifecycle.log"
[[ -d "$(dirname "$LOG")" ]] || mkdir -p "$(dirname "$LOG")"

case "$EVENT" in
  WorktreeCreate)
    printf '%s\tCreate\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$NAME" "$CWD" "$SESSION" >> "$LOG"
    ;;
  WorktreeRemove)
    printf '%s\tRemove\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$WT_PATH" "$CWD" "$SESSION" >> "$LOG"
    ;;
esac
