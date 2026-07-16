# Events, cache, security

## Events

In the tablet class:

```php
public static function onBeforeAdd(\Bitrix\Main\ORM\Event $event): \Bitrix\Main\ORM\EventResult
{
    $result = new \Bitrix\Main\ORM\EventResult();
    $fields = $event->getParameter('fields');

    if (empty($fields['TITLE']))
    {
        $result->addError(new \Bitrix\Main\ORM\EntityError('Title is required'));
    }

    // Modification:
    $result->modifyFields(['TITLE' => strtoupper($fields['TITLE'])]);

    return $result;
}
```

Events: `onBeforeAdd`, `onAfterAdd`, `onBeforeUpdate`, `onAfterUpdate`, `onBeforeDelete`, `onAfterDelete`.

## Caching

```php
'cache' => [
    'ttl' => 3600,
    'cache_joins' => true,
]
```

- Tablet must return `true` from `isCacheable()` (default is `true` on `DataManager`).
- On successful add/update/delete, ORM calls `DataManager::cleanCache()` → managed cache dir `orm_<tableName>` (e.g. `orm_vendor_module_post`). There are **no** fictional `ORM_*` tagged-cache tags for this — invalidation is by managed-cache directory.
- TTL can be clamped via global `.settings.php` `cache_flags` keys `<table>_min_ttl` / `<table>_max_ttl` (see `Entity::getCacheTtl`). Details: skill `bitrix-caching`.

```php
PostTable::cleanCache(); // after external bulk SQL that bypasses ORM writes
```

## Security: User Input in Queries

Field names in `select` / `order` and expressions in `ExpressionField` / `runtime` / `SqlExpression` are **not** safely escaped as identifiers. Never pass request parameters into them without a whitelist. Prefer bound filter values (`where`, `filter` values). Full patterns: skill `bitrix-security`.

```php
// BAD: $order = $_GET['by'];
// GOOD:
$allowed = ['ID', 'CREATED_AT', 'TITLE'];
$order = in_array($userBy, $allowed, true) ? $userBy : 'ID';
PostTable::getList(['order' => [$order => 'DESC']]);
```

## Checklist

- [ ] Tablet class lives in `lib/Model/` and ends in `Table` (extends `DataManager`).
- [ ] Primary keys are correctly defined (`configurePrimary`); fluent `configureXxx` for fields.
- [ ] New reads use `query()` + `ConditionTree` (not `getList`/array filter by default).
- [ ] Fetch shape matches need: objects for entity/relations; arrays for lists/aggregates.
- [ ] Object fetch is not used for aggregation / `GROUP BY`.
- [ ] Runtime fields registered as field objects; `disableDataDoubling()` only for 1:N filter duplication.
- [ ] Writes: `save()` for object/relations; `add`/`update` for simple rows; multi for homogeneous batches.
- [ ] `deleteByFilter` / merge / insert-ignore used only with intentional semantics and narrow filters.
- [ ] Cache: `isCacheable` + `cleanCache` / `orm_*` dirs understood; no fictional `ORM_*` tags.
- [ ] No user input in `select` / `order` / `ExpressionField` / `runtime` without whitelist.
- [ ] UF via `getUfId()`, not deprecated `UField`; `orm:annotate` run for IDE.
