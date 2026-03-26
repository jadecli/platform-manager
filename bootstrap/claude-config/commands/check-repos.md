---
effort: low
disable-model-invocation: true
argument-hint: "[safety]"
allowed-tools: Bash(gh *)
context: fork
---
Check for recent updates across Anthropic's key GitHub repos. Use `gh` CLI commands.

For each repo below, check the latest release (or recent commits if no releases) and summarize what's new:

## Core Tools
- anthropics/claude-code — `gh release list -R anthropics/claude-code -L 3`
- anthropics/claude-agent-sdk-python — `gh release list` or `gh api repos/anthropics/claude-agent-sdk-python/commits?per_page=5`
- anthropics/claude-agent-sdk-typescript — same
- anthropics/claude-agent-sdk-demos — latest commits
- anthropics/claude-plugins-official — latest commits
- anthropics/skills — latest commits

## Client SDKs
- anthropics/anthropic-sdk-python — latest release
- anthropics/anthropic-sdk-typescript — latest release
- anthropics/anthropic-sdk-java — latest release
- anthropics/anthropic-sdk-go — latest release (if exists)

## MCP Ecosystem
- modelcontextprotocol/servers — latest commits (new/updated servers)
- modelcontextprotocol/python-sdk — latest release
- modelcontextprotocol/typescript-sdk — latest release
- modelcontextprotocol/rust-sdk — latest release
- modelcontextprotocol/java-sdk — latest release

## Safety Research (optional, if $ARGUMENTS includes "safety")
- safety-research/SHADE-Arena
- safety-research/auditing-agents
- safety-research/bloom

If a `gh` command fails, report the error and move on. Don't fabricate release data.
Summarize in a table: Repo | Latest Version/Commit | Date | Notable Changes
