---
name: bitrix-components
description: "Bitrix components: class.php, templates, cache, SEF, Controllerable AJAX. Use when building or editing components."
---

# Bitrix Components

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

Progressive disclosure: open **only** the rule files that match the task. Do not read every `rules/*.md`.

## How to use

1. Identify the layer the task touches.
2. Open the matching `rules/*.md` below.
3. Prefer framework-native Bitrix patterns over custom abstractions.


## Choose a rule file

### When to read `rules/structure.md`

Read `rules/structure.md` (`Placement and structure`) when the task involves:

- Where to Place
- Folder Structure
- `class.php` — Minimum
- Usage
- `$arParams` and `$arResult`
- `.description.php`
- `.parameters.php`

### When to read `rules/template.md`

Read `rules/template.md` (`Templates and epilog`) when the task involves:

- Template
- `result_modifier.php`
- `component_epilog.php`

### When to read `rules/cache-sef-ajax.md`

Read `rules/cache-sef-ajax.md` (`Cache, SEF, AJAX`) when the task involves:

- Caching Details
- SEF (Search-Friendly URLs)
- Controllerable and AJAX
- Checklist

## Checklist

- [ ] Opened only the rule file(s) needed for this task.
- [ ] Followed DI / `/local/` / security canons from `AGENTS.md`.
