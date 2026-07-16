# Placement and structure

Component = a widget that fetches data via module API and transforms it into HTML. For entire sections (catalog, personal area), prefer a controller + routes; complex SEF components when visual-editor tree integration is required.

## Where to Place

- System: `/bitrix/components/bitrix/` — **do not touch**.
- User: `/local/components/<vendor>/<name>/`.
- Component Name: `<vendor>:<name>` (`vendor:catalog.list`). The namespace folder is yours; other vendors' components should not go there.

Quick scaffold:

```bash
php bitrix/bitrix.php make:component Vendor:Catalog.List --local
php bitrix/bitrix.php make:component Vendor:Catalog.List --module=vendor.catalog
```

## Folder Structure

```
/local/components/vendor/catalog.list/
├── class.php              # logic (CBitrixComponent)
├── .description.php       # name/icon/place in visual editor tree
├── .parameters.php        # parameters description for admin panel
├── ajax.php               # optional: lightweight AJAX controller
├── lang/en/
│   ├── class.php
│   ├── .description.php
│   ├── .parameters.php
│   └── component_epilog.php
└── templates/
    ├── .default/
    │   ├── template.php
    │   ├── result_modifier.php
    │   ├── component_epilog.php
    │   ├── style.css
    │   ├── script.js
    │   ├── .description.php
    │   ├── .parameters.php
    │   └── lang/en/template.php
    └── <other_template>/
```

## `class.php` — Minimum

```php
<?php declare(strict_types=1);

if (!defined('B_PROLOG_INCLUDED') || B_PROLOG_INCLUDED !== true) { die(); }

final class VendorCatalogListComponent extends \CBitrixComponent
{
    public function onPrepareComponentParams($arParams): array
    {
        $arParams['IBLOCK_ID'] = (int)($arParams['IBLOCK_ID'] ?? 0);
        $arParams['COUNT']     = max(1, (int)($arParams['COUNT'] ?? 20));
        $arParams['CACHE_TIME'] = (int)($arParams['CACHE_TIME'] ?? 3600);

        return $arParams;
    }

    public function executeComponent(): void
    {
        if (!\Bitrix\Main\Loader::includeModule('iblock'))
        {
            ShowError('Module iblock is not installed');
            return;
        }

        if ($this->startResultCache(false, [$GLOBALS['USER']->GetUserGroupArray()]))
        {
            $this->arResult['ITEMS'] = $this->fetchItems();
            $this->setResultCacheKeys(['ITEMS', 'SECTION_NAME']);
            $this->includeComponentTemplate();
        }
    }

    private function fetchItems(): array
    {
        // data reading
        return [];
    }
}
```

## Usage

```php
$APPLICATION->IncludeComponent(
    'vendor:catalog.list',
    '.default',
    [
        'IBLOCK_ID' => 12,
        'COUNT'     => 10,
        'CACHE_TIME' => 3600,
        'CACHE_TYPE' => 'A',
    ],
    /* parent */ $component ?? false,
);
```

In complex components **always** pass `$component` as the fourth parameter — this allows nested components to find templates in the parent's folder and cache epilogs.

## `$arParams` and `$arResult`

- `$arParams` — input parameters. Values automatically go through `htmlspecialcharsEx`; raw source is available with `~` prefix: `$arParams['~NAME']`.
- `$arResult` — template data. Initialized as `[]`.
- Both are references to component fields. Do not reassign via `$arParams = &$other` and do not `unset($arParams)` — the link to the template will break.

## `.description.php`

```php
<?php
use Bitrix\Main\Localization\Loc;

$arComponentDescription = [
    'NAME' => Loc::getMessage('VENDOR_CATALOG_LIST_NAME'),
    'DESCRIPTION' => Loc::getMessage('VENDOR_CATALOG_LIST_DESC'),
    'ICON' => '/images/icon.gif',
    'PATH' => [
        'ID' => 'content',
        'CHILD' => ['ID' => 'catalog', 'NAME' => 'Catalog'],
    ],
    'CACHE_PATH' => 'Y',
    'COMPLEX' => 'N',
];
```

Without `PATH`, the component won't appear in the visual editor. Tree roots are reserved: `content`, `service`, `communication`, `e-store`, `utility`.

## `.parameters.php`

```php
<?php
use Bitrix\Main\Localization\Loc;

$arComponentParameters = [
    'GROUPS' => [
        'SETTINGS' => ['NAME' => Loc::getMessage('SETTINGS'), 'SORT' => 100],
    ],
    'PARAMETERS' => [
        'IBLOCK_ID' => [
            'PARENT' => 'SETTINGS',
            'NAME' => Loc::getMessage('IBLOCK_ID'),
            'TYPE' => 'STRING',
            'DEFAULT' => '',
        ],
        'COUNT' => [
            'PARENT' => 'SETTINGS',
            'NAME' => Loc::getMessage('COUNT'),
            'TYPE' => 'STRING',
            'DEFAULT' => '20',
        ],
        'SET_TITLE'  => [],  // special — enables title
        'CACHE_TIME' => [],  // special — enables caching block
    ],
];
```

`TYPE` types: `LIST`, `STRING`, `CHECKBOX`, `FILE`, `COLORPICKER`, `CUSTOM` (for custom JS widgets). Hints are `<PARAM>_TIP` constants in `lang/en/.parameters.php`.
