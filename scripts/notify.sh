#!/usr/bin/env bash
# notify.sh — send notifications via iMessage (macOS) or Slack webhook.
# Used by Claude agents and hooks when human attention is needed.
#
# Usage:
#   bash scripts/notify.sh "PR #7 approved — ready to merge"
#   bash scripts/notify.sh --channel slack "CI passed on feat/pm-40"
#   bash scripts/notify.sh --channel imessage "Agent needs approval for deploy"
set -euo pipefail

CHANNEL="${JADECLI_NOTIFY_CHANNEL:-imessage}"
RECIPIENT="${JADECLI_NOTIFY_RECIPIENT:-zhouk.alex@gmail.com}"
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"
MESSAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --channel) CHANNEL="$2"; shift 2 ;;
    --to) RECIPIENT="$2"; shift 2 ;;
    *) MESSAGE="$MESSAGE $1"; shift ;;
  esac
done

MESSAGE="${MESSAGE# }"
[[ -z "$MESSAGE" ]] && { echo "Usage: notify.sh [--channel imessage|slack] <message>" >&2; exit 1; }

case "$CHANNEL" in
  imessage)
    if [[ "$(uname)" != "Darwin" ]]; then
      echo "iMessage requires macOS" >&2; exit 1
    fi
    osascript -e "tell application \"Messages\"
      set targetService to 1st account whose service type = iMessage
      set targetBuddy to participant \"$RECIPIENT\" of targetService
      send \"[jadecli] $MESSAGE\" to targetBuddy
    end tell" 2>/dev/null && echo "Sent via iMessage to $RECIPIENT" || {
      # Fallback: terminal-notifier or osascript notification
      osascript -e "display notification \"$MESSAGE\" with title \"jadecli\" sound name \"Glass\"" 2>/dev/null
      echo "Sent via macOS notification"
    }
    ;;

  slack)
    if [[ -z "$SLACK_WEBHOOK" ]]; then
      echo "Set SLACK_WEBHOOK_URL or secrets.SLACK_WEBHOOK_URL" >&2; exit 1
    fi
    curl -sS -X POST "$SLACK_WEBHOOK" \
      -H 'Content-Type: application/json' \
      -d "{\"text\": \"$MESSAGE\"}"
    echo "Sent via Slack"
    ;;

  both)
    "$0" --channel imessage "$MESSAGE" 2>/dev/null || true
    "$0" --channel slack "$MESSAGE" 2>/dev/null || true
    ;;

  *)
    echo "Unknown channel: $CHANNEL (use imessage, slack, or both)" >&2; exit 1
    ;;
esac
