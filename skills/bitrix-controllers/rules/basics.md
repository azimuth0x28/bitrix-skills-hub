# Location, thin controller, autowire

## Location and Naming

- Files: `/local/modules/<vendor>.<module>/lib/Infrastructure/Controller/<Name>.php`.
- Namespace (default): `\Vendor\Module\Infrastructure\Controller\<Name>`.
- Public URL for AJAX: `/bitrix/services/main/ajax.php?action=vendor:module.<name>.<action>`.
- URL can be rewritten by a route (see `bitrix-routing`).

Namespace configuration — in `/local/modules/vendor.module/.settings.php`:

```php
'controllers' => [
    'value' => [
        'defaultNamespace' => '\\Vendor\\Module\\Infrastructure\\Controller',
        'namespaces' => [
            '\\Vendor\\Module\\Infrastructure\\Controller\\Web' => 'web',
        ],
        'restIntegration' => ['enabled' => true], // for REST
    ],
    'readonly' => true,
],
```

Access to `Web\PostController::getAction` → `?action=vendor:module.web.post.get`.

## Minimal Controller

`ControllerBuilder` builds the controller with `Request` only (`newInstance($request)`). Do **not** put custom services in the controller constructor — inject them via **action method parameters** (autowire). Avoid manual `new Service()` / ServiceLocator lookups inside actions when autowire works.

Keep `*Action()` as **orchestration only**: accept input → call application service → map `Result` / errors → return data or response helper. No fat business logic, heavy transforms, or hidden side effects in the controller.

Prefer **PHP 8 attributes** for filters. Use `configureActions()` only for compatibility or cases attributes cannot express.

```php
<?php declare(strict_types=1);

namespace Vendor\Module\Infrastructure\Controller;

use Bitrix\Main\Engine\Controller;
use Bitrix\Main\Engine\ActionFilter;
use Bitrix\Main\Engine\ActionFilter\Attribute\Rule\Authentication;
use Bitrix\Main\Engine\ActionFilter\Attribute\Rule\HttpMethod;
use Bitrix\Main\Engine\ActionFilter\Attribute\Rule\DisablePrefilters;
use Bitrix\Main\Engine\CurrentUser;
use Bitrix\Main\Error;
use Vendor\Module\Application\Service\PostService;

final class Post extends Controller
{
    #[HttpMethod([HttpMethod::METHOD_GET])]
    #[DisablePrefilters([ActionFilter\Csrf::class])]
    public function getAction(int $id, PostService $postService): array
    {
        $post = $postService->find($id);
        if ($post === null)
        {
            $this->addError(new Error('Not found', 'POST_NOT_FOUND'));
            return [];
        }

        return ['post' => $post];
    }

    #[Authentication]
    #[HttpMethod([HttpMethod::METHOD_POST])]
    public function createAction(
        string $title,
        string $body,
        PostService $postService,
        CurrentUser $currentUser,
    ): array
    {
        $result = $postService->create($title, $body, (int)$currentUser->getId());

        if (!$result->isSuccess())
        {
            $this->addErrors($result->getErrors());
            return [];
        }

        return $result->getData();
    }
}
```

### `JsonController`

`Bitrix\Main\Engine\JsonController` extends `Controller` and adds `ContentType([JSON])` to default prefilters. Use it for JSON-body APIs; otherwise prefer plain `Controller`.

## Action Parameter Autowiring

Action parameters are collected by the engine in the following order:

1. **Scalar types** (`int`, `string`, `bool`, `float`, `array`) → from `GET`/`POST`/`FILES`.
2. **Service objects** → from `ServiceLocator` by name/type.
3. **`HttpRequest`, `Session`, `CurrentUser`** → from context.
4. **Request DTO** with `#[Bitrix\Main\Validation\Engine\ValidationParameter]` → mapping + validation (see `bitrix-validation`).
5. **ORM objects**, if the action accepts `EntityObject` — loaded by `id`.

Missing mandatory parameter → automatic error.

For a cohesive input set (validation, nested structure, pagination), prefer a Request DTO over a long list of scalars.

### Current user

- Prefer `CurrentUser $user` in the action signature, or `$this->getCurrentUser()`.
- Do **not** use global `$USER` inside new controller code.

## Controller Lifecycle

1. Constructor — engine passes `Request` only (`ControllerBuilder`). No ServiceLocator DI for custom services.
2. `init()` — called from the constructor; load modules if needed (`parent::init()` first when overriding). Prefer action-parameter autowire over resolving services in `init()`.
3. Prefilters run.
4. Action method executes.
5. Postfilters run.
6. Response is serialized.

Do not hide action logic in `init()`, `__construct()`, `processBeforeAction()`, or `processAfterAction()`.

`executeComponent()` in component controllers does **not** run during AJAX actions — use `onPrepareComponentParams()` for shared setup.

## Additional Autowire Types

- `Bitrix\Main\Engine\CurrentUser` — current user context.
- `Bitrix\Main\Engine\JsonPayload` — raw JSON body.
- `Bitrix\Main\UI\PageNavigation` — pagination from request.

Custom DTO autowiring via `getAutoWiredParameters()`.

## Front-end Call

```js
BX.ajax.runAction('vendor:module.post.create', {
    data: { title: 'Title', body: 'Body' },
}).then((response) => {
    console.log(response.data);
});
```

For REST — `BX.rest.callMethod('vendor.module.post.create', {...})`.
