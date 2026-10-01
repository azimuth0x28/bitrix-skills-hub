# Anatomy of a Custom UF Type and Its Data Providers
Layer: the PHP type class and its server-side data — the `Field contract and identifiers`,
`Native-type decision…`, `Type class and registration`, and `Field instance` sections of
`workflow.md`; rendering, JS, filter, and bizproc output live in their own rule files. Anything not
verifiable on your installation reads "verify in your kernel".

## Anatomy of a custom UF type class

A custom UF type extends `\Bitrix\Main\UserField\Types\BaseType`, which is **abstract**: every
subclass must implement `getDbColumnType(): string` or the class fails to load. `CUserTypeManager`
uses that method to build the single-value storage column for the DEFAULT storage provider
(`ALTER TABLE b_uts_<entity> ADD <FIELD_NAME> <type>`; HL-blocks build their own `UF_*` column via
their storage handlers, `entity-bindings.md`). Under that provider a multi-value field gets a TEXT
`b_uts_*` column regardless of `getDbColumnType()`, values split into `b_utm_*` rows, and an empty
`getDbColumnType()` result for a single-value UTS field aborts `CUserTypeEntity::Add()` before the row insert
(the HL provider skips that check — its storage column arrives later, `entity-bindings.md`). Pick
the SQL type through the connection helper, as the stock types do (`StringType::getDbColumnType()`).

A complete, loadable example:

```php
<?php
// local/modules/<vendor>.<module>/lib/UserField/Type/MySmartFieldType.php
declare(strict_types=1);
namespace Vendor\Module\UserField\Type;
use Bitrix\Main\Application;
use Bitrix\Main\ORM\Fields\TextField;
use Bitrix\Main\UserField\Types\BaseType;
use CUserTypeManager;
final class MySmartFieldType extends BaseType
{
    public const USER_TYPE_ID = 'my_smart_field';   // unique portal-wide
    protected const RENDER_COMPONENT = '<vendor>:<module>.field.my_smart_field';
    public static function getDbColumnType(): string
    {
        $helper = Application::getConnection()->getSqlHelper();
        return $helper->getColumnTypeByField(new TextField('x'));
    }
    protected static function getDescription(): array
    {
        return [
            'DESCRIPTION' => 'My smart field',
            'BASE_TYPE' => CUserTypeManager::BASE_TYPE_STRING,
        ];
    }
    public static function prepareSettings(array $userField): array
    {
        return $userField['SETTINGS'] ?? [];
    }
    public static function checkFields(array $userField, $value, $userId): array
    {
        if ($value === null || $value === '') {
            return [];
        }
        return is_string($value) ? [] : [['id' => $userField['FIELD_NAME'], 'text' => 'Wrong value type']];
    }
}
```

- `USER_TYPE_ID` — public override, stored in `b_user_field.USER_TYPE_ID`; unique portal-wide
  (contract via `workflow.md`).
- `RENDER_COMPONENT` — the component included for every render mode; `BaseType::getComponentName()`
  prefixes bare names with `bitrix:`, like `StringType::RENDER_COMPONENT = 'bitrix:main.field.string'`.
- `getUserTypeDescription()` merges the base description (sets `USER_TYPE_ID`, `CLASS_NAME`,
  `EDIT_CALLBACK`/`VIEW_CALLBACK`, `USE_FIELD_COMPONENT => true`) with `getDescription()` — override
  `getDescription()` for `DESCRIPTION`/`BASE_TYPE`; the base returns `[]`.
- `BASE_TYPE` drives classic-path formatting: `system.field.view` switches on it (double rounds,
  int casts, default encodes).
- Multiplicity: `MULTIPLE = 'Y'` serializes as `FIELD_NAME[]`. Default provider:
  `getUtsDBColumnType()` gives a TEXT `b_uts_*` column regardless; values split into `b_utm_*`
  rows. HL builds a separate `<hl_table>_<field>` table (`entity-bindings.md`); `getDefaultValue()`
  wraps defaults in arrays — handle both shapes in `checkFields`.
- Overriding `renderView()` / `renderEdit()` to return raw HTML is a valid light path; without
  overrides the class renders through `RENDER_COMPONENT` (`render-component.md`).

## Registering the type on the portal

The user-field manager discovers types through `OnUserTypeBuildList` (a `main` event): the first
`CUserTypeManager::GetUserType()` call fires it, keys by `USER_TYPE_ID` (last wins); the class must
load first.

Self-contained module path (`workflow.md`, Mode B) — autoload plus a persistent handler pair:
- `include.php`: `Loader::registerAutoLoadClasses('<vendor>.<module>', [MyType::class =>
  'lib/UserField/Type/MyType.php'])` registers the class map on every request.
- `DoInstall`/`DoUninstall`: `RegisterModuleDependences('main', 'OnUserTypeBuildList',
  '<vendor>.<module>', MyType::class, 'getUserTypeDescription')` / `UnRegisterModuleDependences`
  — the legacy API the `highloadblock` module uses; `registerEventHandler(...)` D7 works the same.
- Runtime alternative in `include.php` (module INSTALLED and included):
  `EventManager::getInstance()->addEventHandler('main', 'OnUserTypeBuildList',
  [MyType::class, 'getUserTypeDescription'])`; the no-module path is `local/php_interface/init.php`
  with `require_once` (or `Loader::registerAutoLoadClasses(...)`) plus `AddEventHandler(...)`.

- A new module must be installed before its persistent handlers fire; runtime handlers register on
  the next request. Static evidence: handler present in the registration source; actual type
  availability in `CUserTypeManager::GetUserType` is portal-manual.

## Server-side data providers on the type

Static methods the manager and renderers call by convention (`CUserTypeManager` contract):

- `prepareSettings(array $userField): array` — `CUserTypeManager` calls it with **one argument, the
  full field array**; its output is serialized into `b_user_field.SETTINGS` when `CUserTypeEntity::Add()`
  or `::Update()` saves the field. Templates read settings back from `$arResult['userField']['SETTINGS']`.
- `checkFields(array $userField, $value, $userId): array` — called per value on save with those
  three arguments; return `['id' => $FIELD_NAME, 'text' => ...]` entries for errors, `[]` when valid.
- `getList()` — option enumeration for list-style types; whether the manager feeds admin editors from
  it is **verify in your kernel**.
- Legacy callback names (`getEditFormHTML`, `getAdminListViewHTML`, `getFilterHTML`,
  `getDBColumnType`) still work and map to the `MODE_*` renders — the modern path is `render*`.
- BizProc note: the legacy printable chain hands the surface a pseudo-field with no `FIELDS` and
  no `SETTINGS` — names come only from the ID re-query (`bizproc-output.md`).

## Where provider code lives

| Provider kind | Location | Example |
|---|---|---|
| UF type class | `lib/UserField/Type/` | `MySmartFieldType` |
| Class autoload + runtime registration | `include.php` | `Loader::registerAutoLoadClasses`, `addEventHandler` |
| Entity-selector provider | `lib/Integration/UI/EntitySelector/` | `MyEntityProvider` |
| Render component | `local/components/<vendor>/` or `install/components` | `<vendor>:<module>.field.<type>` |
| Persistent handlers | module registration (`DoInstall`/`DoUninstall`) | `RegisterModuleDependences` pair |
| AJAX for settings forms | `local/components/` or controller | settings callbacks |

**Never build the CRM-grid filter on `GetFilterData()`** — a legacy admin-list path
(`CUserTypeManager::AdminListAddFilterFieldsV2()`), not the CRM grid; the grid widget map keys on
`USER_TYPE_ID` and gives an unknown type no class hook at all (`crm-filter.md`).

## Checklist

- [ ] Class extends `BaseType` and implements `getDbColumnType(): string` (mandatory abstract).
- [ ] `USER_TYPE_ID` unique portal-wide; `BASE_TYPE` set in `getDescription()`.
- [ ] `RENDER_COMPONENT` set (or `renderView`/`renderEdit` overridden).
- [ ] Type registered and autoloaded per the mode's scheme (`bitrix-events` when available); `init.php` fallback.
- [ ] `prepareSettings(array $userField)` one-arg signature; `checkFields($userField, $value, $userId)`.
- [ ] No reliance on legacy `GetFilterData()` for the CRM grid filter.
