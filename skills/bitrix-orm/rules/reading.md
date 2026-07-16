# Reading / filters

## Reading Data

### Decision guide (read)

| Need | Prefer |
| --- | --- |
| New query in new code | `DataManager::query()` + fluent API |
| Nested / OR / EXISTS / column-to-column filter | `Query::filter()` → `ConditionTree` (`where*`, `logic()`) |
| Entity + relations / further mutation | `fetchObject()` / `fetchCollection()` |
| Flat list, aggregation, hot path | `fetch()` / `fetchAll()` |
| Legacy file already on array API | `getList()` / array `filter` (compatibility only) |
| Reuse ORM filter as SQL WHERE | `Query::buildFilterSql($entity, $filter)` |

Rules:

- Prefer `query()` over `getList()` / `getRow()` for new code (`getList` is a wrapper).
- Prefer `ConditionTree` over legacy `'=FIELD' => $value` arrays for new filters.
- Do **not** use object fetch for `GROUP BY` / aggregated result shapes.
- Register runtime fields as `ExpressionField` objects — not array-expressions in `select`.
- `disableDataDoubling()` only when a 1:N back-reference filter duplicates rows — not a default accelerator.
- Private fields: call `enablePrivateFields()` explicitly when needed.

### Preferred: `query()` + `ConditionTree`

```php
use Bitrix\Main\ORM\Query\Query;

$visibility = Query::filter()
    ->logic('or')
    ->where('AUTHOR_ID', $userId)
    ->where('PUBLIC', 'Y');

$posts = PostTable::query()
    ->setSelect(['ID', 'TITLE', 'AUTHOR_ID'])
    ->where('ACTIVE', 'Y')
    ->where($visibility)
    ->setOrder(['CREATED_AT' => 'DESC'])
    ->setLimit(20)
    ->fetchAll();
```

### Objects (`fetchObject`, `fetchCollection`)

```php
$post = PostTable::query()
    ->setSelect(['*', 'AUTHOR', 'COMMENTS'])
    ->where('ID', $id)
    ->fetchObject();

$title = $post?->getTitle();
$authorName = $post?->getAuthor()?->getName();

$collection = PostTable::query()
    ->setSelect(['*', 'COMMENTS'])
    ->where('ACTIVE', 'Y')
    ->fetchCollection();
```

### Query builder (runtime / aggregates)

```php
use Bitrix\Main\ORM\Fields\ExpressionField;

$query = PostTable::query()
    ->setSelect(['ID', 'TITLE', new ExpressionField('CNT', 'COUNT(%s)', 'COMMENTS.ID')])
    ->registerRuntimeField(
        new ExpressionField('IS_NEW', 'CASE WHEN %s > NOW() - INTERVAL 7 DAY THEN 1 ELSE 0 END', 'CREATED_AT')
    )
    ->where('ACTIVE', 'Y')
    ->whereIn('AUTHOR_ID', [1, 2, 3])
    ->addOrder('CREATED_AT', 'DESC')
    ->setLimit(50)
    ->setGroup(['ID'])
    ->having('CNT', '>', 0);

// Aggregates → fetchAll(), not fetchObject()
$result = $query->fetchAll();
```

### `buildFilterSql` (bridge to raw / mass ops)

```php
$filter = Query::filter()
    ->where('PROJECT_ID', $projectId)
    ->whereNotNull('ARCHIVED_AT');

$whereSql = Query::buildFilterSql(PostTable::getEntity(), $filter);
```

### Legacy: `getList` + array filter

```php
$rows = PostTable::getList([
    'select' => ['ID', 'TITLE', 'AUTHOR_NAME' => 'AUTHOR.NAME'],
    'filter' => ['=ACTIVE' => 'Y'],
    'order'  => ['CREATED_AT' => 'DESC'],
    'limit'  => 20,
    'cache'  => ['ttl' => 3600],
])->fetchAll();
```

Use only in existing array-style code or tiny compatibility patches.

## Collections and Annotations

After `orm:annotate`, IDE gets types like `EO_Post`, `EO_Post_Collection`, `EO_Post_Query`:

```php
/** @var \Vendor\Module\Model\EO_Post $post */
$post = PostTable::getByPrimary($id)->fetchObject();

/** @var \Vendor\Module\Model\EO_Post_Collection $posts */
$posts = PostTable::query()->where('ACTIVE', 'Y')->fetchCollection();
```

Collection methods: `save()`, `delete()`, `fill()` (eager load relations). Use `fetchCollection()` instead of looping `fetchObject()` to avoid N+1.
