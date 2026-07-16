---
name: bitrix-iblocks
description: Iblock types/elements/sections, ORM compileEntity, properties, SEO templates. Use for content iblock work.
---

# Information Blocks (`iblock`)

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

Progressive disclosure: open **only** the rule files that match the task. Do not read every `rules/*.md`.

## How to use

1. Identify the layer the task touches.
2. Open the matching `rules/*.md` below.
3. Prefer framework-native Bitrix patterns over custom abstractions.


## Choose a rule file

### When to read `rules/basics.md`

Read `rules/basics.md` (`Hierarchy, IDs, API boundary`) when the task involves:

- Hierarchy
- Key Identifiers
- Where ORM / Classic API Boundary Lies
- Compiling ORM Classes
- Creating an Iblock Programmatically
- Rights and Public API

### When to read `rules/properties-sections-elements.md`

Read `rules/properties-sections-elements.md` (`Properties, sections, elements`) when the task involves:

- Properties
- Sections via ORM
- Elements via ORM

### When to read `rules/query-seo-perf.md`

Read `rules/query-seo-perf.md` (`Selections, SEO, performance`) when the task involves:

- Selections and Filters
- SEO Templates
- Checklist
- Performance

## Checklist

- [ ] Opened only the rule file(s) needed for this task.
- [ ] Followed DI / `/local/` / security canons from `AGENTS.md`.
