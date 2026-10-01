# CRM Filter Integration (CRM-specific)
> **CRM only (kernel-confirmed scope):** this rule is the CRM-consumer integration point. The field
> itself is built like any UF (the `Field instance` and `Rendering and optional integrations` stages
> of `workflow.md`); nothing here changes the type. It covers only the CRM entity list filter —
> deals, contacts, companies, and smart processes. No other binding from `entity-bindings.md` has
> this filter surface.

Layer: making a custom UF type appear and filter in the CRM entity list filter. This is where the
kernel stops and the developer's own code must extend the surface — with one owner and no chains.

## What the kernel gives a custom type in the CRM grid filter

The CRM list filter is built by `EntityUFDataProvider::prepareFields()`, which switches on
`USER_TYPE_ID`:

- known kernel types get widgets (employee → entity_selector, string → text, iblock_element → list,
  crm → dest_selector, ...);
- **any other `USER_TYPE_ID`** gets `type = 'custom'`, empty `data.value`, `subtype = USER_TYPE_ID`
  — and nothing else.

The provider calls **no method of the type class** for an unknown type, and its `prepareFieldData()`
is built per field: it returns `null` when the field ID is not in the user-field map and delivers
no widget data for an unknown subtype. An unmodified custom type appears in the CRM filter as an
inert custom control with no value and no search semantics. Smart processes use the same map —
their provider is `ItemUfDataProvider` for `ItemSettings`; deals/contacts/companies use
`UserFieldDataProvider`; both inherit the map above.

## Extending the filter for your own type

The extension point is the CRM filter factory: substitute it **exactly once** from your own module,
the subclass returning a wrapper around the kernel branch:

```php
<?php
// local/modules/<vendor>.<module>/lib/Filter/MyFilterFactory.php
declare(strict_types=1);
namespace Vendor\Module\Filter;
use Bitrix\Crm\Filter\Factory;
use Bitrix\Main\Filter\DataProvider;
use Bitrix\Main\Filter\EntitySettings;
final class MyFilterFactory extends Factory
{
    public function getUserFieldDataProvider(EntitySettings $settings): DataProvider
    {
        $inner = parent::getUserFieldDataProvider($settings);   // kernel branch
        return new MyUserFieldDataProvider($settings, $inner);
    }
}
```

**Never chain factory overrides.** `ServiceLocator::addInstance()` is last-writer-wins; a second
module makes behavior order-dependent and breaks on kernel updates — one owner per portal. Reuse a
stock type when its semantics already fit: no factory change at all.

## Provider composition: replace by UF-ID

`Filter::getFields()` merges provider fields with `+=`, so the base provider's inert `type=custom`
entry survives if you only append. The wrapper must **replace the field's entry by its UF-ID** with
a widget you can serve (per the abstract surface of `DataProvider`):

```php
<?php
declare(strict_types=1);
namespace Vendor\Module\Filter;
use Bitrix\Main\Filter\DataProvider;
use Bitrix\Main\Filter\EntitySettings;
final class MyUserFieldDataProvider extends DataProvider
{
    private const UF_ID = 'UF_MY_FIELD';   // the contract's FIELD_NAME
    public function __construct(private readonly EntitySettings $settings, private readonly DataProvider $inner) {}
    public function getSettings() { return $this->settings; }
    public function prepareFields(): array
    {
        $result = $this->inner->prepareFields();   // Field objects; includes inert type=custom
        if (isset($result[self::UF_ID])) {
            $result[self::UF_ID] = $this->createField(self::UF_ID, [   // real Field, wrapper as provider
                'type' => 'list',
                'name' => $result[self::UF_ID]->getName(),
                'partial' => true,   // data served by prepareFieldData below
            ]);
        }
        return $result;   // Field[] in, Field[] out; the id stays stable
    }
    public function prepareFieldData($fieldID)
    {
        if ($fieldID === self::UF_ID) {
            return ['items' => $this->getOptionItems()];
        }
        return $this->inner->prepareFieldData($fieldID);   // all other fields stay kernel behavior
    }
    private function getOptionItems(): array
    {
        // developer hook: same rights-filtered option list the picker serves — supply it here
        return [];
    }
    public function prepareFilterValue(array $rawFilterValue): array
    {
        $value = $this->inner->prepareFilterValue($rawFilterValue);   // stock conversion first
        if (isset($value[self::UF_ID])) {
            // field-specific ORM condition for your stored column, e.g. exact match
            $value['=' . self::UF_ID] = $value[self::UF_ID];
            unset($value[self::UF_ID]);
        }
        return $value;
    }
}
```

**Kernel trace:** `Filter::getFields()` keeps `prepareFields()`
results as `Field[]`, and `Filter::getFieldArrays()` calls `getId()`/`toArray()` on each — the
entry stays a `Field`, never a plain array. `DataProvider::createField()` returns a `Field` bound
to the wrapper as its provider; a `partial` field assembles through that provider's
`prepareFieldData()`. The CRM grid header sections register the user-field provider as an
**additional** provider, and `Filter::prepareListFilterParams()` invokes `prepareListFilterParam()`
only on the entity provider — never on the wrapper — so the value→ORM conversion goes through
`Filter::prepareFilterValue()`, which pipes every provider's conversion (base
`DataProvider::prepareFilterValue()` is identity; stock `UserFieldDataProvider::prepareFilterValue()`
runs the `AdminListAddFilter()` step, kept by delegating first).

**Scheme hooks:** `getOptionItems()` and the field-specific ORM-condition key — verify on the portal.

## Legacy GetFilterData: admin lists only

`GetFilterData()`/`getFilterHTML()` on the type class feed **admin list pages** via
`CUserTypeManager::AdminListAddFilterFieldsV2()` — useful for the admin grids of your module, **not**
for the CRM entity grid. The CRM grid reads only the `EntityUFDataProvider` map. Do not implement
`GetFilterData()` expecting it to appear in the CRM filter; it will not be called.

## Checklist

- [ ] Stated the kernel default truthfully: unknown `USER_TYPE_ID` → inert `type=custom`, no class hook.
- [ ] Factory substituted from the developer's own module, `extends` + `parent::`, exactly once.
- [ ] Both provider branches kept (`ItemUfDataProvider` for smart processes, `UserFieldDataProvider` for the rest).
- [ ] Field entry replaced by UF-ID, not appended; widget data served and rights-filtered.
- [ ] Value conversion in `prepareFilterValue`; extra providers skip `prepareListFilterParam`; no `GetFilterData()`.
