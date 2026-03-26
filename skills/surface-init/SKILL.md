---
name: surface-init
effort: low
description: >
  Initializes Claude Code session context for jadecli-ecosystem surfaces.
  Use when starting work in any jadecli-ecosystem subdirectory, onboarding a new surface,
  or troubleshooting identity/statusline issues. Reads manifest.xml and board.xml to
  resolve the current surface, inject identity context, and check lock state.
---

# surface-init

Resolves the current Claude login to a jadecli-ecosystem surface and loads context.

## On Session Start

1. Read `JADECLI_EMAIL` from env to identify the surface
2. Load `/Users/alexzh/jadecli-ecosystem/shared/context/session-start.xml`
3. Check lock state: `bash /Users/alexzh/jadecli-ecosystem/scripts/lock.sh status`
4. Read `shared/board.xml` for task assignments
5. Read `shared/memory/` for cross-surface decisions

## Surface Map

| Dir | Login | Platform | App |
|-----|-------|----------|-----|
| ghostty | alex@jadecli.com | cli | Ghostty |
| iterm2 | jade@jadecli.com | cli | iTerm2 |
| toad | zhouk.alex@gmail.com | cli | Toad |
| vscode | roger@jadecli.com | vscode | VS Code |
| cursor | robin@jadecli.com | vscode | Cursor |

## jcli Operations

```
jcli create agent <surface> <task>
jcli read surfaces | board | memory | agents
jcli understand <query>
jcli deactivate agent | surface | session
```
