---
effort: low
disable-model-invocation: true
allowed-tools: WebFetch, Read, Bash(ls *)
context: fork
agent: doc-researcher
---
Fetch the Claude Code changelog and compare against my current ~/.claude setup.

1. WebFetch https://code.claude.com/docs/en/changelog.md (read the latest 2-3 versions)
2. Read ~/.claude/settings.json, ~/.claude/settings.local.json, and ls ~/.claude/hooks/
3. Read ~/.claude/statusline-command.sh
4. For each new feature or setting in the changelog, check whether my setup already uses it
5. Summarize in a table:

| Feature | Version | Status | Action |
|---------|---------|--------|--------|
| ... | 2.1.XX | Already using / Not using / N/A | What to do |

Focus on actionable items — skip pure bug fixes and platform-specific fixes (Windows, VSCode) unless relevant to my macOS terminal setup.
If a changelog entry is unclear, note "unclear — verify manually" rather than guessing the feature.
