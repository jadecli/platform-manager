---
effort: low
disable-model-invocation: true
argument-hint: "<prompt>"
description: Show how to run a quick --bare query for scripted/CI use
---
The user wants a fast, headless Claude Code invocation. Show them the exact command:

```bash
claude --bare -p "$ARGUMENTS"
```

If they provide a prompt, run it. If not, explain:
- `--bare` skips hooks, LSP, plugin sync, skill walks — fastest cold start
- Requires `ANTHROPIC_API_KEY` env var (OAuth/keychain disabled)
- Auto-memory is fully disabled
- Best for: CI pipelines, shell scripts, one-shot queries, git hooks
- Combine with `--output-format json` for machine-parseable output
- Combine with `--model sonnet` for cheaper/faster queries

Example patterns:
```bash
# One-shot code review in CI
claude --bare -p "Review this diff for bugs: $(git diff HEAD~1)"

# Generate commit message
claude --bare --model sonnet -p "Write a commit message for: $(git diff --cached)"

# Quick question
claude --bare -p "What does this error mean: $ERROR_MSG"
```
