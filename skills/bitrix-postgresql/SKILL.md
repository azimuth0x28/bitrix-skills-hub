---
name: bitrix-postgresql
description: Covers PostgreSQL support in Bitrix — PgsqlConnection, migration from MySQL, compatible code, module support matrix. Applied when configuring or migrating to PostgreSQL Enterprise editions. Key terms — PostgreSQL, PgsqlConnection, migration, compatible-code.
---

# PostgreSQL in Bitrix

Baseline: **main 23.0+**. Supported in **Enterprise for PostgreSQL** licenses (B24 and CMS). Connection class: `\Bitrix\Main\DB\PgsqlConnection`.

## Configuration

```php
'connections' => [
    'value' => [
        'default' => [
            'className' => \Bitrix\Main\DB\PgsqlConnection::class,
            'host' => 'localhost',
            'database' => 'bx',
            'login' => 'bx',
            'password' => '***',
            'options' => \Bitrix\Main\DB\Connection::DEFERRED,
        ],
    ],
    'readonly' => true,
],
```

## Before Migration

1. Check that the **current** license stays valid through the whole test period (up to 6 months) and the final switch — renew it first if it expires earlier.
2. Obtain Enterprise for PostgreSQL license. It provides a coupon (activate it only **after** migration testing) and a test key for a separate test install; testing window is max 6 months from purchase. During testing the production site keeps running on MySQL under the current license — the test key is for the test environment only.
3. Update **Performance Monitor** module to 24.0.0+.
4. Project must use UTF-8 encoding.
5. Close site to visitors during migration.
6. Test on staging first — **return to MySQL after production PostgreSQL launch requires manual work**.

## Module Compatibility

Not all kernel and marketplace modules support PostgreSQL. Incompatible modules are disabled during conversion wizard.

Check custom code:
- MySQL-specific SQL (`LIMIT` syntax differences handled by SqlHelper, but raw SQL may break).
- MySQL install scripts under `install/mysql/` or `install/db/mysql/` need matching PostgreSQL scripts under `install/pgsql/` or `install/db/pgsql/`.

Find modules missing pgsql install:

```bash
for mysql in bitrix/modules/*/install/mysql/install.sql bitrix/modules/*/install/db/mysql/install.sql; do
  pgsql=$(echo $mysql | sed 's#/mysql/#/pgsql/#')
  test -e $pgsql || echo "missing: $pgsql"
done
```

Check kernel module install folders: each supporting module should have matching `install/pgsql/` **or** `install/db/pgsql/` scripts. Inspect `bitrix/modules/<module>/install/` in the project.

## Migration Methods

1. **Wizard** — Admin conversion tool (lists disabled modules on step 1).
2. **CLI** — manual server-side migration via Performance Monitor module tools.

## Writing Compatible Code

- Use ORM and `SqlHelper` — avoid MySQL-specific functions in raw SQL.
- Use `SqlExpression` placeholders instead of string concatenation.
- Test DDL in both MySQL (`install/mysql/` or `install/db/mysql/`) and PostgreSQL (`install/pgsql/` or `install/db/pgsql/`) if the module supports both.
- Avoid `ENGINE=InnoDB`, backticks-specific syntax, `UNSIGNED`.

## Checklist

- [ ] License is Enterprise for PostgreSQL.
- [ ] All custom modules checked for pgsql install scripts.
- [ ] Raw SQL audited for MySQL-specific syntax.
- [ ] Migration tested on copy before production.
- [ ] Marketplace modules verified with vendors.
