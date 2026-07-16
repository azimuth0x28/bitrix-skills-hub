---
name: bitrix-cms-basics
description: Covers CMS fundamentals — sites, site templates, menus, page templates, includes, breadcrumbs, user groups, user fields, admin panel. Applied for site structure and content management tasks. Key terms — CSite, template, menu, include area, user field, UF.
---

# CMS Basics

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

Site management layer above the framework — sites, templates, menus, content areas. Landing sites / Sites24: skill `bitrix-landing`.

## Sites (Multisite)

ORM tablet: `\Bitrix\Main\SiteTable` → table `b_lang` (`main/lib/SiteTable.php`). Legacy: `CSite`.

Key fields: `LID` (primary, e.g. `s1`), `NAME`, `DIR`, `DOC_ROOT`, `SERVER_NAME`, `SITE_NAME`, `LANGUAGE_ID`, `CULTURE_ID`, `ACTIVE`, `DEF`.

```php
$site = \Bitrix\Main\SiteTable::getRow([
    'filter' => ['=LID' => SITE_ID],
    'select' => ['LID', 'DIR', 'SERVER_NAME', 'DOC_ROOT', 'LANGUAGE_ID'],
]);

$docRoot = \Bitrix\Main\SiteTable::getDocumentRoot(SITE_ID);
```

`SITE_ID` / `SITE_DIR` are available after kernel init. Resolve site by host/path: `SiteTable::getByDomain($host, $directory)`.

## Site Templates

Location: `/local/templates/<template_id>/`

```
/local/templates/mytemplate/
├── header.php
├── footer.php
├── styles.css
├── components/       # Template-level component overrides
├── page_templates/   # Page layout templates
└── lang/
```

**`#WORK_AREA#`** — required placeholder in the site template (often a single-file template or between `header.php` / `footer.php` flow). The kernel injects the page body at `#WORK_AREA#`. Missing marker → admin error “set the #WORK_AREA# separator”.

Template selected per site in Admin → Sites → Edit. Prefer `/local/templates/`, not `/bitrix/templates/`.

## Section and Access Files

### `.section.php`

Per-directory file (walked from current path up to site root). Typical contents:

```php
<?php
$sSectionName = 'News';
$arDirProperties = [
    'TITLE' => 'News section',
    'keywords' => 'news, updates',
    'description' => 'Company news',
];
```

- `$sSectionName` — used for breadcrumbs (`GetNavChain`).
- `$arDirProperties` — directory properties; read via `$APPLICATION->GetDirProperty()` / merged into `$APPLICATION->GetProperty()`.

### `.access.php`

Per-directory file permissions (`PERM[...]`). Managed by `$APPLICATION->SetFileAccessPermission()` / admin UI. Do not hand-edit unless you know the format; kernel includes it when resolving file rights.

## Page Properties

```php
$APPLICATION->SetPageProperty('title', 'About');
$APPLICATION->SetPageProperty('description', 'About the company');
$APPLICATION->SetPageProperty('keywords', 'about');

$title = $APPLICATION->GetPageProperty('title', 'Default');
// GetProperty: page first, then directory (.section.php), then default
$desc = $APPLICATION->GetProperty('description');
```

- `SetPageProperty` / `GetPageProperty` — current page only.
- `SetDirProperty` / `GetDirProperty` — directory props (often from `.section.php`).
- `GetProperty` — page → dir → default.

Common keys: `title`, `description`, `keywords`, plus custom uppercase IDs.

## Menus

- Menu types per site (`top`, `left`, …).
- Files: `/.top.menu.php`, `/.left.menu.php` in site root or section.
- Component: `bitrix:menu`.

## Page Templates

`/local/templates/<id>/page_templates/` — reusable layouts for the visual editor.

## Include Areas

`bitrix:main.include` — editable content blocks:

```php
$APPLICATION->IncludeComponent('bitrix:main.include', '', [
    'AREA_FILE_SHOW' => 'file',
    'PATH' => '/include/phone.php',
]);
```

Files typically under `/include/` or `/local/include/`.

## Breadcrumbs

- Auto from `$sSectionName` in `.section.php` along the path.
- Manual: `$APPLICATION->AddChainItem('Title', '/path/')`.
- Component: `bitrix:breadcrumb`.

## Users and Groups

- `CUser`, `\Bitrix\Main\UserTable` — users.
- Groups control permissions via `\CMain::GetUserRight()` and group IDs.
- **User fields (UF)** — `CUserTypeEntity`, `\Bitrix\Main\UserFieldTable`; register in module `DoInstall`; access via `USER.UF_*` in ORM or user fields API.

## Admin Panel

`/bitrix/admin/` — admin scripts. Custom pages via module install admin files, or modern UI (`bitrix-ui`). Legacy lists: `CAdminList` / `CAdminForm`.

## Checklist

- [ ] Site-specific code checks `SITE_ID` / `SITE_DIR`.
- [ ] Template has `#WORK_AREA#`; overrides in `/local/templates/`.
- [ ] Section meta/breadcrumbs via `.section.php`; rights via `.access.php` / API.
- [ ] Page meta via `SetPageProperty` / `GetProperty`.
- [ ] Menus via `.menu.php` or Admin UI; includes for editable fragments.
- [ ] Landings / composite sites → `bitrix-landing` when applicable.
