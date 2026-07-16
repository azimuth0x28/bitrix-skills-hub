# Hierarchy, IDs, API boundary

## Hierarchy

- **Iblock Type** (`b_iblock_type`) — a family of iblocks with a shared structure: "news", "catalog".
- **Iblock** (`b_iblock`) — a table of elements of a certain type, linked to sites.
- **Section** (`b_iblock_section`) — a group of elements, forming a tree.
- **Element** (`b_iblock_element`) — a unit of content (news, product).
- **Property** (`b_iblock_property`) — an additional characteristic of an element.

## Key Identifiers

- `CODE` — symbolic code (latin+digits+`-`), used in URLs and code.
- `API_CODE` — 1–50 characters, starts with a letter, **CamelCase recommended**. Object-oriented ORM only works if it's present. Set in iblock settings.
- `XML_ID` — external identifier (for exchanges, Highload directories).

## Where ORM / Classic API Boundary Lies

| Task | API |
| --- | --- |
| Create iblock type | `CIBlockType::Add` (ORM won't add name translations) |
| Create iblock | `CIBlock::Add` (ORM won't link to site, permissions, SEO) |
| Add/change property | `CIBlockProperty::Add/Update/Delete` |
| Basic iblock permissions | `CIBlock::SetPermission` / `GROUP_ID` field in `Add` |
| Advanced permissions | `CIBlockRights` / `CIBlockSectionRights` / `CIBlockElementRights` |
| Image resizing | `CFile::ResizeImage` |
| Full-text search | `CIBlockElement::UpdateSearch($id)` |
| Daily element/section CRUD | ORM |

## Compiling ORM Classes

ORM generates classes "on the fly" by iblock `API_CODE` (`News` in examples below):

```php
\Bitrix\Iblock\IblockTable::compileEntity('News');
// Elements class: \Bitrix\Iblock\Elements\ElementNewsTable
// Sections class: \Bitrix\Iblock\Model\Section::compileEntityByIblock('News')

$elementClass = \Bitrix\Iblock\Elements\ElementNewsTable::class;
$sectionClass = \Bitrix\Iblock\Model\Section::compileEntityByIblock('News');
```

Do not use `\Bitrix\Iblock\ElementTable` and `\Bitrix\Iblock\SectionTable` — they **only** work with basic fields and **do not know about properties/UF**.

IDE annotations: `php bitrix/bitrix.php orm:annotate`.

## Creating an Iblock Programmatically

```php
$iblock = new \CIBlock();
$iblockId = $iblock->Add([
    'IBLOCK_TYPE_ID' => 'mynews',
    'NAME'           => 'News',
    'CODE'           => 'mycompany_news',
    'API_CODE'       => 'News',           // required for ORM
    'ACTIVE'         => 'Y',
    'LID'            => ['s1'],           // link to site
    'GROUP_ID'       => [
        2 => \CIBlockRights::PUBLIC_READ,
        8 => \CIBlockRights::EDIT_ACCESS,
    ],
    'VERSION'        => 2,                // property storage version (usually 2)
]);
if (!$iblockId) { throw new \RuntimeException($iblock->getLastError()->getMessage()); }
```

### Property Storage Versions

- **Version 1** — separate row in the shared `b_iblock_element_property` table. Slow selection, wins with hundreds of properties.
- **Version 2** (default for new) — single/multiple values in `b_iblock_element_prop_s{IBLOCK_ID}` / `b_iblock_element_prop_m{IBLOCK_ID}`. Fast selection when property count is moderate.
- **`PropertyTable`** (`Bitrix\Iblock\PropertyTable`) — fine for **reading** property metadata (`getList` / `getById`). For **add/update/delete**, use **`CIBlockProperty`**: on VERSION=2, classic `Add`/`Update`/`Delete` also alter the `prop_s` / `prop_m` tables (`CIBlockProperty::_Add` and related). Plain `PropertyTable::add/update/delete` only touch `b_iblock_property` and will leave v2 storage inconsistent.

## Rights and Public API

- Basic rights: `CIBlock::SetPermission` / `GROUP_ID` on `CIBlock::Add` (letters like `CIBlockRights::PUBLIC_READ`).
- Extended (element/section level): `CIBlockRights`, `CIBlockSectionRights`, `CIBlockElementRights`. Selections often honor `MIN_PERMISSION` (default public read).
- Namespace `Bitrix\Iblock\Public\` in the kernel is mainly REST validation helpers (`Public\Service\RestValidator\…`), not a general-purpose CRUD façade — prefer compiled ORM entities + classic APIs above for module code.
