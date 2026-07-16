# Writing / batch / upsert

## Writing

### Decision guide (write)

| Need | Prefer |
| --- | --- |
| One row, array data | `add()` / `update()` / `delete()` |
| Object state / relations | `EntityObject::save()` / collection `save()` |
| Many homogeneous rows | `addMulti()` / `updateMulti()` |
| Mass delete by filter (no per-row lifecycle) | `DeleteByFilterTrait::deleteByFilter()` with a **narrow** filter |
| Upsert: update on conflict | `MergeTrait::merge()` or `AddMergeTrait` |
| Upsert: ignore duplicate | `AddInsertIgnoreTrait` / `InsertIgnoreByDefaultTrait` |

Rules:

- Batch methods are not a substitute for Objectify when relations/state matter.
- Empty filter for `deleteByFilter()` is forbidden (not a truncate).
- `addMerge` / `addInsertIgnore` often skip normal events — use only when that is an intentional contract.
- `ignoreEvents` on multi-write is an explicit trade-off, not a default speed hack.
- Prefer ORM write APIs that already call `cleanCache()`; do not assume cache clears after raw SQL.

### Arrays

```php
$add = PostTable::add(['TITLE' => 'Hi', 'AUTHOR_ID' => 1]);
if (!$add->isSuccess())
{
    $this->addErrors($add->getErrors());
    return;
}
$id = $add->getId();

PostTable::update($id, ['TITLE' => 'Hello']);
PostTable::delete($id);
```

### Objects

```php
$post = PostTable::createObject();
$post->setTitle('Title')
     ->setBody('Body')
     ->setAuthorId($currentUserId);

$save = $post->save();
if (!$save->isSuccess()) { /* ... */ }

$loaded = PostTable::getByPrimary(10)->fetchObject();
$loaded->setTitle('Updated');
$loaded->save();
$loaded->delete();
```

Collections:

```php
$collection = PostTable::query()->whereIn('ID', [1, 2])->fetchCollection();
foreach ($collection as $post)
{
    $post->setActive(false);
}
$collection->save();
```

### Batch

```php
PostTable::addMulti([
    ['TITLE' => 'A', 'AUTHOR_ID' => 1],
    ['TITLE' => 'B', 'AUTHOR_ID' => 1],
]);

PostTable::updateMulti(
    [['ID' => 100], ['ID' => 101]],
    ['ACTIVE' => 'N'],
);
```

### Mass delete (`DeleteByFilterTrait`)

```php
use Bitrix\Main\ORM\Data\DataManager;
use Bitrix\Main\ORM\Data\Internal\DeleteByFilterTrait;
use Bitrix\Main\ORM\Query\Query;

final class ArchivedPostTable extends DataManager
{
    use DeleteByFilterTrait;
    // getTableName / getMap …
}

ArchivedPostTable::deleteByFilter(
    Query::filter()
        ->where('AUTHOR_ID', $authorId)
        ->where('ACTIVE', 'N')
);
```

### Merge / InsertIgnore

```php
use Bitrix\Main\ORM\Data\Internal\MergeTrait;
use Bitrix\Main\ORM\Data\AddStrategy\Trait\AddInsertIgnoreTrait;

final class PortalLinkTable extends DataManager
{
    use MergeTrait;
}

PortalLinkTable::merge(
    ['PORTAL_ID' => $portalId, 'EXTERNAL_ID' => $externalId, 'TITLE' => $title],
    ['TITLE' => $title],
);

final class SyncMarkerTable extends DataManager
{
    use AddInsertIgnoreTrait;
}

SyncMarkerTable::addInsertIgnore([
    'ENTITY_ID' => $entityId,
    'MARKER' => $marker,
]);
```

Conflict semantics: **ignore** = keep existing row; **merge** = update existing row. Do not treat them as one generic “upsert”.
