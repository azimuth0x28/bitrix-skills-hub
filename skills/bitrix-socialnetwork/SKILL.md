---
name: bitrix-socialnetwork
description: "Use when managing workgroup/project membership or ownership from code: add/remove members, read or change roles, transfer group owner, query groups by member. Covers UserToGroupTable, WorkgroupTable, CSocNetUserToGroup, SetOwner. Key terms — SONET_ROLES_OWNER, b_sonet_user2group, AddUsersToGroup, OWNER_ID."
metadata:
  type: knowledge
---

# Workgroups & projects (`socialnetwork`)

Sonet groups cover projects, collabs and scrum teams: membership rows in `b_sonet_user2group`, group row (`OWNER_ID`,
name) in `b_sonet_group`. Related skills: `bitrix-tasks`, `bitrix-orm`. Baseline: **main 23.0+**; facts verified against
socialnetwork **25.350.0** in this project's kernel.

## API choice matrix

| Task                               | API                                                                     |
|------------------------------------|-------------------------------------------------------------------------|
| Read roles/memberships             | `Bitrix\Socialnetwork\UserToGroupTable` (`b_sonet_user2group`)          |
| Group row (`OWNER_ID`, name, type) | `Bitrix\Socialnetwork\WorkgroupTable`                                   |
| Remove member (with side effects)  | `\CSocNetUserToGroup::Delete($relationId): bool`                        |
| Add members (plain, immediate)     | `\CSocNetUserToGroup::AddUsersToGroup($groupId, $userIds): Main\Result` |
| Transfer ownership                 | `\CSocNetUserToGroup::SetOwner($userId, $groupId): bool`                |
| Edit one relation row              | `\CSocNetUserToGroup::Update($id, $fields): bool`                       |

**Membership writes go through `CSocNetUserToGroup` only** — chat membership, subscriptions, sonet log and counters hang
on its events.

## Role constants

| `UserToGroupTable` const | Value | Meaning               |
|--------------------------|-------|-----------------------|
| `ROLE_OWNER`             | `A`   | руководитель/владелец |
| `ROLE_MODERATOR`         | `E`   | модератор             |
| `ROLE_USER`              | `K`   | участник              |
| `ROLE_BAN`               | `T`   | исключён              |
| `ROLE_REQUEST`           | `Z`   | заявка на вступление  |

Global defines `SONET_ROLES_*` in `socialnetwork/include.php` mirror them — prefer class constants.

## SetOwner pipeline (order is semantic)

`CSocNetUserToGroup::SetOwner($userId, $groupId)` in one DB transaction: demotes old owner (group's `OWNER_ID`) row to
`ROLE_USER` (`ROLE_MODERATOR` when old owner is SCRUM master) → promotes new owner relation to `ROLE_OWNER` →
`\CSocNetGroup::Update($groupId, ['OWNER_ID' => $new])`. Failure → rollback + `$APPLICATION->ThrowException`, returns
`false`. Initiator recorded as `$USER->GetID()`.

## Legacy error handling

Legacy API returns `bool` and pushes errors to `$APPLICATION` — unwrap them, never swallow:

```php
if (!\CSocNetUserToGroup::Delete($relationId))
{
    $ex = $GLOBALS['APPLICATION']?->GetException();

    throw new \RuntimeException($ex !== null ? $ex->GetString() : 'Failed to delete project member');
}
```

## Membership transfer pattern

```php
<?php declare(strict_types=1);

use Bitrix\Main\Loader;
use Bitrix\Socialnetwork\UserToGroupTable;
use Bitrix\Socialnetwork\WorkgroupTable;

Loader::includeModule('socialnetwork');

$fromRows = UserToGroupTable::query()
    ->setSelect(['ID', 'ROLE'])
    ->where('GROUP_ID', $groupId)
    ->where('USER_ID', $fromUserId)
    ->whereIn('ROLE', [UserToGroupTable::ROLE_OWNER, UserToGroupTable::ROLE_USER])
    ->fetchAll();

$toRelation = UserToGroupTable::query()
    ->setSelect(['ID', 'ROLE'])
    ->where('GROUP_ID', $groupId)
    ->where('USER_ID', $toUserId)
    ->fetch();

// remove source membership first, then give the role to the receiver
foreach ($fromRows as $row)
{
    \CSocNetUserToGroup::Delete((int)$row['ID']);
}

if ($toRelation === null)
{
    \CSocNetUserToGroup::AddUsersToGroup($groupId, [$toUserId]);
}

// if the source was owner — canonical handover: roles + OWNER_ID + chat
// \CSocNetUserToGroup::SetOwner($toUserId, $groupId);
```

## Negative knowledge

- Class names are `CSocNetGroup` / `CSocNetUserToGroup` (Soc**Net**) — `CSonetGroup` does not exist.
- Global constants are `SONET_ROLES_*` (plural ROLES) — `SONET_ROLE_OWNER` does not exist; prefer class constants
  `UserToGroupTable::ROLE_*`.
- `CSocNetUserToGroup::Update()` is defined in `classes/mysql/user_group.php` (DB layer), not `classes/general/`.
- `CSocNetGroup::Update` validates `OWNER_ID` via `CUser::GetByID` but does **not** swap role rows — role changes belong
  to `SetOwner`.
- `AddUsersToGroup` is a plain `addMulti` insert as `ROLE_USER` — no invite flow, no side effects.

## Checklist

- [ ] Membership writes via `\CSocNetUserToGroup::Delete/AddUsersToGroup/Update/SetOwner`; no raw `UserToGroupTable`
  writes.
- [ ] Owner change via `SetOwner`, never `WorkgroupTable::update(['OWNER_ID' => ...])`.
- [ ] Roles via `UserToGroupTable::ROLE_*` constants.
- [ ] Legacy failures unwrapped from `$APPLICATION->GetException()` into exceptions/`Result`.
- [ ] `AddUsersToGroup` result `isSuccess()` checked.
- [ ] Lint clean (`php-cs-fixer` + `phpcs`, see `bitrix-codestyle`).