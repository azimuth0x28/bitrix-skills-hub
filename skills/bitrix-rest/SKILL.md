---
name: bitrix-rest
description: Covers REST module — registering methods from a custom module, scopes, webhook and OAuth overview, rest / restIntegration settings, link to Engine controllers and ActionFilter\Scope::REST. Applied when exposing module APIs to apps, webhooks, or marketplace integrations. Key terms — rest, OnRestServiceBuildDescription, CRestUtil, scope, webhook, OAuth, APAuth, restIntegration, Scope::REST, BX.rest.callMethod.
---

# REST API (`rest`)

The `rest` module exposes HTTP methods under the configured path (default `/rest/`, option `rest.rest_server_path`). Baseline: main **23.0+**. Prefer **Engine controllers + `restIntegration`** for new module APIs; keep classic `OnRestServiceBuildDescription` for explicit method maps / events / placements.

```php
\Bitrix\Main\Loader::includeModule('rest');
```

## Two Registration Paths

| Approach | How | Typical use |
| --- | --- | --- |
| **Engine controller** | Module `.settings.php` → `controllers.restIntegration.enabled` | New CRUD/actions; same class as AJAX |
| **Classic description** | Event `rest` / `OnRestServiceBuildDescription` | Custom method names, REST events, placements |

Discovery of controller methods: `Bitrix\Rest\Engine\RestManager::onFindMethodDescription` requires `restIntegration.enabled` for that module.

## Enable Controllers for REST

`/local/modules/vendor.module/.settings.php`:

```php
<?php declare(strict_types=1);

return [
    'controllers' => [
        'value' => [
            'defaultNamespace' => '\\Vendor\\Module\\Infrastructure\\Controller',
            'restIntegration' => [
                'enabled' => true,
                // 'hideModuleScope' => true,  // optional; see ScopeManager
                // 'scopes' => ['myscope'],    // extra scopes advertised for the module
            ],
        ],
        'readonly' => true,
    ],
];
```

Call from JS: `BX.rest.callMethod('vendor.module.post.create', {...})` (same action name family as `BX.ajax.runAction('vendor:module.post.create')` — note `:` vs `.`).

Restrict an action to REST only (or exclude REST) with `Bitrix\Main\Engine\ActionFilter\Scope`:

```php
<?php declare(strict_types=1);

use Bitrix\Main\Engine\ActionFilter;

// ActionFilter\Scope::REST, ::AJAX, ::CLI, ::ALL, ::NOT_REST, ...
new ActionFilter\Scope(ActionFilter\Scope::REST);
```

Default AJAX CSRF filter does **not** apply to REST scope — design auth via REST app tokens / webhooks. Details: `bitrix-controllers`, `bitrix-security`.

## Classic Method Registration

Register in module `install/index.php` (unregister on uninstall):

```php
$eventManager->registerEventHandler(
    'rest',
    'OnRestServiceBuildDescription',
    'vendor.module',
    '\\Vendor\\Module\\Rest\\ServiceDescription',
    'onRestServiceBuildDescription'
);
```

Handler shape (same pattern as `Bitrix\Main\Rest\Handlers`):

```php
<?php declare(strict_types=1);

namespace Vendor\Module\Rest;

final class ServiceDescription
{
    public static function onRestServiceBuildDescription(): array
    {
        return [
            'vendor.module' => [
                'vendor.module.item.get' => [Item::class, 'get'],
                // Optional specials:
                // \CRestUtil::EVENTS => [...],
                // \CRestUtil::PLACEMENTS => [...],
            ],
        ];
    }
}
```

- Top-level keys are **scopes** (permission units granted to the app).
- `\CRestUtil::GLOBAL_SCOPE` (`'_global'`) for methods available without a dedicated scope (use sparingly).
- Method handler signature follows `IRestService` / classic REST callbacks (`$query`, `$n`, `\CRestServer $server`).

Provider aggregates all handlers via `GetModuleEvents("rest", "OnRestServiceBuildDescription")` (`CRestProvider`).

## Scopes

- App installs with a list of scopes; methods outside granted scopes are rejected.
- Module can advertise scopes via `restIntegration.scopes` and/or classic description keys.
- `Bitrix\Rest\Engine\ScopeManager` builds the scope catalog from modules with REST integration.
- Module `.settings.php` may also define a top-level **`rest`** section (routes/documentation namespace) — see `bitrix/modules/rest/.settings.php` and `main`’s `rest.defaultNamespace`. This is **not** a substitute for registering methods.

## Auth Overview: OAuth, Webhook, APAuth

| Mode | Idea |
| --- | --- |
| **OAuth** | Local apps / Bitrix24-style apps; tokens via OAuth engine (`Bitrix\Rest\OAuth\Auth`, `onRestCheckAuth`) |
| **Incoming webhook** | Per-user webhook URL embedding user id + password secret; `CRestUtil::getWebhookEndpoint($ap, $userId, $method)` → `{endpoint}{userId}/{ap}/{method}/` |
| **APAuth** | Application passwords / permission tables (`rest.service.apauth.*` in rest `.settings.php`) |
| **Session auth** | Browser session for some in-product calls (`Bitrix\Rest\SessionAuth\Auth`) |

Endpoint base: `CRestUtil::getEndpoint()` (site + `rest_server_path`).

Do not invent token formats — use admin UI / REST app tools to issue webhooks and OAuth credentials. Protect secrets; never commit webhook passwords.

## Batch and Limits

`CRestUtil::BATCH_MAX_LENGTH` (50) limits batch size. Prefer server-side batching over huge client loops.

## Checklist

- [ ] `rest` module installed; custom code only in `/local/modules/...`.
- [ ] New APIs: controller + `restIntegration.enabled` (and filters/scopes intentional).
- [ ] Classic methods: `OnRestServiceBuildDescription` registered and removed on uninstall.
- [ ] Scope names stable; documented for app install.
- [ ] No reliance on AJAX CSRF for REST; auth is token/webhook/OAuth.
- [ ] Errors returned in REST-friendly form (controller `addError` / REST exceptions), not raw HTML.
- [ ] Webhook/OAuth secrets kept out of VCS.

## Related skills

`bitrix-controllers`, `bitrix-security`, `bitrix-modules`, `bitrix-events`, `bitrix-settings`.
