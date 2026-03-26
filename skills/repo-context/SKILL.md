---
name: repo-context
description: >
  Loads context from GitHub repos by reading standard files (CLAUDE.md, README.md, AGENTS.md,
  CONTRIBUTING.md, CHANGELOG.md). Use when encountering a new repo, cloning a repo, starting
  work in a repo, or onboarding a new crawler source. Saves time by extracting repo conventions,
  architecture, and contribution patterns before writing code or creating spiders.
---

# repo-context

Extracts structured context from GitHub repos by reading their standard documentation files.

## When to Use

- Cloning or entering a new GitHub repo for the first time
- Before creating a spider for a new documentation source
- Before contributing to or modifying vendored repos
- When onboarding a new repo into the jadecli-ecosystem

## Files to Check (in priority order)

| File | What to Extract |
|------|----------------|
| `CLAUDE.md` | Agent instructions, tool restrictions, coding conventions, project structure |
| `README.md` | Purpose, architecture, setup, dependencies, API overview |
| `AGENTS.md` | Available agents, their roles, tool access, delegation patterns |
| `CONTRIBUTING.md` | PR conventions, commit style, testing requirements, review process |
| `CHANGELOG.md` | Recent changes, version history, breaking changes |
| `.claude-plugin/plugin.json` | Plugin manifest if it's a Claude Code plugin |
| `pyproject.toml` / `package.json` | Dependencies, scripts, versions |

## Workflow

1. For a GitHub repo URL or local path, read each file if it exists
2. Extract key facts into a structured summary
3. Save context to `crawler/context/<source>.xml` with the enhanced metadata fields
4. Use the context to inform spider creation, contribution, or integration

## Command

```bash
# For a GitHub repo (uses gh api)
gh api repos/{owner}/{repo}/contents/CLAUDE.md --jq '.content' | base64 -d
gh api repos/{owner}/{repo}/contents/README.md --jq '.content' | base64 -d

# For a local clone
cat CLAUDE.md README.md AGENTS.md CONTRIBUTING.md CHANGELOG.md 2>/dev/null
```

## Enhanced Context Metadata

When documenting a crawler source, include these optional fields in the context XML:

```xml
<crawler-context source="example_docs" last-updated="2026-03-25">
  <source>
    <!-- Required -->
    <name>...</name>
    <index-url>...</index-url>
    <page-count>N</page-count>

    <!-- Optional: repo context -->
    <github-org>owner</github-org>
    <github-repo>owner/repo</github-repo>
    <repo-files checked="CLAUDE.md,README.md,AGENTS.md">
      <claude-md>summary of agent instructions</claude-md>
      <readme>summary of purpose and architecture</readme>
    </repo-files>

    <!-- Optional: ecosystem context -->
    <plugin name="..." marketplace="...">description</plugin>
    <skills>
      <skill name="..." source="..."/>
    </skills>
    <documentation>
      <doc url="..." type="api-spec|guide|reference">description</doc>
    </documentation>
    <related-repos>
      <repo name="owner/repo" stars="N">why it's relevant</repo>
    </related-repos>
  </source>
</crawler-context>
```
