---
name: bitrix-cms-basics
description: "Use when structuring a site — creating sites, templates, menus, includes, breadcrumbs — or managing user groups and fields. Covers CMS fundamentals — sites, site templates, menus, includes, breadcrumbs, styles/CSS handling (styles.css vs template_styles.css, SetAdditionalCSS), user groups, user fields, admin panel. Key terms — CSite, template, menu, include area, styles.css, user field, UF."
metadata:
  type: knowledge
  version: "1.0.0"
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
├── description.php       # Template meta ($arTemplate), incl. EDITOR_STYLES
├── styles.css            # Content styles — also loaded by the visual editor
├── template_styles.css   # Template frame styles (header/footer/grid)
├── .styles.php           # Visual editor style list entries
├── components/           # Template-level component overrides
├── page_templates/       # Page layout templates
└── lang/
```

**`#WORK_AREA#`** — required placeholder in the site template (often a single-file template or between `header.php` / `footer.php` flow). The kernel injects the page body at `#WORK_AREA#`. Missing marker → admin error “set the #WORK_AREA# separator”.

Template selected per site in Admin → Sites → Edit. Prefer `/local/templates/`, not `/bitrix/templates/`.

## Styles (CSS)

Store CSS next to the owner of the markup:

| Owner of markup | Where CSS lives |
| --- | --- |
| Site frame (`header.php` / `footer.php`, grid, background) | `template_styles.css` of the site template |
| Page content that must be styleable in the visual editor | `styles.css` + `.styles.php` of the site template |
| Component template markup (`template.php`) | `style.css` next to the component template |
| JS-extension UI loaded via `Extension::load()` | CSS inside the extension (`config.php` `css` key) — skill `bitrix-extensions` |
| One-off page CSS | `Asset::getInstance()->addCss()` / classic `SetAdditionalCSS()` |

**`styles.css` vs `template_styles.css`:** the visual editor renders content in an iframe and injects `styles.css` into its `<head>` — never put site-frame rules there, or they distort the editor; keep them in `template_styles.css`. Both files are editable in Admin → *Settings → Product settings → Sites → Site templates* (tabs "Site styles" / "Template styles").

**Visual editor style list** — `.styles.php` in the template returns entries (CSS rule itself goes to `styles.css`):

```php
return [
    'example' => [                     // array key = CSS class name
        'tag' => 'p',                  // tag(s) the style applies to; comma-separated list allowed
        'title' => 'Test style',       // name shown in the editor
        'html' => '<span style="...">Preview</span>', // optional styled preview
        // optional 'section' => groups entries in the editor's style dropdown
    ],
];
```

**Editor-only CSS files** — `EDITOR_STYLES` in the template's `description.php` (`$arTemplate`): `'EDITOR_STYLES' => ['/bitrix/css/main/bootstrap.css', ...]`. Loaded only in the visual editor; include them separately for the public site if needed.

**Include APIs:**

```php
$APPLICATION->ShowCSS();          // classic, in header.php <head>: outputs page + template CSS set
$APPLICATION->SetAdditionalCSS('/local/templates/demo/additional.css'); // classic add to that set

\Bitrix\Main\Page\Asset::getInstance()->addCss(SITE_TEMPLATE_PATH . '/styles/page.css');
// 2nd param $additional=true → file goes to the template set, after styles.css / template_styles.css

\Bitrix\Main\UI\Extension::load('demo.product-card'); // extension JS+CSS from its config.php
```

Prefer `Asset::addCss()` (D7) or `Extension::load()` for new code; `ShowCSS()` / `SetAdditionalCSS()` belong to classic site templates.

**Optimization** (Admin → *Settings → Product settings → Module settings → Main module*): merge CSS files (`main` option `optimize_css_files`), use existing `.min` versions, gzip copies (`compres_css_js_files`, requires zlib). Merge applies only to Asset-registered CSS, is skipped in the admin section and Ajax mode, and can be disabled via `disableOptimizeCss()`. Merged files live in `/bitrix/cache/css/<SITE_ID>/<template>/` (kernel / `template_<hash>` / `page_<hash>` sets) — after editing CSS clear the Bitrix cache (and browser cache) if the old look persists.

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
- [ ] Site-frame CSS in `template_styles.css`; editor-visible content CSS in `styles.css` (+ `.styles.php`); component CSS in the template's `style.css`; new code uses `Asset::addCss()` / `Extension::load()`.
- [ ] Section meta/breadcrumbs via `.section.php`; rights via `.access.php` / API.
- [ ] Page meta via `SetPageProperty` / `GetProperty`.
- [ ] Menus via `.menu.php` or Admin UI; includes for editable fragments.
- [ ] Landings / composite sites → `bitrix-landing` when applicable.
