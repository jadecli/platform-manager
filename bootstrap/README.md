# Bootstrap

Deterministic environment setup for jadecli team onboarding.

## Quick Start

```bash
# macOS (new machine)
bash bootstrap/install.sh --platform darwin

# Linux (CI/CD or remote device)
bash bootstrap/install.sh --platform linux
```

## What It Does

1. Installs pinned runtime versions from `versions.json`
2. Installs Anthropic-aligned toolchain (Claude Code, LSPs, extensions)
3. Configures git identity from `manifest.xml` surface mapping
4. Sets up SSH keys and signing
5. Installs Claude Code plugins and MCP servers
6. Validates the environment against expected checksums

## Files

```
bootstrap/
├── install.sh              # Entry point — detects platform, runs phases
├── phases/
│   ├── 01-runtime.sh       # Node, Python, Rust, uv (via mise/fnm)
│   ├── 02-claude.sh        # Claude Code CLI + auth + plugins
│   ├── 03-lsp.sh           # Language servers (TS, Python, Rust, etc.)
│   ├── 04-git.sh           # Git config, SSH keys, signing, includeIf
│   ├── 05-shell.sh         # Zsh, antidote, starship, aliases
│   └── 06-validate.sh      # Verify all versions match versions.json
├── Brewfile                 # macOS packages (brew bundle)
├── apt-packages.txt         # Linux packages (apt)
└── manifest-reader.sh       # Parse manifest.xml for surface identity
```

## Principles

- **Pinned versions**: Every tool has an exact version in `versions.json`
- **Anthropic-aligned**: Only tools referenced in code.claude.com/docs or Anthropic repos
- **Cross-platform**: macOS primary, Linux secondary (same tools, different installers)
- **Idempotent**: Safe to re-run — skips already-installed, upgrades if version differs
- **No competitors**: No Copilot, Codex, Gemini, Cline, Kiro, etc.
