#!/usr/bin/env bash
# ~/.claude/shell-helpers.sh
# Source this from your .zshrc: source ~/.claude/shell-helpers.sh

# Quick one-shot query (fastest cold start, no hooks/plugins)
cq() {
  claude --bare -p "$*"
}

# Quick query with JSON output (for piping/scripting)
cqj() {
  claude --bare --output-format json -p "$*"
}

# Quick query with sonnet (cheaper/faster)
cqs() {
  claude --bare --model sonnet -p "$*"
}

# Generate commit message from staged changes
claude-commit-msg() {
  local diff
  diff=$(git diff --cached --stat && echo "---" && git diff --cached)
  if [[ -z "$diff" ]]; then
    echo "No staged changes." >&2
    return 1
  fi
  claude --bare --model sonnet -p "Write a concise git commit message (1-2 sentences) for these staged changes. Output ONLY the message, no quotes or prefix:

$diff"
}

# Review last N commits (default 1)
claude-review() {
  local n="${1:-1}"
  claude --bare --model sonnet -p "Review this diff for bugs, security issues, and style problems. Be concise:

$(git diff HEAD~"$n")"
}

# Explain an error message
claude-explain() {
  claude --bare --model sonnet -p "Explain this error concisely and suggest a fix: $*"
}

# --- V2 SDK helpers ---

# Scaffold a V2 SDK project
claude-sdk-init() {
  local name="${1:?Usage: claude-sdk-init <project-name>}"
  mkdir -p "$name/src" "$name/.claude"
  cd "$name" || return 1
  cat > package.json <<'PKGJSON'
{
  "name": "PLACEHOLDER",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "start": "tsx src/index.ts",
    "build": "tsc",
    "dev": "tsx watch src/index.ts"
  },
  "dependencies": {
    "@anthropic-ai/claude-agent-sdk": "latest",
    "zod": "^3.23.0"
  },
  "devDependencies": {
    "tsx": "^4.0.0",
    "typescript": "^5.7.0"
  }
}
PKGJSON
  sed -i '' "s/PLACEHOLDER/$name/" package.json
  cat > tsconfig.json <<'TSCONFIG'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022", "ESNext.Disposable"],
    "outDir": "dist",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src"]
}
TSCONFIG
  cat > src/index.ts <<'SRCINDEX'
import { unstable_v2_createSession } from "@anthropic-ai/claude-agent-sdk";

await using session = unstable_v2_createSession({
  model: "claude-sonnet-4-6",
});

await session.send("Hello! What can you help me with?");
for await (const msg of session.stream()) {
  if (msg.type === "assistant") {
    const text = msg.message.content
      .filter((b: any) => b.type === "text")
      .map((b: any) => b.text)
      .join("");
    process.stdout.write(text);
  }
  if (msg.type === "result") {
    console.log(`\n[Cost: $${msg.subtype === "success" ? msg.total_cost_usd.toFixed(4) : "?"}]`);
  }
}
SRCINDEX
  npm install
  echo "Created $name — run 'npm run dev' to start"
}

# Run a V2 one-shot prompt from the shell (requires SDK installed globally or in cwd)
claude-v2() {
  CLAUDE_V2_PROMPT="$*" npx -y tsx -e "
    import { unstable_v2_prompt } from '@anthropic-ai/claude-agent-sdk';
    const r = await unstable_v2_prompt(process.env.CLAUDE_V2_PROMPT!, { model: 'claude-sonnet-4-6' });
    if (r.subtype === 'success') console.log(r.result);
    else console.error('Error:', r.errors);
  "
}

# --- Workflow helpers ---

# Start Claude in an isolated git worktree
claude-worktree() {
  local name="${1:?Usage: claude-worktree <branch-name>}"
  claude --worktree "$name"
}

# Start Claude in plan mode (read-only, no edits)
claude-plan() {
  claude --permission-mode plan "$@"
}

# Show recent turn-stop events from stop.log
claude-cost() {
  local n="${1:-20}"
  local log="${HOME}/.claude/logs/stop.log"
  [[ -f "$log" ]] || { echo "No stop.log yet." >&2; return 1; }
  tail -n "$n" "$log" | column -t -s $'\t'
}
