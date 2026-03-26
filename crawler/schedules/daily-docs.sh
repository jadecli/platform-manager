#!/usr/bin/env bash
set -euo pipefail

# Daily crawl of code.claude.com/docs — run via cron or jcli scheduler.
# Detects changes to CLI docs and appends to changelog.
#
# Schedule: 0 8 * * * bash /Users/alexzh/platform-manager/crawler/schedules/daily-docs.sh
# Or via jcli: jcli create task "daily docs crawl" --assign ghostty

cd /Users/alexzh/platform-manager

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Starting daily docs crawl"

python -m crawler.run docs 2>&1

# Count changes
changes=$(tail -1 crawler/indexes/changelog.jsonl 2>/dev/null | jq -r '.crawled_at // ""')
if [[ -n "$changes" ]]; then
  new_count=$(grep "$(date -u +%Y-%m-%d)" crawler/indexes/changelog.jsonl 2>/dev/null | wc -l)
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Done. ${new_count} changes detected today."
else
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Done. No changes."
fi
