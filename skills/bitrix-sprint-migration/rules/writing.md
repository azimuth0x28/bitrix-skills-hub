# Writing Version migrations

## Skeleton

```php
<?php

namespace Sprint\Migration;

class Version20260720120000 extends Version
{
    protected $author = '';
    protected $description = 'Short human summary of the change';
    protected $moduleVersion = '5.13.0'; // module version that generated the file (informational)

    public function up()
    {
        $helper = $this->getHelperManager();
        // apply changes
    }

    public function down()
    {
        $helper = $this->getHelperManager();
        // reverse changes when safe/possible
    }
}
```

Scaffold via CLI `add` or admin builder — then fill `up`/`down`.

## Contract of `up` / `down`

| Return / behavior | Meaning |
| --- | --- |
| `void` / `true` / no return | Success (default) |
| `false` | Failure — migration stays not installed |
| Throw `HelperException` / `MigrationException` | Failure with message |
| Throw `RestartException` (via `$this->restart*`) | Pause and resume (long jobs) |

Use `$this->outSuccess()`, `$this->outError()`, `$this->outWarning()`,
`$this->outProgress($msg, $val, $total)` for operator-visible logs.

## Prefer idempotent helpers

Naming convention in helpers:

| Pattern | Behavior |
| --- | --- |
| `saveX(...)` | Create or update to match given fields (preferred for schema) |
| `addXIfNotExists(...)` | Create only if missing |
| `deleteXIfExists(...)` | Delete only if present |
| `getXIfExists(...)` | Fetch or throw / fail clearly |

Example (iblock):

```php
public function up()
{
    $helper = $this->getHelperManager();

    $helper->Iblock()->saveIblockType([
        'ID' => 'content',
        'LANG' => [
            'ru' => [
                'NAME' => 'Контент',
                'SECTION_NAME' => 'Разделы',
                'ELEMENT_NAME' => 'Элементы',
            ],
        ],
    ]);

    $iblockId = $helper->Iblock()->saveIblock([
        'NAME' => 'Новости',
        'CODE' => 'content_news',
        'LID' => ['s1'],
        'IBLOCK_TYPE_ID' => 'content',
    ]);

    $helper->Iblock()->saveProperty($iblockId, [
        'NAME' => 'Ссылка',
        'CODE' => 'LINK',
    ]);
}

public function down()
{
    $this->getHelperManager()->Iblock()->deleteIblockIfExists('content_news');
}
```

## Dependencies between migrations

```php
public function up()
{
    $this->checkRequiredVersions([
        'Version20260101120000',
        OtherMigration::class,
    ]);
    // ...
}
```

`$requiredVersions` property is **deprecated** — use `checkRequiredVersions()`.

## Restartable (batch) migrations

For large loops, use restart helpers so CLI/admin can continue without timeout:

```php
public function up()
{
    $items = $this->loadItems(); // or from exchange

    $this->restartIterator('items', $items, function (array $row) {
        // process one row
        $this->outProgress('rows', /* current */, count($this->loadItems()));
    });
}
```

Also available: `restartOnce($name, $callback)`, `restartWhile($name, $callback)`.
Storage of restart params is managed by the module between invocations.

## Exchange / files next to a version

Large exported data (elements, files) lives under:

`{exchange_dir}/{VersionName}_files/`

Access via `$this->getExchangeManager()`. Prefer builders
(`IblockElementsBuilder`, `HlblockElementsBuilder`, …) over hand-rolling exchange
format. Do not commit secrets or huge binary dumps without an explicit project
policy.

## Hand-written data migrations

When helpers do not cover the entity (custom ORM tablet, business data):

1. `Loader::includeModule('vendor.module')` first; fail with `outError` + `return false` if missing.
2. Prefer D7 ORM / ServiceLocator services over classic API.
3. Check `Result::isSuccess()`; aggregate errors with `outError`.
4. Keep migrations **deterministic** and **re-runnable** where possible (match by
   business key / XML_ID / CODE, not by auto-increment ID).
5. Cast IDs and codes strictly (`(int)`, whitelist filters).

```php
public function up()
{
    if (!\Bitrix\Main\Loader::includeModule('vendor.module')) {
        $this->outError('Module vendor.module is not installed');
        return false;
    }

    $result = \Vendor\Module\Entity\ItemTable::add([/* ... */]);
    if (!$result->isSuccess()) {
        $this->outError(implode('; ', $result->getErrorMessages()));
        return false;
    }

    $this->outSuccess('Item created');
}
```

Raw SQL: only when ORM/helpers cannot express the change — see `bitrix-database`.
Escape via `SqlHelper`; wrap multi-step DDL/DML in a transaction when safe.

## `down()` policy

- Schema created in `up` → delete/revert in `down` when practical.
- One-way data fixes (external registry sync, irreversible transforms) → empty
  `down()` with a short comment why rollback is impossible.
- Never invent destructive `down()` that drops production data “for symmetry”
  without an explicit requirement.

## What not to put in migrations

- Secrets, tokens, `.env` values, private keys.
- Hard-coded absolute host paths of a single developer machine.
- Edits to `/bitrix/` core files.
- Non-deterministic “random” seeds that break replay on another copy.
