---
effort: medium
disable-model-invocation: true
argument-hint: "<project-name> [v1|v2]"
allowed-tools: Write, Edit, Bash(npm *), Bash(mkdir *), Read
---
Scaffold a new Claude Agent SDK project. Default to V2 interface unless "v1" is specified.

Before scaffolding, verify the latest SDK package version: `npm view @anthropic-ai/claude-agent-sdk version`

Arguments: $ARGUMENTS

## V2 scaffold (default)

Create these files:

### package.json
- Dependencies: `@anthropic-ai/claude-agent-sdk`, `zod`, `typescript` (dev)
- Scripts: `start`, `build`, `dev`
- `"type": "module"`

### tsconfig.json
- Target ES2022, module NodeNext
- `lib: ["ES2022", "ESNext.Disposable"]` for `await using` support
- Strict mode enabled

### src/index.ts
Use `unstable_v2_createSession` with `await using`:
```typescript
import { unstable_v2_createSession } from "@anthropic-ai/claude-agent-sdk";

await using session = unstable_v2_createSession({
  model: "claude-sonnet-4-6",
  systemPrompt: { type: "preset", preset: "claude_code", append: "..." },
  settingSources: ["project"],
});

await session.send("Hello!");
for await (const msg of session.stream()) {
  if (msg.type === "assistant") {
    const text = msg.message.content
      .filter((b) => b.type === "text")
      .map((b) => b.text)
      .join("");
    process.stdout.write(text);
  }
}
```

### src/tools.ts (if MCP tools needed)
Use `tool()` + `createSdkMcpServer()` with Zod schemas.

### src/schemas.ts (structured output schemas)
```typescript
import { z } from "zod";

export const TaskResult = z.object({
  summary: z.string(),
  files_modified: z.array(z.string()),
  success: z.boolean(),
  errors: z.array(z.string()).optional(),
});
export type TaskResult = z.infer<typeof TaskResult>;
```

Show how to use with `outputFormat`:
```typescript
import { TaskResult } from "./schemas.js";

// In query options:
outputFormat: { type: "json_schema", schema: z.toJSONSchema(TaskResult) }

// In result handling:
if (msg.type === "result") {
  if (msg.subtype === "success" && msg.structured_output) {
    const result = TaskResult.parse(msg.structured_output);
    console.log(result.summary);
  } else if (msg.subtype === "error_max_structured_output_retries") {
    console.error("Failed to produce valid structured output");
  }
}
```

### src/programmatic-tools.ts (for API-level programmatic tool calling)
Example showing `allowed_callers` + `code_execution_20260120`:
```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// Tool callable from code execution — results stay out of context
const response = await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 4096,
  messages: [{ role: "user", content: "Analyze sales across all regions" }],
  tools: [
    { type: "code_execution_20260120", name: "code_execution" },
    {
      name: "query_database",
      description: "Execute SQL. Returns JSON array of row objects with fields: id, region, revenue, date.",
      input_schema: {
        type: "object",
        properties: { sql: { type: "string", description: "SQL query" } },
        required: ["sql"]
      },
      allowed_callers: ["code_execution_20260120"],
      input_examples: [
        { sql: "SELECT region, SUM(revenue) as total FROM sales GROUP BY region" },
        { sql: "SELECT * FROM sales WHERE region = 'West' AND date >= '2024-01-01'" }
      ]
    }
  ]
});

// Handle programmatic tool calls — check caller.type
for (const block of response.content) {
  if (block.type === "tool_use" && block.caller?.type === "code_execution_20260120") {
    // Execute tool, return result — it goes back to code, not Claude's context
    console.log(`Programmatic call to ${block.name}:`, block.input);
  }
}
```

### .claude/CLAUDE.md
Project-specific instructions.

## V1 scaffold
Use `query()` with async generator pattern if "v1" specified.

After scaffolding, run `npm install`.
