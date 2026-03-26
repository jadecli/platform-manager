---
effort: low
disable-model-invocation: true
argument-hint: "[topic]"
allowed-tools: WebFetch
context: fork
agent: doc-researcher
---
Fetch and summarize the latest documentation from platform.claude.com for the topic: $ARGUMENTS

If no topic specified, fetch and summarize these key pages:
1. https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking — adaptive thinking (effort levels, when to use)
2. https://platform.claude.com/docs/en/build-with-claude/extended-thinking — extended thinking (budget_tokens, interleaved thinking)
3. https://platform.claude.com/docs/en/build-with-claude/structured-outputs — JSON outputs + strict tool use
4. https://platform.claude.com/docs/en/agent-sdk/overview — Agent SDK overview and capabilities

If a topic IS specified, construct the URL as:
- https://platform.claude.com/docs/en/build-with-claude/{topic}
- https://platform.claude.com/docs/en/agent-sdk/{topic}

Use WebFetch to retrieve each page. Summarize what's new or notable, focusing on:
- API parameters and their values
- Code examples in Python and TypeScript
- Breaking changes or deprecations
- Beta features requiring headers

If a page returns error or is empty, report that. Don't synthesize content from memory.
Present results in a table with: Feature | Status | Key Details | Code Snippet
