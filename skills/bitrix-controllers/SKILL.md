---
name: bitrix-controllers
description: Engine Controller/JsonController: thin actions, filter attributes, CurrentUser, errors. Use for AJAX/REST/routed endpoints.
---

# Bitrix Controllers

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

Progressive disclosure: open **only** the rule files that match the task. Do not read every `rules/*.md`.

## How to use

1. Identify the layer the task touches.
2. Open the matching `rules/*.md` below.
3. Prefer framework-native Bitrix patterns over custom abstractions.


## Choose a rule file

### When to read `rules/basics.md`

Read `rules/basics.md` (`Location, thin controller, autowire`) when the task involves:

- Location and Naming
- Minimal Controller
- Action Parameter Autowiring
- Controller Lifecycle
- Additional Autowire Types
- Front-end Call

### When to read `rules/filters.md`

Read `rules/filters.md` (`Filters and attributes`) when the task involves:

- Default Prefilters
- Action Filters
- PHP 8 Attribute Filters (preferred)

### When to read `rules/errors-response.md`

Read `rules/errors-response.md` (`Errors, responses, scope`) when the task involves:

- Errors
- Response Types
- Scope (AJAX / REST / CLI)
- Checklist

## Checklist

- [ ] Opened only the rule file(s) needed for this task.
- [ ] Followed DI / `/local/` / security canons from `AGENTS.md`.
