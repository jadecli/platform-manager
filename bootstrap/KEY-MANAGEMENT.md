# Key Management

## Principles

- **OAuth first**: `claude auth login` stores tokens in macOS Keychain
- **apiKeyHelper for rotation**: Fetches key on every request — rotate in backend, zero-touch
- **NEVER hardcode**: No tokens in config files, env vars, or scripts
- **CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1**: Subprocesses can't see API tokens

## Methods

| Method | Use Case | Rotation |
|--------|----------|----------|
| `claude auth login` | Interactive CLI | Auto-refresh, no manual rotation |
| `apiKeyHelper` | Scripted/CI, 1Password-backed | Zero-touch — rotate in 1Password |
| `CLAUDE_CODE_OAUTH_TOKEN` | GitHub Actions | Re-run `claude setup-token` |
| Plugin `sensitive: true` config | Plugin API keys | macOS Keychain / platform credential store |

## apiKeyHelper

In `managed-settings.d/20-jadecli-key-rotation.json`:
```json
{
  "apiKeyHelper": "op read 'op://jadecli-infra/claude-oauth/credential' 2>/dev/null || echo ''"
}
```

Called on every API request. Claude Code never persists the key.
Rotate in 1Password → next request uses new key automatically.

## GitHub Actions

```bash
claude setup-token | gh secret set CLAUDE_CODE_OAUTH_TOKEN --org jadecli --visibility all
```

## MCP Server Keys

Use env vars that resolve at runtime, not hardcoded values:
```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "$(gh auth token)"
  }
}
```

Claude Desktop does NOT support shell expansion in env values.
Use `apiKeyHelper` or start Desktop from a shell that has the token exported.

## Leaked Token Checklist

1. Revoke immediately: GitHub Settings → Developer settings → Tokens
2. Rotate: `claude setup-token` for OAuth, `op` for 1Password
3. Grep repo: `gitleaks detect --source .`
4. Check CI: `gh secret list --org jadecli`
