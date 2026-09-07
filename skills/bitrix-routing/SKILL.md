---
name: bitrix-routing
description: Use for public/API URLs. RoutingConfigurator, /local/routes, PublicPageController, site-guard, urlrewrite migration.
---

# Routing in Bitrix

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

Progressive disclosure: open **only** the rule files that match the task. Do not read every `rules/*.md`.

## How to use

1. Identify the layer the task touches.
2. Open the matching `rules/*.md` below.
3. Prefer framework-native Bitrix patterns over custom abstractions.

## Routing style: check the project first

New-style routing is recommended for new projects; most existing projects still route through `urlrewrite.php`. Before registering routes or touching the `routing` config section, determine the project's active routing: web-server rewrite target (`urlrewrite.php` vs `routing_index.php`) and presence of `/local/routes/`. On a legacy project follow its existing style or migrate explicitly — do not force new routing onto it. Migration → `rules/matching-legacy.md`.

## Choose a rule file

### When to read `rules/setup.md`

Read `rules/setup.md` (`Enable routing and module wiring`) when the task involves:

- Enabling New Routing

### When to read `rules/routes-handlers.md`

Read `rules/routes-handlers.md` (`Routes, handlers, params, groups`) when the task involves:

- Basic `web.php`
- Supported Methods
- Handlers
- Route Parameters
- Names and URL Generation
- Groups (fluent API)
- Delivering view / component

### When to read `rules/matching-legacy.md`

Read `rules/matching-legacy.md` (`Matching, PublicPageController, site-guard`) when the task involves:

- Matching and safety
- PublicPageController (legacy bridge)
- Site-guard (multisite)
- Migration from `urlrewrite.php`
- Checklist

## Checklist

- [ ] Opened only the rule file(s) needed for this task.
- [ ] Followed DI / `/local/` / security canons from `AGENTS.md`.
