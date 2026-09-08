---
name: bitrix-orm
description: "Use when designing D7 ORM entities, reading or persisting data via tablets, or choosing between DataManager and *Table classes. Covers D7 ORM — tablet map, field types, relations, user fields, ConditionTree queries, Objectify, batch/merge/deleteByFilter writes, events, cache. Key terms — DataManager, Tablet, ConditionTree, Objectify, deleteByFilter, addBatch."
metadata:
  type: knowledge
---

# Bitrix D7 ORM

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

Progressive disclosure: open **only** the rule files that match the task. Do not read every `rules/*.md`.

## How to use

1. Identify the layer the task touches.
2. Open the matching `rules/*.md` below.
3. Prefer framework-native Bitrix patterns over custom abstractions.


## Choose a rule file

### When to read `rules/tablet-map.md`

Read `rules/tablet-map.md` (`Tablet map`) when the task involves:

- Naming: `DataManager` vs `*Table`
- Tablet Skeleton
- Field Types
- Relations
- User Fields (UF)

### When to read `rules/reading.md`

Read `rules/reading.md` (`Reading / filters`) when the task involves:

- Reading Data
- Collections and Annotations

### When to read `rules/writing.md`

Read `rules/writing.md` (`Writing / batch / upsert`) when the task involves:

- Writing

### When to read `rules/events-cache-security.md`

Read `rules/events-cache-security.md` (`Events, cache, security`) when the task involves:

- Events
- Caching
- Security: User Input in Queries
- Checklist

## Checklist

- [ ] Opened only the rule file(s) needed for this task.
- [ ] Followed DI / `/local/` / security canons from `AGENTS.md`.
