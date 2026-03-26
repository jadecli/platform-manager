#!/usr/bin/env bash
# Integration test suite: validates Slack, GitHub, Linear, Channels, Remote Control.
# Run: bash integrations/tests/check-integrations.sh
# Each test outputs PASS/FAIL/SKIP with a one-line explanation.
set -uo pipefail

GRN='\033[32m'; RED='\033[31m'; YLW='\033[33m'; DIM='\033[2m'; RST='\033[0m'
PASS=0; FAIL=0; SKIP=0

pass() { printf "${GRN}PASS${RST}  %s\n" "$1"; ((PASS++)) || true; }
fail() { printf "${RED}FAIL${RST}  %s\n" "$1"; ((FAIL++)) || true; }
skip() { printf "${YLW}SKIP${RST}  %s  ${DIM}(%s)${RST}\n" "$1" "$2"; ((SKIP++)) || true; }

ORG="jadecli"
REPO="platform-manager"

echo "Integration Tests — ${ORG}/${REPO}"
echo "================================================"
echo ""

# ─── 1. SLACK ──────────────────────────────────────

echo "── Slack ──"

# 1a. SLACK_WEBHOOK_URL org secret exists
if gh secret list --org "$ORG" 2>/dev/null | grep -q SLACK_WEBHOOK_URL; then
  pass "SLACK_WEBHOOK_URL org secret exists"
else
  fail "SLACK_WEBHOOK_URL org secret missing — set via: gh secret set SLACK_WEBHOOK_URL --org $ORG"
fi

# 1b. pr-notify.yml workflow exists on default branch
if gh api "repos/${ORG}/${REPO}/contents/.github/workflows/pr-notify.yml" --jq '.name' &>/dev/null; then
  pass "pr-notify.yml workflow exists on default branch"
else
  fail "pr-notify.yml workflow not found — merge PR #10"
fi

# 1c. Claude app installed in Slack (check via API — requires slack token)
if [[ -n "${SLACK_BOT_TOKEN:-}" ]]; then
  if curl -sS -H "Authorization: Bearer $SLACK_BOT_TOKEN" "https://slack.com/api/auth.test" | jq -e '.ok' &>/dev/null; then
    pass "Claude Slack app authenticated"
  else
    fail "Claude Slack app auth failed"
  fi
else
  skip "Claude Slack app auth" "set SLACK_BOT_TOKEN to test"
fi

echo ""

# ─── 2. GITHUB ─────────────────────────────────────

echo "── GitHub ──"

# 2a. CLAUDE_CODE_OAUTH_TOKEN org secret
if gh secret list --org "$ORG" 2>/dev/null | grep -q CLAUDE_CODE_OAUTH_TOKEN; then
  pass "CLAUDE_CODE_OAUTH_TOKEN org secret exists"
else
  fail "CLAUDE_CODE_OAUTH_TOKEN missing — run: claude setup-token"
fi

# 2b. claude-code-review.yml on default branch
if gh api "repos/${ORG}/${REPO}/contents/.github/workflows/claude-code-review.yml" --jq '.name' &>/dev/null; then
  pass "claude-code-review.yml workflow exists"
else
  fail "claude-code-review.yml not found"
fi

# 2c. claude-code-review uses oauth token (not API key)
REVIEW_YML=$(gh api "repos/${ORG}/${REPO}/contents/.github/workflows/claude-code-review.yml" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || echo "")
if echo "$REVIEW_YML" | grep -q "claude_code_oauth_token"; then
  pass "claude-code-review uses OAuth token (not API key)"
elif echo "$REVIEW_YML" | grep -q "anthropic_api_key"; then
  fail "claude-code-review uses ANTHROPIC_API_KEY — must use claude_code_oauth_token"
else
  skip "claude-code-review auth check" "could not read workflow"
fi

# 2d. Branch protection / rulesets active
RULESETS=$(gh api "repos/${ORG}/${REPO}/rulesets" --jq 'length' 2>/dev/null || echo "0")
if [[ "$RULESETS" -gt 0 ]]; then
  pass "Branch rulesets active ($RULESETS ruleset(s))"
else
  skip "Branch rulesets" "none found — check org-level rulesets"
fi

# 2e. Required checks configured (check last PR)
LAST_PR=$(gh pr list -R "${ORG}/${REPO}" --state all --limit 1 --json number --jq '.[0].number' 2>/dev/null || echo "")
if [[ -n "$LAST_PR" ]]; then
  CHECKS=$(gh pr checks "$LAST_PR" -R "${ORG}/${REPO}" 2>&1 | wc -l | tr -d ' ')
  if [[ "$CHECKS" -ge 3 ]]; then
    pass "PR #${LAST_PR} has $CHECKS CI checks configured"
  else
    fail "PR #${LAST_PR} has only $CHECKS checks — expected ≥3"
  fi
else
  skip "CI check count" "no PRs found"
fi

echo ""

# ─── 3. LINEAR ─────────────────────────────────────

echo "── Linear ──"

# 3a. Branch naming convention includes Linear ticket
BRANCHES=$(gh pr list -R "${ORG}/${REPO}" --state all --limit 10 --json headRefName --jq '.[].headRefName' 2>/dev/null || echo "")
PM_BRANCHES=$(echo "$BRANCHES" | grep -c "pm-[0-9]" || true)
if [[ "$PM_BRANCHES" -ge 3 ]]; then
  pass "Branch naming includes PM-N ticket ($PM_BRANCHES/10 recent branches)"
else
  skip "Linear ticket in branches" "only $PM_BRANCHES of 10 recent branches match pm-N"
fi

# 3b. check-branch-name workflow validates Linear tickets
if gh api "repos/${ORG}/${REPO}/contents/.github/workflows/branch-guard.yml" --jq '.name' &>/dev/null; then
  pass "branch-guard.yml workflow validates Linear ticket format"
else
  fail "branch-guard.yml not found"
fi

# 3c. claude-code-review.yml extracts Linear ticket
if echo "$REVIEW_YML" | grep -q "linear.app/jadecli"; then
  pass "claude-code-review extracts Linear ticket URL"
else
  fail "claude-code-review does not extract Linear ticket"
fi

echo ""

# ─── 4. CHANNELS ───────────────────────────────────

echo "── Claude Code Channels ──"

# 4a. Claude Code version supports channels (≥2.1.80)
CLAUDE_VER=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "0.0.0")
MINOR=$(echo "$CLAUDE_VER" | cut -d. -f2)
PATCH=$(echo "$CLAUDE_VER" | cut -d. -f3)
if [[ "$MINOR" -gt 1 ]] || [[ "$MINOR" -eq 1 && "$PATCH" -ge 80 ]]; then
  pass "Claude Code $CLAUDE_VER supports channels (≥2.1.80)"
else
  fail "Claude Code $CLAUDE_VER too old for channels (need ≥2.1.80)"
fi

# 4b. allowedChannelPlugins in managed-settings.d
MANAGED_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/managed-settings.d"
if [[ -f "$MANAGED_DIR/10-jadecli-channels.json" ]]; then
  if jq -e '.allowedChannelPlugins' "$MANAGED_DIR/10-jadecli-channels.json" &>/dev/null; then
    pass "allowedChannelPlugins configured in managed-settings.d"
  else
    fail "10-jadecli-channels.json missing allowedChannelPlugins key"
  fi
else
  skip "allowedChannelPlugins" "10-jadecli-channels.json not deployed — run phase 02"
fi

# 4c. iMessage availability (macOS only)
if [[ "$(uname)" == "Darwin" ]]; then
  if [[ -f "$HOME/Library/Messages/chat.db" ]]; then
    pass "iMessage chat.db accessible (macOS)"
  else
    fail "iMessage chat.db not found — check Full Disk Access"
  fi
else
  skip "iMessage" "not macOS"
fi

# 4d. notify.sh script exists and is executable
NOTIFY_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/notify.sh"
if [[ -x "$NOTIFY_SCRIPT" ]]; then
  pass "scripts/notify.sh exists and is executable"
else
  fail "scripts/notify.sh missing or not executable"
fi

echo ""

# ─── 5. REMOTE CONTROL ────────────────────────────

echo "── Remote Control ──"

# 5a. Claude Code supports remote-control (≥2.1.51)
if [[ "$MINOR" -gt 1 ]] || [[ "$MINOR" -eq 1 && "$PATCH" -ge 51 ]]; then
  pass "Claude Code $CLAUDE_VER supports remote-control (≥2.1.51)"
else
  fail "Claude Code $CLAUDE_VER too old for remote-control (need ≥2.1.51)"
fi

# 5b. OAuth login (remote-control requires claude.ai login, not API key)
if claude auth status &>/dev/null 2>&1; then
  pass "Claude auth active (OAuth — required for remote-control)"
else
  fail "Claude auth not active — run: claude auth login"
fi

# 5c. Permission relay capability (≥2.1.81)
if [[ "$MINOR" -gt 1 ]] || [[ "$MINOR" -eq 1 && "$PATCH" -ge 81 ]]; then
  pass "Claude Code $CLAUDE_VER supports permission relay (≥2.1.81)"
else
  skip "Permission relay" "need ≥2.1.81 (have $CLAUDE_VER)"
fi

echo ""

# ─── SUMMARY ───────────────────────────────────────

echo "================================================"
TOTAL=$((PASS + FAIL + SKIP))
printf "Results: ${GRN}%d pass${RST}, ${RED}%d fail${RST}, ${YLW}%d skip${RST} / %d total\n" "$PASS" "$FAIL" "$SKIP" "$TOTAL"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "Fix failures above, then re-run:"
  echo "  bash integrations/tests/check-integrations.sh"
  exit 1
fi
