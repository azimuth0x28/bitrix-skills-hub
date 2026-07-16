# Filters and attributes

## Default Prefilters

By default, actions get: `Authentication` + `HttpMethod([GET, POST])` + `Csrf`.

When overriding `getDefaultPreFilters()`, **extend** `parent::getDefaultPreFilters()` — do not rebuild the base protection from scratch without reason.

## Action Filters

Predefined filters:

- `ActionFilter\Authentication` — requires an authorized user (401 without redirect).
- `ActionFilter\Csrf` — `sessid`/`X-Bitrix-Csrf-Token` check. **Limited to `SCOPE_AJAX`** (`listAllowedScopes()`); does not run for REST/CLI scopes.
- `ActionFilter\HttpMethod([...])` — method restriction.
- `ActionFilter\CloseSession` — closes session before action (parallel AJAX).
- `ActionFilter\ContentType(['application/json'])` — allowed `Content-Type`.
- `ActionFilter\Scope($scope)` — restricts call to a specific scope (ajax/rest/cli).
- `ActionFilter\Cors` — CORS headers for cross-origin AJAX.

If a built-in filter is missing, write a custom `ActionFilter\Base` — do not copy-paste checks into every action.

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
