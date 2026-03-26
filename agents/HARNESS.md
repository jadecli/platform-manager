# Harness Design Spec

Three-agent architecture for long-running autonomous application development,
based on [Anthropic's harness design research](https://www.anthropic.com/engineering/harness-design).

## Architecture

```
User prompt (1-4 sentences)
         │
         ▼
┌─────────────────┐
│  harness-planner │  Expands prompt → full product spec
│  (opus)          │  with design language + AI integration
└────────┬────────┘
         │  harness/specs/{name}.md
         ▼
┌─────────────────┐     sprint contract      ┌──────────────────┐
│ harness-generator│◄──────────────────────►│ harness-evaluator  │
│ (opus)           │  negotiate before each  │ (opus)             │
│                  │  sprint, iterate after   │                    │
│ Implements one   │                          │ Tests via Playwright│
│ sprint at a time │  harness/handoffs/       │ Grades 4 criteria  │
│                  │──────────────────────►│ Threshold: 7.0/10  │
│                  │                          │                    │
│                  │◄──────────────────────│ harness/evaluations/ │
│                  │  fix feedback            │                    │
└─────────────────┘                          └──────────────────┘
```

## Directory structure (codegen targets)

```
harness/
├── specs/              # Planner output: product specs
├── contracts/          # Generator ↔ evaluator: sprint contracts
├── handoffs/           # Generator → evaluator: sprint completion
├── evaluations/        # Evaluator → generator: grades + feedback
└── orchestrator.ts     # Agent SDK entry point (TODO: codegen)
```

## What exists today

| Component | Status | Location |
|-----------|--------|----------|
| harness-planner agent | ✅ Created | `agents/harness-planner.md` |
| harness-generator agent | ✅ Created | `agents/harness-generator.md` |
| harness-evaluator agent | ✅ Created | `agents/harness-evaluator.md` |
| Directory structure | ❌ TODO | `harness/` |
| Orchestrator (Agent SDK) | ❌ TODO | `harness/orchestrator.ts` |
| Evaluation criteria calibration | ❌ TODO | Few-shot examples for evaluator |
| Playwright MCP integration | ❌ TODO | MCP config for evaluator |
| Ralph-wiggum loop integration | ❌ TODO | Stop hook for continuous iteration |

## What needs to be codegen'd

### Phase 1: Scaffolding
- [ ] `harness/` directory structure
- [ ] `harness/orchestrator.ts` — Agent SDK entry point that chains planner → generator → evaluator
- [ ] `harness/package.json` — deps on `@anthropic-ai/claude-agent-sdk`

### Phase 2: Orchestration
- [ ] Sprint contract negotiation loop (generator proposes, evaluator reviews, iterate until agreed)
- [ ] Sprint execution loop (generator builds, evaluator grades, iterate until pass)
- [ ] Context reset strategy: single continuous session with auto-compaction (Opus 4.6 handles this natively per the blog post)

### Phase 3: Evaluation calibration
- [ ] Few-shot evaluation examples with detailed score breakdowns
- [ ] Per-criterion rubric with concrete fail/pass examples
- [ ] Score drift detection across iterations

### Phase 4: Plugin integration
Harness-relevant plugins from official + community marketplaces:

| Plugin | Source | What it provides |
|--------|--------|-----------------|
| `feature-dev` | official (vendored) | Existing planner→architect→reviewer pipeline — reference architecture |
| `ralph-wiggum` | official (vendored) | Stop hook loop for continuous iteration without human intervention |
| `frontend-design` | official (vendored) | Design skill with aesthetic criteria — feeds into planner |
| `code-review` | official (vendored) | Review commands — feeds into evaluator |
| `playwright-pro` | community | Playwright test generation + 3 specialized agents |
| `bugbash` | community | Hands-on QA testing with evidence bars |
| `spec-engine` | community | Spec-driven wave-based parallel agent execution |
| `challenger` | community | Multi-agent adversarial stress-testing |
| `evolve-loop` | community | Self-learning pipeline with Scout/Builder/Auditor/Operator |

### Phase 5: Commands
- [ ] `/harness <prompt>` — full pipeline: plan → build → evaluate → iterate
- [ ] `/harness:plan <prompt>` — planner only
- [ ] `/harness:evaluate` — evaluator only against current state

## Key decisions from the Anthropic blog

1. **Context resets vs compaction**: Opus 4.6 removed the "context anxiety" behavior that required resets with Sonnet 4.5. Use single continuous sessions with auto-compaction. Drop sprint decomposition for simpler tasks; keep it for ambitious multi-feature specs.

2. **Separate generator from evaluator**: Self-evaluation is unreliable — agents praise their own work. Tuning a standalone evaluator to be skeptical is more tractable than making a generator self-critical.

3. **Sprint contracts**: Bridge the gap between high-level spec and testable implementation. Generator proposes, evaluator reviews, iterate until agreed. Prevents spec-implementation drift.

4. **Evaluator with Playwright**: The evaluator navigates the running application rather than scoring static screenshots. Each QA cycle takes real wall-clock time. Full runs stretch to hours.

5. **Criteria as steering**: Evaluation criteria shape generator behavior even before evaluator feedback. Phrases like "museum quality" in criteria directly steer aesthetic output. Criteria = prompt engineering for the generator.

6. **Re-examine on model upgrade**: Every harness component encodes an assumption about what the model can't do. Stress-test these assumptions when models improve. Strip what's no longer load-bearing.

## File-based inter-agent communication

Agents communicate via files, not direct messages:
- Planner writes spec → Generator reads it
- Generator writes contract → Evaluator reads and responds in same file
- Generator writes handoff → Evaluator reads it
- Evaluator writes evaluation → Generator reads feedback

This pattern is compatible with both Claude Code's native agent system and the Agent SDK.
