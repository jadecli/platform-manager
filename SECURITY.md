# Security

## Audit Status

Last audit: 2026-03-25

### Plugin Hooks (`hooks/hooks.json`)
- **SessionStart**: Calls `session-init.sh` — emits read-only XML context. No user input processing.
- **PreToolUse**: Calls `access-guard.sh` — validates file paths against allowed surfaces. Input parsed via `jq` (safe JSON parsing).
- **Risk**: Low. Commands are static strings with no variable interpolation.

### Access Guard (`access-guard.sh`)
- Lives in jadecli-ecosystem, not this repo.
- Uses `jq` for JSON input parsing (not grep/sed on raw input).
- Path validation uses case-match against known prefixes.
- **Known limitations**: Does not resolve symlinks or `../` — a symlink inside an allowed dir could point outside. Mitigation: surfaces use full clones, not symlinks to code.

### Vendored Code (`vendor/`)
- Scanned for hardcoded credentials: no actual secrets found.
- Pattern matches (e.g., `password` in test fixtures, `api_key` in config schemas) are from open-source libraries, not jadecli secrets.
- feapder user_pool references are generic proxy pool patterns, not credentials.

### Authentication
- **CRITICAL**: All Claude auth uses OAuth tokens, NEVER ANTHROPIC_API_KEY.
- GitHub Actions use `CLAUDE_CODE_OAUTH_TOKEN` secret.
- See `packages/scrapy-cli/src/primitives/auth.ts` for the auth primitive.

## Reporting

Report security issues to alex@jadecli.com.
