# Bootstrap

Deterministic environment setup for jadecli team onboarding.

## Quick Start

```bash
# macOS (new machine or existing)
bash bootstrap/install.sh --platform darwin

# Linux (CI/CD or remote — test via GitHub Actions, not from macOS)
bash bootstrap/install.sh --platform linux

# Validate only
bash bootstrap/install.sh --phase 06

# Dry run
bash bootstrap/install.sh --platform darwin --dry-run

# Secondary identity (separate Claude auth, shared config)
bash bootstrap/phases/multi-identity-setup.sh .claude-jade
```

## Surface → Platform Mapping

Test what matches your surface. Don't test Linux from macOS or vice versa.

| Surface | Platform | Terminal/Editor | Test on |
|---------|----------|-----------------|---------|
| ghostty | darwin/cli | Ghostty | This macOS device |
| iterm2 | darwin/cli | iTerm2 | This macOS device |
| toad | darwin/cli | Toad | This macOS device |
| vscode | darwin/vscode | VS Code | This macOS device |
| cursor | darwin/vscode | Cursor | This macOS device |
| ci | linux/cli | GitHub Actions | ubuntu-latest runner |

Reference: [code.claude.com/docs/en/platforms](https://code.claude.com/docs/en/platforms)

## Phases

| Phase | Script | What | Skip on |
|-------|--------|------|---------|
| 01 | runtime.sh | Node, Python, Rust, uv | — |
| 02 | claude.sh | Claude Code CLI (native installer) + managed-settings.d | CI (no auth) |
| 03 | lsp.sh | 8 language servers | — |
| 04 | git.sh | SSH keys, signing, includeIf | CI (no interactive keygen) |
| 05 | shell.sh | zsh, antidote, starship, CLI tools | — |
| 06 | validate.sh | Version check against versions.json | — |

## Multi-Identity

One macOS device, multiple Claude logins:

```
~/.claude/          ← primary (alex@jadecli.com)
~/.claude-jade/     ← secondary (jade@jadecli.com)
  ├── 16 symlinks → ~/.claude/  (shared: settings, hooks, commands, plugins, ...)
  └── sessions/                 (separate: auth credentials, session history)
```

`CLAUDE_CONFIG_DIR` replaces the entire `~/.claude/` path.
Without symlinks, the secondary identity has no hooks, settings, or plugins.
Use `multi-identity-setup.sh` to create the symlink structure.

## Principles

- **Pinned versions**: Every tool has an exact version in `versions.json`
- **Anthropic-aligned**: Only tools from code.claude.com/docs or Anthropic repos
- **Surface-tested**: Each surface tests its own platform (macOS tests macOS, CI tests Linux)
- **Idempotent**: Safe to re-run — skips installed, upgrades if version differs
- **No competitors**: No Copilot, Codex, Gemini, Cline, Kiro, etc.
- **Native installer**: Claude Code via `curl`, not npm (deprecated)
