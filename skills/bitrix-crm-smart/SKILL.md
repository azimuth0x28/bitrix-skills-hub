---
name: bitrix-crm-smart
description: "Use when reading, filtering or updating CRM dynamic (smart process) items from code: search items by fields, replace users in fields, bulk transfer, stage/category filters. Covers Crm Service Container, Factory\\Dynamic, getDataClass, getUpdateOperation, Item, Context. Key terms — entityTypeId, getFactory, disableAllChecks, crm.type.factory, launch."
metadata:
  type: knowledge
  version: "1.0.0"
---

# Smart processes (`crm` dynamic entities)

Smart processes are CRM dynamic entities: resolve everything through `Bitrix\Crm\Service\Container` (dir
`crm/lib/Service` — capital S). Related skills: `bitrix-bizproc` (automation), `bitrix-orm` (query syntax).

Baseline: **main 23.0+**; facts verified against crm **25.700.0**.

## API choice matrix

| Task                     | API                                                                                |
|--------------------------|------------------------------------------------------------------------------------|
| Resolve factory          | `Bitrix\Crm\Service\Container::getInstance()->getFactory($entityTypeId): ?Factory` |
| Cheap ID/filter queries  | `$factory->getDataClass()::getList(['select' => ..., 'filter' => ...])`            |
| Load full item           | `$factory->getItem($id, array $fieldsToSelect = ['*']): ?Item`                     |
| Update with side effects | `$factory->getUpdateOperation($item, new Context([...]))->launch(): Main\Result`   |
| Field catalog            | `$factory->getFieldsInfo(): array`                                                 |
| Dynamic factory check    | `$factory instanceof Bitrix\Crm\Service\Factory\Dynamic`                           |

## Kernel facts

- `Factory\Dynamic::getDataClass(): string` resolves the generated ORM class via
  `ServiceLocator 'crm.type.factory' → getItemDataClass($type)` — call it as `$dataClass::getList(...)` /
  `$dataClass::update(...)`.
- `Context`: `new Context(['userId' => $id, 'scope' => Context::SCOPE_TASK])` — props `userId`, `scope` (`SCOPE_MANUAL`/
  `SCOPE_TASK`/`SCOPE_AUTOMATION`/`SCOPE_REST`/`SCOPE_AI`), `eventId`. `SCOPE_TASK` marks agents/background runs.
- `Bitrix\Crm\Item` (lib/item.php): `get(string $commonFieldName)`, `set(string $commonFieldName, $value): self` — *
  *common** field names, not raw entity columns; system `ID` is read-only.
- Operation pipeline on `launch()`: `preSaveChecks` → save → `updatePermissions` → search indexes → duplicates →
  counters.
- `Operation::disableAllChecks(): self` — for system commands (agents/cron have no current user; access checks would
  fail).
- OR search across fields via ORM filter: `['LOGIC' => 'OR', ['F1' => $v], ['F2' => $v]]` as a numeric sub-filter,
  AND-ed with extra conditions.

## Search by user fields + replace user (transfer pattern)

```php
<?php declare(strict_types=1);

use Bitrix\Crm\Service\Container;
use Bitrix\Crm\Service\Context;
use Bitrix\Crm\Service\Factory\Dynamic;
use Bitrix\Main\Loader;

Loader::includeModule('crm');

$factory = Container::getInstance()->getFactory($entityTypeId);
if (!$factory instanceof Dynamic)
{
    throw new \Bitrix\Main\ObjectNotFoundException("No factory for entityTypeId #{$entityTypeId}");
}

$orFilter = ['LOGIC' => 'OR'];
foreach ($searchFieldNames as $field)
{
    $orFilter[] = [$field => $fromUserId];
}

$rows = $factory->getDataClass()::getList([
    'select' => ['ID'],
    // extra filter AND-extends the OR conditions
    'filter' => array_merge([$orFilter], $extraFilter),
])->fetchAll();

// per item: compare, replace, launch
$item = $factory->getItem($itemId);
if ((int)$item->get($field) === $fromUserId)
{
    $item->set($field, $toUserId);
}

$operation = $factory->getUpdateOperation($item, new Context(['userId' => $fromUserId]));
$operation->disableAllChecks(); // system command: no current user in cron context

$operationResult = $operation->launch();
if (!$operationResult->isSuccess())
{
    throw new \RuntimeException(implode('; ', $operationResult->getErrorMessages()));
}
```

## Operation vs DataClass update fork

| Fork                                                   | Choose                                                                         |
|--------------------------------------------------------|--------------------------------------------------------------------------------|
| Business update (must be visible in UI)                | `getUpdateOperation()->launch()` — automation, timeline, counters, search fire |
| True low-level batch, side effects explicitly unwanted | `getDataClass()::update()`                                                     |

## Negative knowledge

- Directory is `crm/lib/Service` (capital S) — `lib/service` does not exist.
- `Factory::getItems()` hydrates full items — for ID lists use `getDataClass()::getList()`.
- No Factory method accepts a raw filter array — pass it to the data class getList.
- `launch()` runs `preSaveChecks` (access rights) — fails for current user without rights and in cron;
  `disableAllChecks()` exists for system operations.
- `$factory->getFieldsInfo()` may omit `UF_*` fields — unknown columns surface as ORM exceptions from getList, so
  validate field names or catch per item.

## Checklist

- [ ] Factory resolved via `Container::getInstance()->getFactory()`; null/`Dynamic` checked.
- [ ] Item updates via `getUpdateOperation()->launch()`; no raw `getDataClass()::update()` for business changes.
- [ ] `Main\Result` from `launch()` checked (`isSuccess()` / `getErrorMessages()`).
- [ ] `Context` set explicitly (`userId`, `SCOPE_TASK` for background runs).
- [ ] `disableAllChecks()` used only for system commands.
- [ ] Search fields validated (ORM exceptions surfaced per item, not swallowed).
- [ ] Lint clean (`php-cs-fixer` + `phpcs`, see `bitrix-codestyle`).
