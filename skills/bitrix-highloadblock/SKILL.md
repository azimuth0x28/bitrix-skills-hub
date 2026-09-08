---
name: bitrix-highloadblock
description: "Use when storing dynamic data in highload blocks, or when adding user fields to them. Covers Highloadblock module — HighloadBlockTable manage API, compileEntity() and dynamic DataManager CRUD, user fields (HLBLOCK_{id}), directory property (UF_XML_ID), ORM events, rights (hl_element_*). Key terms — HighloadBlockTable, compileEntity, DataManager, HLBLOCK_, UF_XML_ID."
metadata:
  type: knowledge
---

# Highload Blocks (`highloadblock`)

Highload blocks (HL) are ORM-backed flat tables whose columns are **user fields** (`UF_*`). No sections/tree, no iblock SEO model. The name does not guarantee performance — it depends on fields, indexes, filters and volume.

```php
\Bitrix\Main\Loader::includeModule('highloadblock'); // always before API use
```

## When HL vs Iblock vs Custom Tablet

| Need | Prefer |
| --- | --- |
| Flat dictionary / reference list, admin-editable UF structure, iblock "directory" source | **Highload block** |
| Sections, SEO, properties, public content UX | **Iblock** (`bitrix-iblocks`) |
| Schema fully owned by code, migrations, typed checks | **Custom ORM tablet** (`bitrix-orm`) |

## Core Concepts

| Term | Meaning |
| --- | --- |
| HL block | Description row: `ID`, `NAME`, `TABLE_NAME` (+ computed `FIELDS_COUNT`, `LANG` reference) |
| Fields | User fields with `ENTITY_ID = HLBLOCK_{id}` (`HighloadBlockTable::compileEntityId($id)`) |
| Data class | Runtime class `\{NAME}Table` (global ns) extending `Bitrix\Highloadblock\DataManager` |
| Lang names | `HighloadBlockLangTable`, composite PK `ID` + `LID` (≤ 2 chars) |
| Rights | `HighloadBlockRightsTable` (`HL_ID`, `TASK_ID`, `ACCESS_CODE`) |

Naming rules: `NAME` — starts with capital Latin letter, Latin letters/digits only, ≤ 100 chars, must not end with `Table` and must not be `Collection`; `TABLE_NAME` — lowercase Latin/digits/underscore, ≤ 64 chars; both unique (table must not pre-exist). UF codes ending `_REF` are rejected (reserved for ORM references).

## Manage HL Blocks

```php
<?php declare(strict_types=1);

use Bitrix\Highloadblock\HighloadBlockTable;
use Bitrix\Main\Loader;

Loader::includeModule('highloadblock');

// Idempotent create: look up by stable NAME first
$hl = HighloadBlockTable::getList([
    'select' => ['ID'], 'filter' => ['=NAME' => 'ProductColor'], 'limit' => 1,
])->fetch();

if (!$hl) {
    $result = HighloadBlockTable::add(['NAME' => 'ProductColor', 'TABLE_NAME' => 'product_color']);
    if (!$result->isSuccess()) {
        throw new \RuntimeException(implode('; ', $result->getErrorMessages()));
    }
    $hlId = (int)$result->getId(); // table with ID column created; rolled back on failure
} else {
    $hlId = (int)$hl['ID'];
}
```

- `getList` extras: `FIELDS_COUNT`, `'LANG_NAME' => 'LANG.NAME'` (current-language title).
- `update($id, [...])`: changing `NAME` affects the class name on next compile; changing `TABLE_NAME` physically renames the table + multiple-value storages. Finish the request, recompile in a **new request**.
- `delete($id)`: removes description, records, UFs, files, lang names, rights, tables. Irreversible — backup first.
- Structure ops are multi-step and not transactional: check every `Result`, never run the same migration concurrently.
- Lang titles: `HighloadBlockLangTable::add/update` with primary `['ID' => $hlId, 'LID' => 'ru']`.

## User Fields

Attach via `CUserTypeEntity` with `ENTITY_ID = HLBLOCK_{id}`. Key params: `FIELD_NAME` (`UF_` prefix, uppercase Latin/digits/`_`, 4–50 chars), `USER_TYPE_ID` (`string`, `integer`, `boolean`, `file`, `enumeration`, `hlblock`, …), `MULTIPLE`/`MANDATORY` (`Y|N`, default `N`), `SORT`, `SETTINGS`, `EDIT_FORM_LABEL`/`LIST_COLUMN_LABEL`/`LIST_FILTER_LABEL`, `SHOW_FILTER` (`N|I|E|S` — hide / exact / mask / substring).

```php
$entityId = HighloadBlockTable::compileEntityId($hlId); // 'HLBLOCK_7'
$exists = \CUserTypeEntity::GetList([], ['ENTITY_ID' => $entityId, 'FIELD_NAME' => 'UF_NAME'])->Fetch();
if (!$exists) {
    $fieldId = (new \CUserTypeEntity())->Add([
        'ENTITY_ID' => $entityId, 'FIELD_NAME' => 'UF_NAME',
        'USER_TYPE_ID' => 'string', 'MANDATORY' => 'Y',
    ]);
    if (!$fieldId) { /* $APPLICATION->GetException()?->GetString() */ }
}
```

- `Update()` cannot change `ENTITY_ID`, `FIELD_NAME`, `USER_TYPE_ID`, `MULTIPLE` — create new field, migrate values, delete old. Label updates replace all stored labels.
- `Delete()` removes value storage; file fields delete their files (block delete too).
- Multiple field → extra value storage synced by `DataManager`; never touch it (or the main table) with raw SQL.

**Recompile rules.** First `compileEntity()` per request builds the PHP class; repeated calls return it. After UF changes, prefer a **new request**; to continue in the same request re-fetch the block and call `compileEntity($hlblock, true)` (rebuilds ORM map but does NOT redefine the loaded PHP class), then verify via `$entity->hasField('UF_X')`. `NAME`/`TABLE_NAME` changes always need a new request.

## Records CRUD

`compileEntity($hlblock)` accepts array, ID, or NAME; returns `Bitrix\Main\ORM\Entity`. Compile once per request.

```php
<?php declare(strict_types=1);

use Bitrix\Highloadblock\HighloadBlockTable;
use Bitrix\Main\Loader;

Loader::includeModule('highloadblock');

$entity = HighloadBlockTable::compileEntity('ProductColor');
/** @var class-string<\Bitrix\Highloadblock\DataManager> $dataClass */
$dataClass = $entity->getDataClass();

$add = $dataClass::add(['UF_NAME' => 'Red', 'UF_CODE' => 'red', 'UF_TAGS' => ['a', 'b']]);
if (!$add->isSuccess()) { /* getErrorMessages() */ }

$row = $dataClass::getRow(['select' => ['ID', 'UF_NAME'], 'filter' => ['=UF_CODE' => 'red']]); // array|null
$list = $dataClass::getList([
    'select' => ['ID', 'UF_NAME'], 'filter' => ['=UF_ACTIVE' => 1],
    'order' => ['ID' => 'ASC'], 'limit' => 20, 'offset' => 0, 'count_total' => true,
]);
$total = $list->getCount();

$dataClass::update((int)$row['ID'], ['UF_NAME' => 'Dark red']); // partial: pass only changed fields
$dataClass::delete((int)$row['ID']); // also removes multiple values and UF files
```

- Object API: `fetchObject()` / `fetchCollection()` work (`$obj->get('UF_NAME')`); classes are runtime-generated.
- UF validation runs in `add()`/`update()` (mandatory, type checks) — errors land in the `Result`. Unknown field keys throw.
- Multiple field update **replaces** the whole set; `[]` clears it. Single optional link cleared with `null`.
- Files: `\CFile::MakeFileArray($path)` as value; replace by adding `'old_id' => $oldFileId` to the new array; clear with array `['error' => UPLOAD_ERR_NO_FILE, 'old_id' => $id, 'del' => true, ...]`. File deletion happens before the operation completes — a DB transaction does not restore files.
- No optimistic locking: `update()` overwrites concurrent changes; lock at application level if needed.
- Idempotent import: `getRow` by unique `UF_CODE` → add or update (sequential runs only; use a DB unique constraint for parallel safety).

## Relations Between HL Blocks (UF type `hlblock`)

Stores the target record's numeric `ID`. `SETTINGS`: `HLBLOCK_ID` (required, target block), `HLFIELD_ID` (display field, `0` = ID), `DISPLAY` (`LIST|CHECKBOX|UI|DIALOG`), `LIST_HEIGHT`, `DEFAULT_VALUE`. `MULTIPLE` lives on the field, not in `SETTINGS`. Self-references allowed (e.g. `UF_PARENT` tree) — guard against cycles yourself.

- Single field gets an auto ORM reference `UF_X_REF`: select `'CAT_NAME' => 'UF_CATEGORY_REF.UF_NAME'`, filter `'=UF_CATEGORY_REF.UF_ACTIVE' => 1`.
- Multiple field has **no** `_REF` alias — only the array value and a `_SINGLE` helper expression. Collect IDs, then one batched query with `'@ID' => $ids`.
- No FK constraints: existence of the target is never checked and dangling links are not cleaned. Validate before save, define delete rules (block / clear / replace / tolerate).

## Directory Property (Iblock ← HL)

Iblock property of type Справочник stores the **`UF_XML_ID`** of the HL record (not the `ID`). Create with `PROPERTY_TYPE => 'S'`, `USER_TYPE => 'directory'`, `USER_TYPE_SETTINGS => ['TABLE_NAME' => $hl['TABLE_NAME']]`; multiplicity via property `MULTIPLE`, not `USER_TYPE_SETTINGS`.

Directory service fields: `UF_XML_ID` (required, stable, unique — no auto constraint), `UF_NAME`, `UF_SORT`, `UF_FILE`, `UF_DEF` (default flag), `UF_DESCRIPTION`, `UF_FULL_DESCRIPTION`, `UF_LINK`. Resolve values: read property → query HL data class with `'@UF_XML_ID' => $values`. After a `TABLE_NAME` rename, update the property's `USER_TYPE_SETTINGS` or its options stop loading. For cross-environment transfer keep `UF_XML_ID` stable; numeric `ID`s differ per environment.

## Events

Dynamic-class ORM events; register via `Bitrix\Main\ORM\EventManager` with the data class (register before calling the operation; permanent handlers go in init.php or module install):

```php
use Bitrix\Main\ORM\{Event, EventManager, EventResult, EntityError};
use Bitrix\Main\ORM\Data\DataManager;

EventManager::getInstance()->addEventHandler(
    $dataClass,
    DataManager::EVENT_ON_BEFORE_ADD,
    static function (Event $event): EventResult {
        $result = new EventResult();
        $fields = $event->getParameter('fields');
        $result->modifyFields(['UF_CODE' => mb_strtolower(trim((string)$fields['UF_CODE']))]);
        // or: $result->addError(new EntityError('...')); to cancel
        return $result;
    }
);
```

| Event | Cancellable | Notes |
| --- | --- | --- |
| `OnBeforeAdd` / `OnBeforeUpdate` | Yes | `modifyFields()`, `unsetFields()`, `addError()`; update gets `fields` + `oldFields` (scalar) |
| `OnBeforeDelete` | Yes | no `fields`; record data in `oldFields` |
| `OnAdd` / `OnUpdate` / `OnDelete` | No | pre-SQL, cannot cancel via EventResult |
| `OnAfterAdd` / `OnAfterUpdate` / `OnAfterDelete` | No | `id`/`primary`; cache clears, audit, background jobs |

Calling the same data-class method inside its handler re-fires events — guard with a static flag. Handler exceptions abort the PHP flow; after-events are not part of a transaction with external actions.

## Rights

Direct data-class calls **never check user rights**. Operations: `hl_element_read`, `hl_element_write` (add+update), `hl_element_delete` — per block, not per record. Check yourself:

```php
$ops = \Bitrix\Highloadblock\HighloadBlockRightsTable::getOperationsName([$hlId])[$hlId] ?? [];
$allowed = $USER->IsAdmin() || in_array('hl_element_write', $ops, true);
```

`getOperationsName()` relies on global `$USER` — in agents/CLI decide the access model explicitly (never default to admin).

## Components

Read-only public output: `bitrix:highloadblock.list` (`BLOCK_ID`*, `ROWS_PER_PAGE`, `PAGEN_ID` — unique per list on one page, `FILTER_NAME` — name of a global var holding an ORM filter, `SORT_FIELD`/`SORT_ORDER`, `DETAIL_URL` with `#ID#`/`#BLOCK_ID#`, `CHECK_PERMISSIONS`) and `bitrix:highloadblock.view` (`BLOCK_ID`*, `ROW_KEY` default `ID`, `ROW_ID`*, `LIST_URL` with `#BLOCK_ID#`, `CHECK_PERMISSIONS`). No `CACHE_TYPE`/`CACHE_TIME` — they do not cache. `CHECK_PERMISSIONS => 'Y'` passes if the user has **any** operation, not strictly read; components show errors but set no HTTP status (pre-check for real 404/403). List result: `rows` (SHOW_IN_LIST fields pre-rendered as HTML — don't re-escape), `fields`, `nav_object`; view result: `ERROR`, raw `row`, `fields` (render via `$USER_FIELD_MANAGER->getListView()`).

## Performance

- Select only needed fields; exact filters (`=UF_CODE`) index-friendly, `%UF_NAME` is not; avoid functions over indexed columns in `runtime`.
- Batch processing: iterate by `'>ID' => $lastId` + `order ID ASC` + `limit`, not growing `offset`; fix `<=ID` upper bound for a stable run; persist `$lastId` for resume.
- Kill queries-in-loop: collect IDs, one query with `'@ID' => $ids`, map by ID.
- Query cache: `'cache' => ['ttl' => 300]` (off by default); JOINs need `'cache_joins' => true`; `add/update/delete` auto-clear the entity cache, external writes need `$dataClass::getEntity()->cleanCache()`.
- Indexes via migration: `$conn->isIndexExists($dataClass::getTableName(), $fields)` / `$conn->createIndex($table, $name, $fields)`; never per-request.
- Measure with `Bitrix\Main\Diag\SqlTracker`: `$tracker = $connection->startTracker()`, then `getQueries()`, `getCounter()`, `getTime()`.

## Anti-Patterns

- Raw SQL against the HL table or multiple-value storage (breaks UF validation, events, sync, cache).
- Treating HL as iblock (no sections, no `API_CODE` element ORM) or hardcoding generated class names without `compileEntity`.
- Assuming rights are enforced by the ORM class, or that `CHECK_PERMISSIONS` covers your own queries in templates/AJAX.
- Relying on hardcoded numeric HL `ID` across environments — look up by `NAME`; for directory values rely on `UF_XML_ID`.
- Using target-record `ID` in a `directory` property (it stores `UF_XML_ID`) or `_REF`-suffixed UF codes.

## Checklist

- [ ] `Loader::includeModule('highloadblock')` before API use.
- [ ] `NAME`/`TABLE_NAME` satisfy naming rules; create via `HighloadBlockTable::add`, idempotently by `NAME`.
- [ ] UF attached to `HLBLOCK_{id}` via `compileEntityId()`; every `Result` / `CUserTypeEntity` return checked.
- [ ] After structure changes: new request (or forced `compileEntity(..., true)` + `hasField()` check).
- [ ] CRUD via compiled data class; multiple fields replaced wholesale; files via `MakeFileArray` + `old_id`/`del`.
- [ ] Rights checked in code (`hl_element_*`); validations/cancels in `OnBefore*` events.
- [ ] Relations validated before save (no FK); directory props keyed by stable unique `UF_XML_ID`.
- [ ] Big sets: batch by `ID`, `cache.ttl` where data is stable, indexes added by migration only.

## Related skills

`bitrix-iblocks`, `bitrix-orm`, `bitrix-events`, `bitrix-cms-basics`, `bitrix-catalog` (directory props on products), `bitrix-performance`.
