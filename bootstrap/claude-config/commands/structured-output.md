---
effort: medium
disable-model-invocation: true
argument-hint: "<description of data shape>"
allowed-tools: Write, Edit, Read
---
Generate a Zod schema (TypeScript) and JSON Schema for structured agent output.

Input description: $ARGUMENTS

## What to generate

1. **Zod schema** with full type inference:
```typescript
import { z } from "zod";

export const MySchema = z.object({
  // ... fields from description
});
export type MySchema = z.infer<typeof MySchema>;
```

2. **Usage pattern** with the Agent SDK:
```typescript
// V1 (query)
for await (const msg of query({
  prompt: "...",
  options: {
    outputFormat: { type: "json_schema", schema: z.toJSONSchema(MySchema) }
  }
})) {
  if (msg.type === "result") {
    if (msg.subtype === "success" && msg.structured_output) {
      const data = MySchema.parse(msg.structured_output);
    } else if (msg.subtype === "error_max_structured_output_retries") {
      // handle failure
    }
  }
}
```

3. **Equivalent Pydantic model** (Python):
```python
from pydantic import BaseModel
class MySchema(BaseModel):
    # ... fields
```

4. **API SDK usage** (GA — `output_config.format` replaces beta `output_format`):
```typescript
import Anthropic from "@anthropic-ai/sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";

const response = await client.messages.parse({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "..." }],
  output_config: { format: zodOutputFormat(MySchema) },
});
console.log(response.parsed_output);
```

5. **Strict tool use** (guarantees tool input matches schema):
```json
{ "name": "tool_name", "strict": true, "input_schema": { ... } }
```

## Guidelines
- Use `z.enum()` for fixed string values
- Use `.optional()` for fields the agent might not find
- Use `.describe()` on fields to help Claude understand intent
- Keep schemas focused — avoid deeply nested required structures
- Use `z.array()` with `.min(1)` when at least one item is expected
- Prefer flat structures over deep nesting
- Schema complexity limits: max 20 strict tools/request, 24 optional params total, 16 union-type params total
- `strict: true` incompatible with programmatic tool calling
