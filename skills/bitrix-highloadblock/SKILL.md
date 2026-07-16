---
name: bitrix-highloadblock
description: Covers Highloadblock module — HighloadBlockTable, compileEntity(), dynamic DataManager CRUD, user fields (HLBLOCK_{id}), directory iblock property link, when to choose HL vs iblock vs custom ORM tablet. Applied for flat dictionaries, reference lists, and high-volume simple entities without sections. Key terms — highloadblock, HighloadBlockTable, compileEntity, DataManager, HLBLOCK_, directory, CIBlockPropertyDirectory, UF.
---

# Highload Blocks (`highloadblock`)

Highload blocks (HL) are ORM-backed flat tables with columns as **user fields**. No sections/tree, no iblock SEO/permissions model. Baseline: main **23.0+** (module present on typical installs).

```php
\Bitrix\Main\Loader::includeModule('highloadblock');
```

## When HL vs Iblock vs Custom Tablet

| Need | Prefer |
| --- | --- |
| Flat dictionary / reference list, admin UF UI, link from iblock as “directory” | **Highload block** |
| Sections, SEO, complex properties, public catalog/news UX | **Iblock** (`bitrix-iblocks`) |
| Strict typed domain model, migrations, no UF dependency | **Custom ORM tablet** in your module (`bitrix-orm`) |

HL fits colors, brands, simple lookups. Do not use HL as a substitute for a full content tree or commerce catalog.

## Core Concepts

| Term | Meaning |
| --- | --- |
| HL entity | Row in `b_hlblock_entity` (`NAME`, `TABLE_NAME`) |
| Physical table | Created on `HighloadBlockTable::add` from `TABLE_NAME` |
| Fields | User fields with `ENTITY_ID = HLBLOCK_{id}` |
| Dynamic DataManager | Class `{NAME}Table` built by `compileEntity()` |

`NAME` must be a valid PHP class prefix (e.g. `BrandDict` → `BrandDictTable`).

## Create HL Block

```php
<?php declare(strict_types=1);

use Bitrix\Highloadblock\HighloadBlockTable;
use Bitrix\Main\Loader;

Loader::includeModule('highloadblock');

$result = HighloadBlockTable::add([
    'NAME' => 'BrandDict',
    'TABLE_NAME' => 'b_hlbd_brand',
]);
if (!$result->isSuccess()) {
    // $result->getErrorMessages()
}

$hlId = (int)$result->getId();
// ENTITY_ID for UF: HighloadBlockTable::compileEntityId($hlId) → 'HLBLOCK_12'
```

Add fields via `CUserTypeEntity::Add` with `ENTITY_ID` = `HLBLOCK_{id}` (`USER_TYPE_ID`: `string`, `integer`, `enumeration`, `file`, `hlblock`, …).

Lang titles: `HighloadBlockLangTable` (reference `LANG` on `HighloadBlockTable`).

## Compile Entity and CRUD

`compileEntity($hlblock)` accepts **array**, **ID**, or **NAME**. Returns `Bitrix\Main\ORM\Entity`. Generated class extends `Bitrix\Highloadblock\DataManager` (UF checks on add/update/delete).

```php
<?php declare(strict_types=1);

use Bitrix\Highloadblock\HighloadBlockTable;
use Bitrix\Main\Loader;

Loader::includeModule('highloadblock');

$entity = HighloadBlockTable::compileEntity('BrandDict');
/** @var class-string<\Bitrix\Highloadblock\DataManager> $dataClass */
$dataClass = $entity->getDataClass();

$add = $dataClass::add([
    'UF_NAME' => 'Acme',
    'UF_XML_ID' => 'acme',
]);

$row = $dataClass::getList([
    'select' => ['ID', 'UF_NAME', 'UF_XML_ID'],
    'filter' => ['=UF_XML_ID' => 'acme'],
    'limit' => 1,
])->fetch();

$dataClass::update((int)$row['ID'], ['UF_NAME' => 'Acme Ltd']);
$dataClass::delete((int)$row['ID']);
```

Object API also works after compile (`fetchObject` / collections) when annotations/IDE support are available (`orm:annotate` helps surrounding code; HL classes are runtime-generated).

Recompile after UF map changes: `compileEntity($hl, force: true)` or destroy entity instance as kernel does on UF events.

## Directory Property (Iblock ↔ HL)

Iblock property user type **`directory`** (`CIBlockPropertyDirectory`, `USER_TYPE = directory`) stores values as links into an HL table (often prefixed `b_hlbd_`). Settings live in `USER_TYPE_SETTINGS` (table name, size, etc.).

Typical use: product “brand/color” as a dictionary in HL, selected on catalog elements. Resolve rows via compiled HL DataManager by `UF_XML_ID` / `ID` — do not invent join APIs beyond UF/iblock property values.

Also: UF type `hlblock` (`CUserTypeHlblock`) references HL rows from other UF entities. Field names ending with `_REF` are reserved for HL internal references.

## Rights and Admin

- Rights table: `HighloadBlockRightsTable`.
- Admin UI / components: `highloadblock.list`, `highloadblock.view` (under module install components).
- Entity selector integration may be present in module `.settings.php` — optional for custom code.

## Anti-Patterns

- Treating HL as iblock (no sections, no `API_CODE` element ORM).
- Hardcoding generated class names without `compileEntity` / `Loader::includeModule`.
- Putting complex business graphs only in HL when a module tablet is clearer.
- Raw SQL against `TABLE_NAME` bypassing UF validation in `DataManager`.

## Checklist

- [ ] `Loader::includeModule('highloadblock')` before API use.
- [ ] `NAME` / `TABLE_NAME` valid; table created via `HighloadBlockTable::add`.
- [ ] UF attached to `HLBLOCK_{id}` (`compileEntityId`).
- [ ] CRUD goes through `compileEntity()` → `getDataClass()`.
- [ ] Directory properties point at the correct HL table settings.
- [ ] Choice vs iblock/custom ORM is intentional.

## Related skills

`bitrix-iblocks`, `bitrix-orm`, `bitrix-cms-basics`, `bitrix-catalog` (directory props on products).
