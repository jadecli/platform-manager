# Changelog Parser & Canonical Feature Library

## Context

Build a system that parses Claude Code and SDK changelogs into structured data, then extracts a canonical feature library of all primitives (env vars, settings, hooks, flags, commands, tools, keybindings, etc.) with SDK parity tracking.

**Blog context:** The "auto mode" blog post (Mar 25, 2026) describes the `--permission-mode auto` alternative to `--dangerously-skip-permissions`. This is exactly the kind of feature the library should capture: name, category, version introduced, action required, cross-SDK availability.

**Sources:**
1. Claude Code changelog (`code.claude.com/docs/en/changelog`) — versions 2.1.30–2.1.84
2. Python Agent SDK changelog (`anthropics/claude-agent-sdk-python`)
3. TypeScript Agent SDK changelog (`anthropics/claude-agent-sdk-typescript`)
4. Skills README, Plugins README, Code Action README — static reference data

**Existing infra:** Scrapy crawler with IndexPipeline→DiffPipeline→ChangelogPipeline, TypeScript Zod primitives in `packages/scrapy-cli/src/primitives/`, Python 3.12+ with dataclasses (no Pydantic).

---

## Implementation

### Phase 1: Python Parser Module (`crawler/parsers/`)

**New files (5):**

1. **`crawler/parsers/__init__.py`** — empty init

2. **`crawler/parsers/models.py`** — dataclasses
   - `ChangelogEntry`: source, version, date, category, raw_text, identifiers (dict of lists), pr_numbers, commit_hashes
   - `FeatureRecord`: name, category, introduced_version, source, description, action_required, os_scope, plan_scope, sdk_parity
   - Literal types for `ChangelogSource`, `FeatureCategory`, `ActionRequired`

3. **`crawler/parsers/extractor.py`** — regex-based identifier extraction
   - `PATTERNS` dict with compiled regex for each category: env_var (`CLAUDE_*/ANTHROPIC_*`), setting (backtick camelCase), hook (PascalCase known names), cli_flag (`--*`), slash_command (`/*`), tool (PascalCase tool names), keybinding (`Ctrl+*`), mcp_feature, permission_mode, action_mode
   - `extract_identifiers(text) -> dict[str, list[str]]`
   - `infer_action_required(text, category, name) -> ActionRequired` — heuristics: "managed"/"enterprise" → admin, "opt-in"/"set to" → opt-in, keybinding → learn, default → auto
   - `infer_os_scope(text) -> list[str]` — detect "macOS"/"Windows"/"Linux" mentions
   - `infer_plan_scope(text) -> list[str]` — detect "Team"/"Enterprise"/"Max" mentions

4. **`crawler/parsers/changelog_parser.py`** — format-specific parsers
   - `parse_claude_code_changelog(md) -> list[ChangelogEntry]` — state machine: VERSION_HEADER → SUBSECTION_HEADER → BULLET, verb prefix determines category
   - `parse_python_sdk_changelog(md) -> list[ChangelogEntry]` — `## 0.1.X` headers, `### Features/Bug Fixes` subsections, strip PR/commit refs
   - `parse_typescript_sdk_changelog(md) -> list[ChangelogEntry]` — same format as Python SDK
   - `parse_changelog(md, source) -> list[ChangelogEntry]` — match dispatcher

5. **`crawler/parsers/feature_builder.py`** — aggregation
   - `build_feature_records(entries) -> list[FeatureRecord]` — group by (name, category), use earliest version as introduced_version, cross-ref SDK parity
   - `write_features_index(records, path)` — JSON with metadata header (generated_at, cli_version, total, by_category)
   - `write_changelog_entries_jsonl(entries, path)` — one JSON per line

### Phase 2: Scrapy Spider + Pipeline

**New files (2):**

6. **`crawler/spiders/changelog_sources.py`** — `ChangelogSourcesSpider`
   - 3 remote URLs: Claude Code changelog, Python SDK raw CHANGELOG.md, TS SDK raw CHANGELOG.md
   - Yields standard page items (for existing pipelines) + `feature_batch` items (raw markdown + source tag)
   - Polite settings: DOWNLOAD_DELAY 1.5, CONCURRENT_REQUESTS 2

7. **`crawler/pipelines/feature_extraction.py`** — `FeatureExtractionPipeline` (priority 600)
   - `open_spider`: init accumulator
   - `process_item`: filter for `type == "feature_batch"`, parse markdown, accumulate entries
   - `close_spider`: build features, write `parsed-changelog.jsonl` + `features-index.json`

### Phase 3: TypeScript Zod Schemas

**New file (1):**

8. **`packages/scrapy-cli/src/primitives/feature.ts`**
   - `ChangelogSource`, `FeatureCategory`, `ActionRequired` enums
   - `ChangelogEntry`, `FeatureRecord`, `SdkParity`, `FeaturesIndex` Zod objects
   - Type exports via `z.infer`

### Phase 4: Integration Wiring

**Modified files (5):**

9. **`crawler/pipelines/__init__.py`** — add `FeatureExtractionPipeline` to barrel
10. **`crawler/settings.py`** — add pipeline at 600, add `FEATURES_INDEX_PATH` + `PARSED_CHANGELOG_PATH` constants
11. **`crawler/run.py`** — add `changelog` command (runs spider), `features` command (shows summary), add spider to `all`
12. **`packages/scrapy-cli/src/primitives/index.ts`** — re-export feature.ts
13. **`package.json`** — add `crawl:changelog` and `crawl:features` scripts

### Phase 5: Context + Skill

**New files (2):**

14. **`crawler/context/changelog-sources.xml`** — source context following existing pattern
15. **`skills/feature-library/SKILL.md`** — skill for querying feature index

---

## File Summary

| # | File | Op | Lines |
|---|------|-----|-------|
| 1 | `crawler/parsers/__init__.py` | NEW | ~1 |
| 2 | `crawler/parsers/models.py` | NEW | ~60 |
| 3 | `crawler/parsers/extractor.py` | NEW | ~120 |
| 4 | `crawler/parsers/changelog_parser.py` | NEW | ~150 |
| 5 | `crawler/parsers/feature_builder.py` | NEW | ~80 |
| 6 | `crawler/spiders/changelog_sources.py` | NEW | ~90 |
| 7 | `crawler/pipelines/feature_extraction.py` | NEW | ~50 |
| 8 | `packages/scrapy-cli/src/primitives/feature.ts` | NEW | ~85 |
| 9 | `crawler/pipelines/__init__.py` | EDIT | +2 |
| 10 | `crawler/settings.py` | EDIT | +4 |
| 11 | `crawler/run.py` | EDIT | +25 |
| 12 | `packages/scrapy-cli/src/primitives/index.ts` | EDIT | +7 |
| 13 | `package.json` | EDIT | +2 |
| 14 | `crawler/context/changelog-sources.xml` | NEW | ~20 |
| 15 | `skills/feature-library/SKILL.md` | NEW | ~30 |

**Total: 10 new files, 5 edits. ~700 lines.**

---

## Execution Order

1. `models.py` — types first
2. `extractor.py` — regex patterns (depends on models)
3. `changelog_parser.py` — parsers (depends on models + extractor)
4. `feature_builder.py` — aggregation (depends on models)
5. `feature_extraction.py` — pipeline (depends on parsers)
6. `changelog_sources.py` — spider (depends on pipeline)
7. `feature.ts` — Zod schemas (independent, can parallel with Python)
8. Wiring edits (pipelines init, settings, run.py, primitives index, package.json)
9. Context XML + skill
10. Verify

---

## Verification

```bash
# 1. Python type check
pyright crawler/parsers/

# 2. Lint
ruff check crawler/parsers/ crawler/spiders/changelog_sources.py crawler/pipelines/feature_extraction.py

# 3. Run spider (creates indexes/)
python -m crawler.run changelog

# 4. Check outputs exist
ls -la crawler/indexes/parsed-changelog.jsonl crawler/indexes/features-index.json

# 5. Show feature summary
python -m crawler.run features

# 6. TypeScript compile
cd packages/scrapy-cli && npx tsc --noEmit

# 7. Zod round-trip validation
npx tsx -e "
import { FeaturesIndex } from './src/primitives/feature.js';
import { readFileSync } from 'fs';
const raw = JSON.parse(readFileSync('../../crawler/indexes/features-index.json', 'utf-8'));
const result = FeaturesIndex.safeParse(raw);
console.log(result.success ? 'Valid' : result.error.issues);
"
```

---

## Key Decisions

- **Dataclasses over Pydantic** — existing codebase has zero Pydantic; smallest diff
- **No vendor directory** — doesn't exist yet; spider fetches live, RFC2616 cache handles 304s
- **`feature_batch` item type** — accumulate all entries before building features (needs global sort for `introduced_version`)
- **Separate spider** — `claude_docs.py` crawls all 84 doc pages via llms.txt; changelog is a distinct concern
- **Hook regex uses known names** — extensible list, not a generic PascalCase match (avoids false positives on class names)
