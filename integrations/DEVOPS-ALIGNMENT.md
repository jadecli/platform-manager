# DevOps Alignment Strategy

Stay aligned with Anthropic engineering practices and the broader Claude ecosystem.

## Source Repos

Upstream repos we track for DevOps patterns, CI/CD, and tooling:

### Anthropic Engineering (`anthropics/`)
| Repo | What we reuse | Vendored |
|------|--------------|----------|
| `anthropics/claude-code` | Hooks, settings schema, plugin system, changelog | Yes |
| `anthropics/claude-code-action` | CI review workflow, @claude interaction | Via workflow |
| `anthropics/claude-code-security-review` | Security review workflow | Via workflow |
| `anthropics/claude-plugins-community` | Plugin marketplace (500 plugins) | Crawled |
| `anthropics/claude-plugins-official` | Official plugins + channels | Crawled |
| `anthropics/knowledge-work-plugins` | Role-specific plugins | Crawled |
| `anthropics/skills` | Document/example skills | Crawled |
| `anthropics/anthropic-sdk-typescript` | Agent SDK, API client | Vendored |
| `anthropics/anthropic-sdk-python` | Agent SDK, API client | Vendored |
| `anthropics/anthropic-cookbook` | Patterns, examples | Vendored |
| `anthropics/courses` | Training material | Vendored |

### AI SDKs (`anthropic-ai/`)
| Repo | Purpose |
|------|---------|
| `anthropic-ai/claude-agent-sdk` | Agent SDK (spawning, tool use, structured output) |
| `anthropic-ai/claude-code` | Claude Code CLI source |

## Documentation Sources

Five doc sites we crawl and align against:

| Site | Content | Crawler |
|------|---------|---------|
| `code.claude.com/docs` | Claude Code CLI, hooks, settings, channels, remote control | `neon_docs` spider (planned) |
| `platform.claude.com/docs` | Claude API, models, tool use, prompt engineering | Planned |
| `agentskills.io` | Agent skill marketplace, skill authoring | Planned |
| `modelcontextprotocol.io` | MCP spec, registry, SDKs, extensions | Task #46 |
| `docs.anthropic.com` | API reference, safety, usage policies | Planned |

## Why Crawlers

We build crawlers to:
1. **Stay current** — docs change weekly. Crawlers detect drift.
2. **Feed context** — session-start hooks load recent doc changes as compact context.
3. **Track the ecosystem** — 660+ plugins, MCP registry, skill marketplace all evolving.
4. **Validate alignment** — compare our hooks/settings/workflows against upstream patterns.

## Automation Pipeline

```
Crawl docs          Compare against         Update local
& registries   →    our config/code    →    config + alert
                                            on drift

┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Scrapy        │    │ drift-check  │    │ notify.sh    │
│ spiders       │───→│ scripts      │───→│ Slack/iMsg   │
│               │    │              │    │              │
│ • code.claude │    │ • settings   │    │ • human      │
│ • platform    │    │ • hooks      │    │   approval   │
│ • MCP registry│    │ • workflows  │    │              │
│ • agentskills │    │ • plugins    │    │              │
└──────────────┘    └──────────────┘    └──────────────┘
```

## Scheduled Runs

Claude Code native scheduling for periodic alignment checks:

| Task | Method | Frequency |
|------|--------|-----------|
| Doc crawl | `claude --cron` / Cowork scheduled task | Daily |
| Plugin index | `claude --cron` / Cowork scheduled task | Daily |
| Config drift check | SessionStart hook (rate-limited) | Per session (1x/day) |
| Changelog review | `/changelog-review` command | On CLI upgrade |
| MCP registry sync | Dispatch task from Claude Desktop | Weekly |

### Claude Code Cron (native)
```bash
# Daily doc crawl at 9am
claude --cron "0 9 * * *" --print "crawl code.claude.com/docs and report changes"

# Weekly MCP registry sync
claude --cron "0 10 * * 1" --print "sync MCP registry, update dim_mcp_server"
```

### Dispatch (from Claude Desktop/Mobile)
Send a task to a running local session from your phone:
```
Dispatch → "Check if our hooks match the latest claude-code changelog"
```

### Cowork Scheduled Tasks
Long-running crawls in Anthropic-managed cloud:
```
claude cowork --scheduled "daily 9am" "Run plugin ecosystem crawl, deep phase"
```

## Version Tracking

`versions.json` pins all upstream dependencies:
- Runtime versions (claude-cli, node, python, rust, uv)
- Vendor commit hashes (claude-code, SDKs, cookbooks)
- LSP versions
- Cask versions

Phase 06 (`validate.sh`) verifies pins match installed versions.
Drift-check compares config against repo source of truth.
