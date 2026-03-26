# Integrations

Five systems connected through the jadecli Slack workspace.

## Architecture

```
┌─────────────┐    PR events     ┌───────────────┐
│   GitHub     │────────────────→│  Slack #pm     │
│  Actions     │  pr-notify.yml  │  (jadecli)     │
└──────┬───────┘                 └───────┬────────┘
       │                                 │
       │ claude-review                   │ @Claude
       ▼                                 ▼
┌─────────────┐                 ┌───────────────┐
│ Claude Code  │   channels/     │ Claude Code   │
│  Action      │   remote-ctrl   │  on the web   │
│ (CI review)  │◄──────────────→│ (from Slack)  │
└──────┬───────┘                 └───────────────┘
       │
       │ notify.sh
       ▼
┌─────────────┐
│  iMessage /  │
│  macOS notif │
└─────────────┘
```

## 1. Claude in Slack

@Claude in `#platform-manager` routes coding tasks to Claude Code on the web.

**Setup**: Slack App Marketplace → Claude → `/invite @Claude` in channel.
**Routing**: Code + Chat mode (auto-detects coding vs general questions).

## 2. GitHub → Slack

PR lifecycle events fire notifications via `pr-notify.yml`.

| Event | Notification |
|-------|-------------|
| PR created | `:rocket: PR #N created` |
| PR approved | `:white_check_mark: Approved — needs merge` |
| Checks pass/fail | `:green_circle:/:red_circle: Checks status` |
| Claude review done | `:brain: Review complete` |

**Setup**: `gh secret set SLACK_WEBHOOK_URL --org jadecli`

Also: `/github subscribe jadecli/platform-manager reviews comments pulls issues commits:all`

## 3. Linear → Slack

Issue updates sync to `#platform-manager`.

**Setup**: Linear app in Slack → connect jadecli workspace → select channel.
**Branch naming**: `<type>/pm-<N>-desc` — `branch-guard.yml` validates ticket format.
**Claude review**: Extracts `PM-N` from branch name, links to Linear URL.

## 4. Claude Code Channels

MCP servers that push events INTO a running Claude Code session.

| Channel | Platform | Use case |
|---------|----------|----------|
| iMessage | macOS | Agent → human notification |
| Telegram | Cross-platform | Two-way chat + permission relay |
| Discord | Cross-platform | Two-way chat + permission relay |
| Custom webhook | Any | GitHub/CI events → session |

**Permission relay** (v2.1.81+): approve/deny tool calls from your phone.
Reply `yes <id>` or `no <id>` to the channel message.

**Managed settings**: `allowedChannelPlugins` in `managed-settings.d/10-jadecli-channels.json`.

## 5. Remote Control

Control a local Claude Code session from claude.ai/code or the Claude mobile app.

```bash
claude remote-control --name "platform-manager"
```

Your filesystem, MCP servers, and tools stay local. Only messages route through Anthropic API.
Requires OAuth login (not API keys). v2.1.51+.

## Validation

```bash
bash integrations/tests/check-integrations.sh
```

Tests 15+ integration points across all 5 systems.
