---
name: sdk-reference
description: Claude Agent SDK V2 patterns, API tool use (programmatic calling, tool search, input_examples), structured outputs, and best practices. Use when writing SDK code, building agents, working with @anthropic-ai/claude-agent-sdk, or using advanced tool use API features like allowed_callers, defer_loading, or code_execution.
user-invocable: false
---

# Claude Agent SDK V2 Quick Reference

> When recommending SDK patterns, verify signatures against `~/.claude/platform.claude.docs/typescript.md` if uncertain. Flag `unstable_v2_*` functions as preview. Distinguish Agent SDK (`@anthropic-ai/claude-agent-sdk`) from API SDK (`@anthropic-ai/sdk`).

## V2 Core API (preview, unstable)

```typescript
// One-shot
const result = await unstable_v2_prompt("prompt", { model: "claude-opus-4-6" });

// Session
await using session = unstable_v2_createSession({ model: "claude-opus-4-6" });
await session.send("message");
for await (const msg of session.stream()) { /* handle */ }

// Resume
await using s = unstable_v2_resumeSession(sessionId, { model: "claude-opus-4-6" });
```

## Key Options

| Option | Type | Description |
|--------|------|-------------|
| `systemPrompt` | `string \| { preset: "claude_code", append?: string }` | Custom or extend default |
| `settingSources` | `["user","project","local"]` | Load CLAUDE.md and settings |
| `allowedTools` | `string[]` | Auto-approve (does NOT restrict) |
| `disallowedTools` | `string[]` | Always deny (overrides everything) |
| `permissionMode` | `default\|acceptEdits\|bypassPermissions\|plan\|dontAsk` | Permission handling |
| `maxTurns` | `number` | Limit agentic loops |
| `effort` | `low\|medium\|high\|max` | Thinking depth |
| `enableFileCheckpointing` | `boolean` | Enable rewindFiles() |
| `agents` | `Record<string, AgentDefinition>` | Inline subagent definitions |
| `mcpServers` | `Record<string, McpServerConfig>` | MCP server configs |
| `hooks` | `Partial<Record<HookEvent, HookCallbackMatcher[]>>` | Programmatic hooks |
| `sandbox` | `SandboxSettings` | OS-level isolation |

## In-Process MCP Server

```typescript
import { tool, createSdkMcpServer } from "@anthropic-ai/claude-agent-sdk";
import { z } from "zod";

const myTool = tool("get-weather", "Get weather for a city", { city: z.string() },
  async ({ city }) => ({ content: [{ type: "text", text: `Sunny in ${city}` }] }),
  { annotations: { readOnlyHint: true } }
);

const server = createSdkMcpServer({ name: "weather", tools: [myTool] });
// Use: mcpServers: { weather: server }
```

## Message Filtering Pattern

```typescript
for await (const msg of session.stream()) {
  if (msg.type === "assistant") {
    const text = msg.message.content
      .filter((b) => b.type === "text")
      .map((b) => b.text)
      .join("");
  }
  if (msg.type === "result") {
    if (msg.subtype === "success") { /* msg.result, msg.total_cost_usd */ }
    else { /* msg.errors */ }
  }
}
```

## Session History

```typescript
import { listSessions, getSessionMessages } from "@anthropic-ai/claude-agent-sdk";
const sessions = await listSessions({ dir: "/path", limit: 10 });
const msgs = await getSessionMessages(sessions[0].sessionId, { dir: "/path" });
```

## Structured Outputs

Return validated JSON from agent workflows. Define schema, agent uses tools freely, you get typed data back.

```typescript
import { z } from "zod";

// Define with Zod for type safety
const TodoReport = z.object({
  todos: z.array(z.object({
    text: z.string(),
    file: z.string(),
    line: z.number(),
    author: z.string().optional(),
  })),
  total_count: z.number(),
});
type TodoReport = z.infer<typeof TodoReport>;

// V1: pass via outputFormat
for await (const msg of query({
  prompt: "Find all TODO comments and who added them",
  options: {
    outputFormat: { type: "json_schema", schema: z.toJSONSchema(TodoReport) }
  }
})) {
  if (msg.type === "result" && msg.structured_output) {
    const parsed = TodoReport.safeParse(msg.structured_output);
    if (parsed.success) console.log(parsed.data.total_count);
  }
}

// Raw JSON Schema (without Zod)
const schema = {
  type: "object",
  properties: {
    name: { type: "string" },
    items: { type: "array", items: { type: "string" } }
  },
  required: ["name", "items"]
};
```

**Error handling:** Check `msg.subtype`:
- `"success"` → `msg.structured_output` has validated data
- `"error_max_structured_output_retries"` → agent couldn't produce valid output

**Tips:** Keep schemas focused, make optional fields optional, use clear prompts.

## API SDK Structured Outputs (`@anthropic-ai/sdk`, GA)

Separate from Agent SDK — use `output_config.format` (replaces beta `output_format`):

```typescript
import Anthropic from "@anthropic-ai/sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";

const response = await client.messages.parse({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Extract contact info..." }],
  output_config: { format: zodOutputFormat(ContactSchema) },
});
// response.parsed_output is typed and validated
```

Python: `client.messages.parse(output_format=PydanticModel)` — auto-transforms schema.

## Strict Tool Use

Guarantees tool `input` matches `input_schema` and `name` is valid:
```typescript
{ name: "get_weather", strict: true, input_schema: { ..., additionalProperties: false } }
```

- Combinable with `output_config.format` in same request
- Limits: 20 strict tools/request, 24 optional params total, 16 union-type params
- Grammar compiled on first use, cached 24h
- Incompatible with programmatic tool calling

## Programmatic Tool Calling (API-level, code_execution_20260120)

Claude writes Python that calls your tools inside a sandbox. Intermediate results stay out of context — only final output reaches Claude. Key for large data, multi-step workflows, batch operations.

### Tool definition with `allowed_callers`
```typescript
tools: [
  { type: "code_execution_20260120", name: "code_execution" },
  {
    name: "query_database",
    description: "Execute SQL. Returns JSON array of row objects.",
    input_schema: { type: "object", properties: { sql: { type: "string" } }, required: ["sql"] },
    allowed_callers: ["code_execution_20260120"]  // Only callable from code
  }
]
```

**`allowed_callers` values:**
- `["direct"]` — traditional tool use only (default)
- `["code_execution_20260120"]` — only from code execution
- `["direct", "code_execution_20260120"]` — both (pick one for clarity)

### Response: `caller` field
```typescript
// Programmatic call has caller.type + caller.tool_id
if (block.type === "tool_use" && block.caller?.type === "code_execution_20260120") {
  // This tool call came from code execution — provide result, it goes back to code not context
}
```

### Container reuse
```typescript
// Response includes container: { id: "container_xyz", expires_at: "..." }
// Reuse in next request to maintain state:
const next = await client.messages.create({ container: "container_xyz", ... });
```

**Key constraints:**
- Containers expire ~4.5min idle. Respond to tool calls before expiry.
- Tool results from programmatic calls do NOT enter Claude's context (only final stdout)
- `strict: true` tools incompatible with programmatic calling
- MCP connector tools cannot be called programmatically (yet)

### When to use
- Processing large datasets needing only aggregates
- 3+ dependent tool calls in sequence
- Filtering/transforming results before Claude sees them
- Parallel operations across many items

## Tool Search Tool (defer_loading)

Load tools on-demand instead of all upfront. 85% token reduction for large tool libraries.

```typescript
tools: [
  { type: "tool_search_tool_regex_20251119", name: "tool_search_tool_regex" },
  { name: "github.createPR", description: "...", input_schema: {...}, defer_loading: true },
  // ... hundreds more deferred tools
]
```

Claude searches for tools when needed. Only matched tools enter context.

## Tool Use Examples (input_examples)

Show Claude concrete usage patterns, not just schemas:

```typescript
{
  name: "create_ticket",
  input_schema: { /* ... */ },
  input_examples: [
    { title: "Login 500 error", priority: "critical", labels: ["bug","auth","prod"],
      reporter: { id: "USR-12345", name: "Jane" }, due_date: "2024-11-06",
      escalation: { level: 2, notify_manager: true, sla_hours: 4 } },
    { title: "Add dark mode", labels: ["feature-request","ui"],
      reporter: { id: "USR-67890", name: "Alex" } },
    { title: "Update docs" }  // minimal example
  ]
}
```

1-5 examples per tool. Show minimal, partial, and full patterns. Use realistic data.

## Hook Events
`PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `Notification`, `UserPromptSubmit`, `SessionStart`, `SessionEnd`, `Stop`, `SubagentStart`, `SubagentStop`, `PreCompact`, `PermissionRequest`, `Setup`, `TeammateIdle`, `TaskCompleted`, `ConfigChange`, `WorktreeCreate`, `WorktreeRemove`
