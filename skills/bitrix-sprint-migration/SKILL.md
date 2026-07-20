---
name: bitrix-sprint-migration
description: >-
  Covers Bitrix module sprint.migration — Version migrations, HelperManager
  (Iblock/Hlblock/Option/Agent/…), builders (run), CLI migrate.php
  (add/ls/up/down/redo/mark), configs migrations.*.php, restartable batches,
  exchange dirs. Use when creating or applying DB/schema/content migrations,
  exporting iblock/HL/options via builders, or debugging migration state.
  Key terms — sprint.migration, Version, up/down, HelperManager, saveIblock,
  saveHlblock, migrate.php, version builders, migration_dir.
---

# Bitrix sprint.migration

Module **`sprint.migration`** (Composer: `andreyryabin/sprint.migration`) stores
schema/content changes as PHP classes under VCS and applies them on each copy
of the project via CLI or admin UI.

Install location (either is valid; resolve before calling CLI):

| Path | Typical when |
| --- | --- |
| `/local/modules/sprint.migration/` | Composer / marketplace into `local` |
| `/bitrix/modules/sprint.migration/` | Marketplace / copy into kernel modules |

Below, **`{module}`** means that resolved directory. Do **not** edit module
source. Write only migration files and optional configs (usually under
`php_interface/`).

Progressive disclosure: open **only** the rule files that match the task.

## How to use

1. Confirm the module is installed (`Loader::includeModule('sprint.migration')`).
2. Identify the layer (CLI/config vs writing a Version vs helpers/builders).
3. Open the matching `rules/*.md` below.
4. Prefer helpers/`save*` APIs over raw Bitrix API when they cover the entity.
5. For domain ORM/data updates without builders — use D7/`Result` inside `up()`,
   still as a `Version` class.

Official wiki: https://github.com/andreyryabin/sprint.migration/wiki

## Defaults (override via `migrations.*.php` / module options)

| Item | Default |
| --- | --- |
| Migration dir | `{local\|bitrix}/php_interface/migrations` (`local` wins if present) |
| Versions table | `sprint_migration_versions` |
| Class prefix | `Version` + timestamp `YmdHis` (name must contain a valid timestamp) |
| Extend class | `Sprint\Migration\Version` |
| CLI entry | `php {module}/tools/migrate.php` |
| Extra configs | `{local\|bitrix}/php_interface/migrations.<name>.php` → dir `migrations.<name>`, table `sprint_migration_<name>` |

## Choose a rule file

### When to read `rules/cli-config.md`

Read when the task involves:

- Running CLI (`add`, `ls`, `up`, `down`, `redo`, `mark`, `run`, `config`)
- Naming versions / timestamps
- Multiple configs (`--config`, `migrations.*.php`)
- Admin UI vs console auth user

### When to read `rules/writing.md`

Read when the task involves:

- Authoring `Version` (`up` / `down`)
- Idempotent `save*` vs `add*IfNotExists`
- Output (`outSuccess` / `outError`), return `false` on failure
- Dependencies (`checkRequiredVersions`)
- Restartable long migrations
- Exchange files / large data sets
- Hand-written data migrations (ORM / SQL)

### When to read `rules/helpers-builders.md`

Read when the task involves:

- Choosing a Helper (`Iblock()`, `Hlblock()`, …)
- Choosing a Builder (`run IblockBuilder`, …)
- Export-from-admin → commit generated PHP

### When to read `rules/checklist.md`

Read before finishing or reviewing a migration change:

- Safety / anti-patterns
- Apply / verify checklist

## Related skills

| Need | Skill |
| --- | --- |
| Iblock domain model | `bitrix-iblocks` |
| Highloadblock CRUD | `bitrix-highloadblock` |
| Raw SQL / DDL outside helpers | `bitrix-database` |
| Module install SQL (not sprint) | `bitrix-modules` |
| Agents registration | `bitrix-background-jobs` |
| Options / storage choice | `bitrix-storage` |

## Checklist

- [ ] Opened only the rule file(s) needed for this task.
- [ ] Migration files live under the configured `migration_dir` (not in the module).
- [ ] Did not modify sprint.migration module source.
- [ ] Applied `up` on a local/dev copy when verifying the change.
