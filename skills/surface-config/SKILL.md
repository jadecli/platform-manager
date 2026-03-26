---
name: surface-config
description: >
  Configure Claude Code statusline and session-start hooks for the jadecli 5-terminal
  ecosystem. Use when setting up a new surface, reconfiguring identity routing, fixing
  statusline display, updating hooks after manifest changes, or onboarding a new user.
  Also use when the user mentions statusline, surface setup, identity badge, session hooks,
  or JADECLI_* env vars.
---

# surface-config

Generates per-surface `.claude/settings.json`, statusline script, and session-start hook
from `manifest.xml`. All 5 surfaces share one macOS device (`/Users/alexzh`).

## Source of Truth

```
/Users/alexzh/jadecli-ecosystem/manifest.xml
```

Parse `<members>/<member>` elements. Each member has:
- `login` attr → `JADECLI_EMAIL`
- `role` attr → `JADECLI_ROLE`
- `<subscription>` → `JADECLI_TIER` (shorten: "Claude Pro Max ($200/mo)" → "Pro Max", "Claude Pro ($20/mo) + Premium team seat" → "Pro + Premium", "TBD" → "TBD")
- `<directory>` → surface subdir name
- `<surface platform="..." app="..."/>` → `JADECLI_PLATFORM`, `JADECLI_SURFACE`

## Surface Map

| Dir | Email | Platform | App | Tier |
|-----|-------|----------|-----|------|
| ghostty | alex@jadecli.com | cli | Ghostty | Pro Max |
| iterm2 | jade@jadecli.com | cli | iTerm2 | Pro Max |
| toad | zhouk.alex@gmail.com | cli | Toad | Pro + Premium |
| vscode | roger@jadecli.com | vscode | VS Code | TBD |
| cursor | robin@jadecli.com | vscode | Cursor | TBD |

## Generated Files

### 1. Per-surface settings: `{surface}/.claude/settings.json`

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "env": {
    "JADECLI_EMAIL": "<login>",
    "JADECLI_PLATFORM": "<platform>",
    "JADECLI_SURFACE": "<app>",
    "JADECLI_TIER": "<tier>",
    "JADECLI_ROLE": "<role>"
  },
  "statusLine": {
    "type": "command",
    "command": "bash /Users/alexzh/jadecli-ecosystem/scripts/statusline.sh"
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash /Users/alexzh/jadecli-ecosystem/scripts/access-guard.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash /Users/alexzh/jadecli-ecosystem/scripts/session-init.sh"
          }
        ]
      }
    ]
  }
}
```

### 2. Statusline script: `scripts/statusline.sh`

Reads stdin JSON from Claude Code, prepends identity badge (email, surface, tier in color),
then delegates to `~/.claude/statusline-command.sh` for model/context/cost/git display.

Format: `email · surface · tier │ <global statusline>`

### 3. Session-init script: `scripts/session-init.sh`

Reads CWD from stdin JSON, emits XML:

```xml
<surface-context>
  <identity>{JADECLI_EMAIL}</identity>
  <platform>{JADECLI_PLATFORM}</platform>
  <surface>{JADECLI_SURFACE}</surface>
  <tier>{JADECLI_TIER}</tier>
  <role>{JADECLI_ROLE}</role>
  <path>{CWD}</path>
  <device>darwin/arm64</device>
  <manifest>/Users/alexzh/jadecli-ecosystem/manifest.xml</manifest>
  <context>/Users/alexzh/jadecli-ecosystem/shared/context/session-start.xml</context>
  <jcli>/Users/alexzh/jadecli-ecosystem/scripts/jcli.sh</jcli>
</surface-context>
```

## Configure All Surfaces

Run the bundled script to regenerate all 5 settings from manifest.xml:

```bash
bash /Users/alexzh/platform-manager/skills/surface-config/scripts/configure.sh
```

This parses manifest.xml and writes each `{surface}/.claude/settings.json`.
To configure a single surface: `bash scripts/configure.sh ghostty`

## Adding a New Surface

1. Add `<member>` to manifest.xml with login, role, directory, surface
2. Create `{dir}/` and `{dir}/.claude/` under jadecli-ecosystem
3. Run `bash scripts/configure.sh {dir}`
4. Create `{dir}/CLAUDE.md` with owner/auth info
5. Verify: `cat {dir}/.claude/settings.json | jq .env`

## Troubleshooting

- **Statusline shows "unknown"**: Check `JADECLI_*` env vars in surface settings.json
- **Session-init not firing**: Verify `SessionStart` hook in settings.json, matcher is `""`
- **Access denied unexpectedly**: Check `bash scripts/lock.sh status` and board.xml roles
- **Wrong identity**: Ensure Claude is launched from the correct surface subdir
