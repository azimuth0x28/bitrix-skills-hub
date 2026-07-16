# Cache, SEF, AJAX

## Caching Details

Cache ID is built from: site ID, component name, template name, parameters, external conditions (e.g. user groups).

- Pass user groups as cache key when content differs by group: `$this->startResultCache(false, [$GLOBALS['USER']->GetUserGroupArray()])`.
- Avoid deferred functions in templates when caching is on.
- Autocache can be disabled globally in Admin → Autocache settings.

## SEF (Search-Friendly URLs)

For complex components, define in `.parameters.php`:

```php
'SEF_MODE' => 'Y',
'SEF_FOLDER' => '/catalog/',
'SEF_URL_TEMPLATES' => [
    'sections' => '',
    'section'  => '#SECTION_ID#/',
    'element'  => '#SECTION_ID#/#ELEMENT_ID#/',
],
'VARIABLE_ALIASES' => [
    'SECTION_ID' => ['NAME' => 'Section ID'],
    'ELEMENT_ID' => ['NAME' => 'Element ID'],
],
```

In `class.php`, parse SEF variables and build URLs. Prefer controllers + routes for new full sections; use complex SEF components only when visual editor integration is required.

## Controllerable and AJAX

Implement `\Bitrix\Main\Engine\Contract\Controllerable` (+ `\Bitrix\Main\Errorable` for errors):

```php
final class VendorCatalogListComponent extends \CBitrixComponent
    implements \Bitrix\Main\Engine\Contract\Controllerable, \Bitrix\Main\Errorable
{
    protected \Bitrix\Main\ErrorCollection $errorCollection;

    public function configureActions(): array
    {
        return [
            'addToCart' => [
                '+prefilters' => [new \Bitrix\Main\Engine\ActionFilter\Authentication()],
            ],
        ];
    }

    public function onPrepareComponentParams($arParams): array
    {
        $this->errorCollection = new \Bitrix\Main\ErrorCollection();
        return parent::onPrepareComponentParams($arParams);
    }

    public function addToCartAction(int $productId): array
    {
        // executeComponent() is NOT called during AJAX
        return ['success' => true];
    }

    public function getErrors(): array { return $this->errorCollection->toArray(); }
    public function getErrorByCode($code) { return $this->errorCollection->getErrorByCode($code); }

    protected function listKeysSignedParameters(): array
    {
        return ['IBLOCK_ID', 'STORAGE_ID'];
    }
}
```

Alternative: lightweight `ajax.php` with a class extending `\Bitrix\Main\Engine\Controller`.

### JavaScript

```javascript
BX.ajax.runComponentAction('vendor:catalog.list', 'addToCart', {
    mode: 'class',
    signedParameters: '<?= $this->getComponent()->getSignedParameters() ?>',
    data: { productId: 42 },
});
```

For AJAX page updates, include `id="pagetitle"` and `id="navigation"` in the template.

## Checklist

- [ ] Logic in `class.php`; display in template; heavy work in services.
- [ ] `onPrepareComponentParams` normalizes and casts all `$arParams`.
- [ ] `setResultCacheKeys` limits epilog cache size.
- [ ] Nested components pass `$component` as 4th argument to `IncludeComponent`.
- [ ] `Controllerable` actions have proper filters; signed parameters listed in `listKeysSignedParameters`.
- [ ] Templates in `/local/templates/<site>/components/` for site-specific overrides.
