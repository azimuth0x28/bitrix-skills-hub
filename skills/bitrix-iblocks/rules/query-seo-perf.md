# Selections, SEO, performance

## Selections and Filters

```php
$elements = $elementClass::query()
    ->setSelect(['ID', 'NAME', 'PREVIEW_TEXT', 'AUTHOR', 'SOURCE'])
    ->where('ACTIVE', 'Y')
    ->where('IBLOCK_SECTION_ID', $sectionId)
    ->where('AUTHOR.VALUE', 'Jane Smith')           // filter by property value
    ->whereIn('SOURCE.VALUE', [$enumId1, $enumId2])
    ->setOrder(['SORT' => 'ASC', 'ID' => 'DESC'])
    ->setLimit(10)
    ->fetchCollection();

foreach ($elements as $el)
{
    echo $el->getName();
    echo $el->getAuthor()?->getValue(); // single property
}
```

For properties of type "List" (`L`), "Element" (`E`), "Section" (`G`), ORM provides access to the related entity:

```php
// Property AUTHOR (List) -> CIBlockPropertyEnum
echo $el->getAuthor()->getItem()->getValue();
echo $el->getAuthor()->getItem()->getXmlId();
```

## SEO Templates

SEO values (Meta Title, Description, etc.) are stored in `IPROPERTY_TEMPLATES`.

```php
$iproperty = new \Bitrix\Iblock\InheritedProperty\ElementValues($iblockId, $elementId);
$seoValues = $iproperty->getValues();

echo $seoValues['ELEMENT_META_TITLE'];
```

## Checklist

- [ ] `API_CODE` is set in iblock settings.
- [ ] Properties have unique `CODE`.
- [ ] Elements/Sections are handled via ORM generated classes (`ElementXxxTable`).
- [ ] Iblock creation/deletion uses `CIBlock` / `CIBlockSection` for full cleanup.
- [ ] Permissions are set during iblock creation (`CIBlockRights` / `GROUP_ID`).
- [ ] Properties version 2 is used for performance where possible; property CRUD via `CIBlockProperty` (not raw `PropertyTable` writes).
- [ ] File properties are set via `PropertyValue`.
- [ ] Highload directory properties → skill `bitrix-highloadblock`.

## Performance

- Limit `select` to needed fields — avoid `['*']` on elements with many properties.
- Use ORM cache: `['cache' => ['ttl' => 3600]]` in queries.
- Avoid N+1: use `fetchCollection()` with relations in `select`, not per-element property fetches.
- `ElementTable` for ID+NAME lists is fine; for properties use compiled entity classes.
- Disable `UpdateSearch` on bulk imports when search index refresh is not needed.
