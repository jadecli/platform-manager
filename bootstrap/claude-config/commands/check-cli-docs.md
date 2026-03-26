---
effort: low
disable-model-invocation: true
argument-hint: "[topic]"
allowed-tools: WebFetch
context: fork
agent: doc-researcher
---
Fetch and summarize the latest Claude Code CLI documentation for the topic: $ARGUMENTS

First, fetch the docs index from https://code.claude.com/docs/llms.txt to find all available pages.

If a topic IS specified, find the matching page(s) from the index and fetch them with WebFetch.

If no topic specified, fetch these key pages and summarize what's new:
1. https://code.claude.com/docs/en/skills.md — skills system
2. https://code.claude.com/docs/en/sub-agents.md — custom subagents
3. https://code.claude.com/docs/en/hooks-guide.md — hooks
4. https://code.claude.com/docs/en/plugins.md — plugins
5. https://code.claude.com/docs/en/features-overview.md — extension overview
6. https://code.claude.com/docs/en/changelog.md — recent changes

Summarize each page focusing on:
- New features or capabilities
- Configuration format and examples
- How features interact (skills + subagents, hooks + MCP, etc.)

If a page returns error or is empty, report that. Don't synthesize content from memory.
Present results as a concise reference.
