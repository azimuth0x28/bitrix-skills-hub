---
name: bitrix-tasks
description: "Use when reading, filtering, searching or updating tasks from PHP code: change responsible, creator, accomplices, auditors; transfer/reassign tasks; filter by status. Covers tasks V2 services, UpdateTaskService, UpdateConfig, TaskTable, MemberTable, Status. Key terms — cloneWith, UserCollection, MEMBER_TYPE_ACCOMPLICE, b_tasks_member."
metadata:
  type: knowledge
---

# Tasks module (`tasks`)

Two layers: **Internals ORM** (`Bitrix\Tasks\Internals\...`) for cheap reads, and **tasks V2** (
`Bitrix\Tasks\V2\Internal\...`) for entity loads and updates with full side effects. Related skills: `bitrix-orm` (query
basics), `bitrix-result-and-errors`. Baseline: **main 23.0+**; facts verified against tasks **25.675.0** in this
project's kernel.

## API choice matrix

| Task                                                            | API                                                                     |
|-----------------------------------------------------------------|-------------------------------------------------------------------------|
| Query tasks by columns (ID, RESPONSIBLE_ID, CREATED_BY, STATUS) | `Bitrix\Tasks\Internals\TaskTable::query()`                             |
| Load full task entity incl. members (creator/responsible/…)     | `Container::getInstance()->getTaskRepository()->getById($id): ?Task`    |
| Update task with side effects                                   | `getUpdateTaskService()->update($task, new UpdateConfig(userId: $uid))` |
| Find users by task role                                         | `Bitrix\Tasks\Internals\Task\MemberTable` → `b_tasks_member`            |
| Status ints                                                     | `Bitrix\Tasks\Internals\Task\Status` class constants                    |

**All writes go through `UpdateTaskService`.** Direct `TaskTable::update()` skips members, counters, notifications,
search index.

## Kernel facts

- Container: `Bitrix\Tasks\V2\Internal\DI\Container::getInstance()` → `getTaskRepository()`, `getUpdateTaskService()`.
- `Entity\Task` readonly props: `creator`, `responsible` (`?User`, `->getId()`), `accomplices`, `auditors` (
  `?UserCollection`), `status`. Modify via `$task->cloneWith([...])` — whole-list replacement.
- `UserCollection`: `mapFromIds([1,2])`, `->getFirstEntity()`, `->getIdList()`.
- `MemberTable` (`b_tasks_member`): `MEMBER_TYPE_ORIGINATOR`=`O` (originator, постановщик), `MEMBER_TYPE_RESPONSIBLE`=`R` (responsible),
  `MEMBER_TYPE_ACCOMPLICE`=`A` (accomplice, соисполнитель), `MEMBER_TYPE_AUDITOR`=`U` (auditor, наблюдатель).
- `Status`: `NEW`=1, `PENDING`=2, `IN_PROGRESS`=3, `SUPPOSEDLY_COMPLETED`=4, `COMPLETED`=5, `DEFERRED`=6, `DECLINED`
  =7. "Not completed" → `whereNotIn('STATUS', [4, 5])`.
- `UpdateConfig` named args: `userId` (acting user), `needCorrectDatePlan`, `needAutoclose`, `skipNotifications`,
  `skipPush`, `skipBP`, `skipComments`, `byPassParameters`. Defaults send notifications and push.

## Update pipeline (order is semantic)

`update()` → validation → `EntityFieldService::prepare` → `repository->save()` (ORM write, incl. `CREATED_BY` mapped
from `creator`) → `UpdateMembers` → files/tags → notifications/push/counters. Fields are persisted **before**
member/notification actions — an exception mid-pipeline leaves partially updated rows; catch per item and report.

## Replace a user across roles (transfer pattern)

```php
<?php declare(strict_types=1);

use Bitrix\Main\Loader;
use Bitrix\Tasks\V2\Internal\DI\Container as TaskContainer;
use Bitrix\Tasks\V2\Internal\Entity\UserCollection;
use Bitrix\Tasks\V2\Internal\Service\Task\Action\Update\Config\UpdateConfig;

Loader::includeModule('tasks');

$container = TaskContainer::getInstance();
$task = $container->getTaskRepository()->getById($taskId);

if ($task !== null && $task->responsible?->getId() === $fromUserId)
{
    $container->getUpdateTaskService()->update(
        $task->cloneWith([
            'responsible' => UserCollection::mapFromIds([$toUserId])->getFirstEntity(),
            // 'creator' => ... — persisted too: ORM mapper writes CREATED_BY
            // 'accomplices' => UserCollection::mapFromIds($ids),
            // 'auditors'   => UserCollection::mapFromIds($ids),
        ]),
        new UpdateConfig(userId: $fromUserId),
    );
}
```

Find tasks where a user holds any role:

```php
use Bitrix\Tasks\Internals\Task\MemberTable;
use Bitrix\Tasks\Internals\TaskTable;

$ids = MemberTable::query()
    ->setSelect(['TASK_ID'])
    ->where('USER_ID', $userId)
    ->whereIn('TYPE', [
        MemberTable::MEMBER_TYPE_ORIGINATOR,
        MemberTable::MEMBER_TYPE_RESPONSIBLE,
        MemberTable::MEMBER_TYPE_ACCOMPLICE,
        MemberTable::MEMBER_TYPE_AUDITOR,
    ])
    ->fetchAll();
```

## V2 vs Internals fork

| Fork                                | Choose                                                             |
|-------------------------------------|--------------------------------------------------------------------|
| Persisting anything                 | V2 `UpdateTaskService` — members/counters/notifications fire       |
| Bulk reads, analytics, ID filtering | `TaskTable::query()` — no side effects                             |
| System commands (agents/cron)       | V2 internal services bypass ACL — still validate user ids yourself |

## Negative knowledge

- `TaskTable` has **no** STATUS_* constants — use `Bitrix\Tasks\Internals\Task\Status` (legacy `\CTasks::STATE_*` live
  in `classes/general/task.php`).
- V2 update does **no ACL and no user-existence checks** — ghost ids write through to `RESPONSIBLE_ID`/`CREATED_BY`.
  Validate via `Bitrix\Main\UserTable` first.
- `$task->responsible` is a `User` entity; `$task->status` is a typed `Status` object — ints come from `TaskTable` rows
  only.
- V2 `Task` entity is readonly — modifications only via `cloneWith()`.

## Checklist

- [ ] Writes via `getUpdateTaskService()->update()`; no direct `TaskTable::update()`.
- [ ] User ids validated against `UserTable` before writing.
- [ ] Roles via `MemberTable::MEMBER_TYPE_*`, no string literals.
- [ ] Statuses via `Status` constants.
- [ ] Whole-list replacement via `cloneWith` + `UserCollection::mapFromIds`.
- [ ] `UpdateConfig(userId:)` set explicitly.
- [ ] Lint clean (`php-cs-fixer` + `phpcs`, see `bitrix-codestyle`).