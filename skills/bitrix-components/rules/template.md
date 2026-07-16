# Templates and epilog

## Template

### Template Search

Order from `CBitrixComponentTemplate::__SearchTemplate` / `generatePossibleTemplatePath()` (`main/classes/general/component_template.php`). Parent-template paths apply only when the component was included with a parent (`IncludeComponent` 4th argument). `/local/` is always checked before `BX_PERSONAL_ROOT` (usually `/bitrix`) and system component templates.

With a **parent** component template (typical nested call):

1. `/local/templates/<site_template>/components/<parent_path>/<parent_tpl>/<component_path>/`
2. `/local/templates/.default/components/<parent_path>/<parent_tpl>/<component_path>/`
3. `/local/components/<parent_path>/templates/<parent_tpl>/<component_path>/`
4. `/local/templates/<site_template>/components/<component_path>/`
5. `/local/templates/.default/components/<component_path>/`
6. `/local/components/<component_path>/templates/`
7. `/bitrix/templates/<site_template>/components/<parent_path>/<parent_tpl>/<component_path>/` (`BX_PERSONAL_ROOT`)
8. `/bitrix/templates/.default/components/<parent_path>/<parent_tpl>/<component_path>/`
9. `/bitrix/components/<parent_path>/templates/<parent_tpl>/<component_path>/`
10. `/bitrix/templates/<site_template>/components/<component_path>/`
11. `/bitrix/templates/.default/components/<component_path>/`
12. `/bitrix/components/<component_path>/templates/`

Without a parent, steps that mention `<parent_…>` are skipped; search still prefers `/local/templates…` → `/local/components…/templates` → `/bitrix/templates…` → `/bitrix/components…/templates`.

Site-specific overrides: copy into `/local/templates/<site>/components/<ns>/<name>/<tpl>/`. Kernel updates will not overwrite that copy.

### `template.php`

```php
<?php if (!defined('B_PROLOG_INCLUDED') || B_PROLOG_INCLUDED !== true) { die(); } ?>

<div class="catalog-list">
    <?php foreach ($arResult['ITEMS'] as $item): ?>
        <a href="<?= htmlspecialcharsbx($item['URL']) ?>">
            <?= htmlspecialcharsbx($item['NAME']) ?>
        </a>
    <?php endforeach; ?>
</div>
```

### Available Variables

`$arResult`, `$arParams`, `$templateName`, `$templateFolder`, `$templateFile`, `$componentPath`, `$component`, `$this`, `$templateData`, `$APPLICATION`, `$USER`.

## `result_modifier.php`

Runs **before** the template. Use to enrich `$arResult` without modifying the component class.

- When caching is **enabled**, the template (and modifier) are skipped on cache hit — modifier does not run.
- Cannot set dynamic page properties (`title`, `keywords`, `description`) when cache is on.
- `$arParams` changes affect the template but not the component member.
- `$arResult` changes affect the component member.

## `component_epilog.php`

Runs **after** the template on **every hit**, even with cache enabled. Use for dynamic page properties, counters, or logic that must execute per request.

Limit cached `$arResult` keys via `setResultCacheKeys()` in `class.php`:

```php
$this->setResultCacheKeys(['ITEMS', 'SECTION_NAME', 'NAV_CACHED_DATA']);
```

Pass data from template to epilog via `$templateData` (cached):

```php
// template.php
$templateData = ['ITEM_COUNT' => count($arResult['ITEMS'])];
```

Epilog lang phrases: create `/lang/en/component_epilog.php` and `Loc::loadLanguageFile(__FILE__)`.

> Code in `class.php` after `includeComponentTemplate()` runs **after** epilog and overrides epilog changes (e.g. `SetTitle`).
