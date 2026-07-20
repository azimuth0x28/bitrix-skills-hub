# CLI and config

## Resolve module path

The module may be installed in **either** place:

1. `/local/modules/sprint.migration/` — prefer this if `include.php` exists there
2. `/bitrix/modules/sprint.migration/` — fallback

```bash
# from document root
if [ -f local/modules/sprint.migration/tools/migrate.php ]; then
  MIGRATE=local/modules/sprint.migration/tools/migrate.php
else
  MIGRATE=bitrix/modules/sprint.migration/tools/migrate.php
fi

php "$MIGRATE" <command> [args] [options]
```

In docs below, **`{migrate}`** = that `tools/migrate.php` path.
Optional thin wrapper in project root (e.g. `bin/migrate`) that sets
`DOCUMENT_ROOT` and requires `{module}/tools/migrate.php`.

Symfony: `php bin/console sprint:migration` when the SprintMigration bundle /
console command is registered.

CLI refuses non-CLI SAPI. It bootstraps Bitrix via `prolog_before.php`.

## Essential commands

Full list: module files `commands.txt` (RU) / `commands-en.txt` under `{module}/`.

| Command | Purpose |
| --- | --- |
| `add [desc] [name]` | Scaffold blank migration (`--desc`, `--name`) |
| `ls` | List (`--new`, `--installed`, `--search=`, `--tag=`) |
| `up` / `up [version]` | Apply all new or one version (`--search=`, `--add-tag=`) |
| `down` / `down [version]` | Rollback |
| `redo [version]` | `down` then `up` for one version |
| `run [builder]` | Interactive/export builder (admin-oriented; CLI supported) |
| `mark [version\|new\|installed\|unknown] --as=installed\|new` | Change status **without** running code |
| `delete …` | Remove migration records/files (destructive — confirm intent) |
| `config` | Show active config; `--config=[name]` switches config |

Examples (after resolving `$MIGRATE` / `{migrate}`):

```bash
php "$MIGRATE" add "Add news iblock" NewsIblock
php "$MIGRATE" ls --new
php "$MIGRATE" up
php "$MIGRATE" up Version20240722144938
php "$MIGRATE" down Version20240722144938
php "$MIGRATE" redo Version20240722144938
php "$MIGRATE" mark Version20240722144938 --as=installed
php "$MIGRATE" --config=shop up
```

Prefer **`add`** (or admin builders) over inventing filenames by hand. Hand-copied
classes often break timestamp/name validation.

## Version naming

- Must be a valid PHP class name: `^[a-zA-Z_][a-zA-Z0-9_]*$`.
- Must contain a timestamp matching config `version_timestamp_format`
  (default `YmdHis`, pattern like `20\d{12}`).
- Default template: `#NAME##TIMESTAMP#` → e.g. `Version20260720113800` or
  `NewsIblock20260720113800`.
- Class name **equals** file basename without `.php`.
- Namespace: `Sprint\Migration`.

## Configs

Default config is built-in (empty overrides → module defaults).

Additional configs: files in php_interface (`local/php_interface` if that
directory exists, else `bitrix/php_interface`):

```
{php_interface}/migrations.<name>.php
```

Must `return` an array. Typical keys:

```php
<?php

return [
    'title' => 'Shop migrations',
    // path relative to docroot unless migration_dir_absolute is set
    'migration_dir' => '/local/php_interface/migrations.shop',
    'migration_table' => 'sprint_migration_shop',
    'version_prefix' => 'Version',
    'exchange_dir' => '/local/php_interface/migrations.shop',
    // 'console_user' => 'admin' | false | 'login:someuser',
    // 'migration_extend_class' => 'Version',
    // 'version_builders' => [...],
];
```

Use `/bitrix/php_interface/...` in `migration_dir` / `exchange_dir` when the
project has no `local/php_interface`.

Custom config directories can also be registered via module event
`OnSearchConfigFiles` (returns a directory path with `migrations.*.php` files).

Show / switch: `config`, `--config=[name]`.

## Console user and events

Defaults (unless overridden):

- `console_user` = `admin` (migrations run as that user in CLI).
- `console_auth_events_disable` = `true` (auth events skipped in console).

Set `console_user` to `false` to run without authorizing a user when the change
must not depend on admin context.

## Admin UI

Module admin page can create migrations, run builders, and apply `up`/`down`.
Same files and status table as CLI. Prefer CLI in automation scripts.
