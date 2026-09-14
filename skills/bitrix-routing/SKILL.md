---
name: bitrix-routing
description: "Use when adding public or API URLs to a project, migrating legacy urlrewrite rules, or detecting CRM pages (kanban, detail, smart-process URLs). Covers routing setup and wiring, web.php routes/handlers, groups, URL generation, PublicPageController, site-guard, urlrewrite migration, CRM Router custom sections. Key terms — RoutingConfigurator, /local/routes, getCustomRoots, matchPage, /page/."
metadata:
  type: knowledge
  version: "1.1.0"
---

# Routing in Bitrix

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

## How to use

1. Identify the layer the task touches; open **only** the matching `rules/*.md` below — never every file.
2. Check the project's active routing first (`urlrewrite.php` vs `routing_index.php`, presence of `/local/routes/`); on a legacy project follow its style or migrate explicitly (`rules/matching-legacy.md`).

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

### When to read `rules/crm-pages.md`

Read `rules/crm-pages.md` (`CRM page URLs and detection`) when the task involves:

- URL structure: standard `/crm/` roots
- Custom sections (`/page/`)
- Detecting the current page
- OnProlog asset injection pattern
- Checklist

## Checklist

- [ ] Opened only the rule file(s) needed for this task; followed DI / `/local/` / security canons from `AGENTS.md`; forced the project's active routing style, legacy migrated explicitly.
