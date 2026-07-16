# Routes, handlers, params, groups

## Basic `web.php`

```php
<?php declare(strict_types=1);

use Bitrix\Main\Routing\RoutingConfigurator;
use Vendor\Module\Infrastructure\Controller\Post;

return function (RoutingConfigurator $routes): void {
    $routes->get('/api/posts', [Post::class, 'listAction'])->name('post.list');
    $routes->get('/api/posts/{id}', [Post::class, 'getAction'])
        ->where('id', '\d+')
        ->name('post.get');

    $routes->post('/api/posts', [Post::class, 'createAction'])->name('post.create');
    $routes->put('/api/posts/{id}', [Post::class, 'updateAction'])->where('id', '\d+');
    $routes->delete('/api/posts/{id}', [Post::class, 'deleteAction'])->where('id', '\d+');
};
```

## Supported Methods

- `get`, `post`, `put`, `patch`, `delete`, `head`, `options` — for specific HTTP methods.
- `any($uri, $handler)` — for any method.
- `match(['GET', 'POST'], $uri, $handler)` — explicit list of methods.
- `get` routes also accept `HEAD` automatically.

## Handlers

Accepted:

- `[Controller::class, 'actionName']` — Engine controller; name **without** or with `Action` suffix (`view` / `viewAction` — routing strips `Action` if present). Prefer short form `view`.
- Callable/closure — AutoWire can inject route params, `Route`, `HttpRequest`. Keep closures thin; grow into a controller when CSRF/auth/stable contract appears.
- Action class string only if it implements `Bitrix\Main\Engine\Contract\RoutableAction`.
- `PublicPageController` — include a legacy PHP page (see below).

```php
$routes->get('/health', function () {
    return new \Bitrix\Main\HttpResponse('ok');
});
```

Closure return: `HttpResponse`, string, array (converted to JSON), `null`.

Prefer explicit HTTP verbs (`get`/`post`/…) over `any()` for state-changing operations.

## Route Parameters

```php
$routes->get('/posts/{slug}', [Post::class, 'bySlugAction']);
$routes->get('/users/{id}/posts/{postId?}', [Post::class, 'userPostsAction']);
```

`{param?}` is optional (requires a `default`):

```php
$routes->get('/posts/{page?}', [Post::class, 'listAction'])->default('page', 1);
```

Regex on parameter:

```php
$routes->get('/posts/{id}', [Post::class, 'getAction'])
    ->where('id', '[0-9]+');

$routes->get('/{section}/{slug}', $handler)
    ->where(['section' => '[a-z]+', 'slug' => '[a-z0-9\-]+']);
```

## Names and URL Generation

```php
$routes->get('/posts/{id}', [Post::class, 'getAction'])
    ->where('id', '\d+')
    ->name('post.get');
```

```php
$url = (string)\Bitrix\Main\Application::getInstance()
    ->getRouter()
    ->route('post.get', ['id' => 42]);
// /posts/42
```

## Groups (fluent API)

`group()` accepts **only a closure**. Apply `prefix` / `name` via the fluent chain:

```php
$routes
    ->prefix('api')
    ->name('api.')
    ->group(function (RoutingConfigurator $routes) {
        $routes->get('/posts', [Post::class, 'listAction'])->name('post.list');
        // URL: /api/posts, name: api.post.list

        $routes
            ->prefix('admin')
            ->name('admin.')
            ->group(function (RoutingConfigurator $routes) {
                $routes->get('/stats', [Admin::class, 'statsAction'])->name('stats');
                // URL: /api/admin/stats, name: api.admin.stats
            });
    });
```

Also available on the configurator/options: `where` (group defaults), `domain`.

> Do **not** use Laravel-style `group(['prefix' => '/api'], fn () => …)` — that is not the Bitrix API.

### Prefix and trailing slash

- `->prefix()` takes a path **without** a leading slash (`api`, or `ltrim($siteDir, '/')`).
- For fixed leaf paths without a dynamic segment, prefer a trailing slash in the URI (`…/settings/`) or a catch-all `{any}` — otherwise the web server may treat the path as a static file and 404 before `routing_index.php`.
- Inside a group: register **narrow** routes first, then catch-all `{any}` with `->where('any', '.*')`.

## Delivering view / component

```php
$routes->get('/about', fn () => \Bitrix\Main\Engine\Response\Component::createByComponentName(
    'bitrix:main.include', '.default', ['PATH' => '/about.inc.php']
));
```

Or return an array/object — the engine serializes via `Engine\Response\Converter`.
