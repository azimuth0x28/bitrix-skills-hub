# Filters and attributes

## Default Prefilters

By default, actions get: `Authentication` + `HttpMethod([GET, POST])` + `Csrf`.

When overriding `getDefaultPreFilters()`, **extend** `parent::getDefaultPreFilters()` — do not rebuild the base protection from scratch without reason.

Guests fail the default `Authentication` → **401** without redirect (`bitrix/modules/main/lib/engine/actionfilter/authentication.php`). Guest access to an action = drop the prefilter for that action: `#[DisablePrefilters([ActionFilter\Authentication::class, ActionFilter\Csrf::class])]` or `'-prefilters'` in `configureActions()`, optionally re-adding `Attribute\Rule\*` rules per action. There is **no `allowAnonymous()`** API — prefilters are the only switch.

## Action Filters

Predefined filters:

- `ActionFilter\Authentication` — requires an authorized user (401 without redirect).
- `ActionFilter\Csrf` — `sessid`/`X-Bitrix-Csrf-Token` check. **Limited to `SCOPE_AJAX`** (`listAllowedScopes()`); does not run for REST/CLI scopes.
- `ActionFilter\HttpMethod([...])` — method restriction.
- `ActionFilter\CloseSession` — closes session before action (parallel AJAX).
- `ActionFilter\ContentType(['application/json'])` — allowed `Content-Type`.
- `ActionFilter\Scope($scope)` — restricts call to a specific scope (ajax/rest/cli).
- `ActionFilter\Cors` — CORS headers for cross-origin AJAX.
- `ActionFilter\AccessCheck` / `#[ActionAccess]` — module ACL via `AccessibleController` (see below).
- `ActionFilter\Token` — signed entity token in request headers (`X-Bitrix-Sign-Entity` / `X-Bitrix-Sign-Token` via `ActionFilter\Service\Token`). Niche; prefer CSRF + rights for ordinary AJAX.

If a built-in filter is missing, write a custom `ActionFilter\Base` — do not copy-paste checks into every action.

## `#[ActionAccess]` (module ACL)

When the module already has an `access` controller (`Bitrix\Main\Access\AccessibleController` / `BaseAccessController`), check the action with `#[ActionAccess]` instead of a hand-rolled rights filter.

The controller **must** implement `Bitrix\Main\Engine\Contract\AccessCheckControllerInterface` and return the access controller from `getAccessController()`. Otherwise `AccessCheck` throws `SystemException`.

Default strategy is `ItemIdFromRequestStrategy`: it reads a request key (default `id`) and calls `checkByItemId($action, $itemId)`. Override the key with `strategyArgs`.

```php
use Bitrix\Main\Access\AccessibleController;
use Bitrix\Main\Engine\ActionFilter\Access\ItemIdFromRequestStrategy;
use Bitrix\Main\Engine\ActionFilter\Attribute\Access\ActionAccess;
use Bitrix\Main\Engine\Contract\AccessCheckControllerInterface;
use Bitrix\Main\Engine\CurrentUser;

final class Post extends Controller implements AccessCheckControllerInterface
{
    public function getAccessController(): AccessibleController
    {
        return PostAccessController::getInstance((int)CurrentUser::get()->getId());
    }

    #[ActionAccess(
        action: PostActionDictionary::VIEW, // string or UnitEnum (BackedEnum → value, else → name)
        strategy: ItemIdFromRequestStrategy::class,
        strategyArgs: ['itemIdRequestKey' => 'id'],
    )]
    public function getAction(int $id, PostService $postService): array
    {
        // ...
    }
}
```

`#[ActionAccess]` does **not** set HTTP 403 by default (`setHttpStatus` is only on `AccessCheck` itself, default `false`). The action is rejected with an engine error; set status yourself in a custom strategy/`AccessCheck` if the HTTP code matters.

Custom strategies implement `AccessCheckStrategyInterface::create()` + `check()`. Do not use `#[ActionAccess]` unless the module actually has an access controller — for simple auth keep `Authentication` / a small `ActionFilter\Base`.

## PHP 8 Attribute Filters (preferred)

```php
use Bitrix\Main\Engine\ActionFilter;
use Bitrix\Main\Engine\ActionFilter\Attribute\Rule\Prefilters;
use Bitrix\Main\Engine\ActionFilter\Attribute\Rule\HttpMethod;
use Bitrix\Main\Engine\ActionFilter\Attribute\Rule\Authentication;
use Bitrix\Main\Engine\ActionFilter\Attribute\Rule\Csrf;
use Bitrix\Main\Engine\ActionFilter\Attribute\Rule\EnablePrefilters;
use Bitrix\Main\Engine\ActionFilter\Attribute\Rule\DisablePrefilters;

final class Post extends Controller
{
    #[HttpMethod([HttpMethod::METHOD_GET])]
    #[DisablePrefilters([ActionFilter\Csrf::class])]
    public function listAction(): array { /* ... */ }

    #[Authentication]
    #[HttpMethod([HttpMethod::METHOD_POST])]
    #[Csrf]
    public function createAction(string $title): array { /* ... */ }

    #[DisablePrefilters([ActionFilter\Authentication::class, ActionFilter\Csrf::class])]
    #[EnablePrefilters([
        new ActionFilter\HttpMethod([ActionFilter\HttpMethod::METHOD_GET]),
    ])]
    public function publicPingAction(): array
    {
        return ['ok' => true];
    }
}
```

**Name-collision trap:** `ActionFilter\HttpMethod` (filter class, no `#[Attribute]`) and `ActionFilter\Attribute\Rule\HttpMethod` (attribute) are different classes. The attribute reader reads only attributes implementing `FilterAttributeInterface` (`bitrix/modules/main/lib/engine/actionfilter/attribute/attributereader.php`): a filter class used in attribute position is silently ignored and the restriction disappears.

Controller-level defaults via `getDefaultPreFilters()` / `getDefaultPostFilters()`. Use `#[EnablePrefilters]` / `#[DisablePrefilters]` to adjust inherited defaults per action.

### `configureActions()` (compatibility)

Use when attributes are insufficient or when patching legacy controllers:

```php
public function configureActions(): array
{
    return [
        'get' => [
            '+prefilters' => [new ActionFilter\HttpMethod([ActionFilter\HttpMethod::METHOD_GET])],
            '-prefilters' => [ActionFilter\Csrf::class],
        ],
    ];
}
```

Format keys: `prefilters` (replace), `+prefilters` (add), `-prefilters` (remove by FQCN), `postfilters`.
