---
name: dotfile-audit
description: >
  Audits dotfiles on the local device against the documented inventory.
  Use when checking for drift between documented configs and actual disk state,
  finding unused configs to clean up, or verifying dotfile changes after migration.
  Reads shared/context/dotfiles.xml and shared/context/change-plan.xml as references.
---

# dotfile-audit

Compares actual dotfile state against the documented inventory and change plan.

## References

- Inventory: `/Users/alexzh/jadecli-ecosystem/shared/context/dotfiles.xml`
- Change plan: `/Users/alexzh/jadecli-ecosystem/shared/context/change-plan.xml`
- Dotfile manager: chezmoi (source: `~/repos/dotfiles/`)

## Audit Steps

1. Read `dotfiles.xml` for the expected inventory
2. Read `change-plan.xml` for pending changes
3. Check each documented path exists and matches expected state
4. Report drift: new files not in inventory, missing files, size changes
5. Flag broken symlinks (mise config, toad config)

## Status Enum

- `rm-now` — approved for immediate removal
- `rm-after-backup` — remove after backup (or without, if approved)
- `keep` — do not touch
- `modify` — needs changes, see action field
- `defer` — revisit later
- `review` — user must decide
