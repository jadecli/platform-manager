---
effort: medium
disable-model-invocation: true
argument-hint: "<tool-name> <description>"
allowed-tools: Write, Edit, Read
---
Generate a complete tool definition with advanced features for the Claude API.

Input: $ARGUMENTS

## Generate all three variants

### 1. Basic tool (direct calling)
```json
{
  "name": "tool_name",
  "description": "Detailed description including return format",
  "input_schema": {
    "type": "object",
    "properties": { ... },
    "required": [...]
  }
}
```

### 1b. Strict tool (guaranteed schema validation)
Same as basic plus:
```json
{
  "strict": true,
  "input_schema": {
    ...
    "additionalProperties": false
  }
}
```
Guarantees tool `input` matches schema and `name` is valid. Limits: 20 strict tools/request, 24 optional params total, 16 union-type params.

### 2. Programmatic tool (code execution calling)
Same as above plus:
```json
{
  "allowed_callers": ["code_execution_20260120"]
}
```

Add this when:
- Tool returns large datasets that should be filtered/aggregated in code
- Tool will be called in loops (batch processing)
- Intermediate results shouldn't enter Claude's context

### 3. Deferred tool (on-demand discovery)
Same as basic plus:
```json
{
  "defer_loading": true
}
```

Add this when tool is used infrequently or is part of a large library (10+ tools).

### 4. With input_examples
Add 3 examples showing minimal, partial, and full usage:
```json
{
  "input_examples": [
    { /* full params — show all fields, realistic data */ },
    { /* partial — common usage with key optionals */ },
    { /* minimal — just required fields */ }
  ]
}
```

Use realistic data: real city names, plausible IDs (USR-12345), ISO dates (2024-11-06), kebab-case labels.

### 5. Python and TypeScript SDK integration
Show how to use with the Anthropic SDK:

```python
# Python
client.messages.create(
    tools=[
        {"type": "code_execution_20260120", "name": "code_execution"},
        { "name": "...", "allowed_callers": ["code_execution_20260120"], ... }
    ]
)
```

```typescript
// TypeScript
client.messages.create({
    tools: [
        { type: "code_execution_20260120", name: "code_execution" },
        { name: "...", allowed_callers: ["code_execution_20260120"], ... }
    ]
});
```

## Guidelines
- Document return format in description (JSON structure, field types, possible values)
- Use `allowed_callers` — don't combine direct + code_execution unless needed
- `strict: true` is incompatible with programmatic calling
- MCP connector tools can't be called programmatically yet
- Keep input_examples to 1-5 per tool, use realistic data
