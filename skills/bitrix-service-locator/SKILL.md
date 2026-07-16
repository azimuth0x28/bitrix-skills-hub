---
name: bitrix-service-locator
description: Covers DI container Bitrix\Main\DI\ServiceLocator (PSR-11) — registration of services in the services section of a module's .settings.php file, autowire, retrieving dependencies via has()/get(), constructor injection in application services, action-parameter injection in controllers, binding interfaces to implementations. Applied when moving logic to services, avoiding static calls, and wiring dependencies into services and controller actions (not console/event constructors). Key terms — ServiceLocator, DI, services, autowire, PSR-11, dependency injection, container.
---

# ServiceLocator (DI) in Bitrix

`Bitrix\Main\DI\ServiceLocator` is the kernel's PSR-11 container. It should be retrieved via `ServiceLocator::getInstance()`, but directly in application code only where dependencies cannot be injected the usual way (factories, legacy, static context, console commands, event handlers).

## Layer Rules

| Context | Constructor DI via ServiceLocator? | How to get services |
| --- | --- | --- |
| Application / Infrastructure **services** | Yes | Register in `services`, autowire constructors |
| Controller **action parameters** | Yes (autowire) | Type-hint service in the action method |
| `Controller` constructor | **No** | Engine builds controller with `Request` only — use action params or `init()` + `ServiceLocator::get()` |
| Console commands | **No** | CLI does `new $commandClass()` — call `ServiceLocator::get()` in `execute()` |
| Event handlers | **No** | `call_user_func_array` — resolve inside the handler method |
| Messenger receivers | Yes (must be registered) | Handler FQCN must exist in `services` |

- Domain does not know about the container.
- Services from `Application/` / `Infrastructure/` receive dependencies **via constructor**.
- Controllers receive services **via action parameters** only (not constructor).
- Console commands and event handlers are **not** created by the container.

## Service Registration

File `/local/modules/vendor.module/.settings.php`:

```php
<?php
return [
    'services' => [
        'value' => [
            // 1. By string name
            'vendor.module.postService' => [
                'className' => \Vendor\Module\Application\Service\PostService::class,
            ],

            // 2. By FQCN (preferred — less magic, IDE support)
            \Vendor\Module\Application\Service\PostService::class => [
                'className' => \Vendor\Module\Application\Service\PostService::class,
            ],

            // 3. Interface → Implementation
            \Vendor\Module\Domain\Repository\PostRepositoryInterface::class => [
                'className' => \Vendor\Module\Infrastructure\Repository\PostRepository::class,
            ],

            // 4. With constructor parameters
            \Vendor\Module\Infrastructure\Http\TelegramClient::class => [
                'className' => \Vendor\Module\Infrastructure\Http\TelegramClient::class,
                'constructorParams' => static fn () => [
                    'token' => getenv('TELEGRAM_BOT_TOKEN'),
                ],
            ],

            // 5. Closure factory (full control over creation)
            \Psr\Log\LoggerInterface::class => [
                'constructor' => static function (): \Psr\Log\LoggerInterface {
                    return \Vendor\Module\Infrastructure\Logger\LoggerFactory::create();
                },
            ],
        ],
        'readonly' => true,
    ],
];
```

### Modes

- **`className`** — simple registration; the container resolves dependencies via autowire (by FQCN from constructor).
- **`className` + `constructorParams`** — pass scalar parameters.
- **`constructor`** — full control, returns a finished object.

### Global Services

The `services` section can also be used in `/local/.settings.php` — registration does not require a module:

```php
'services' => [
    'value' => [
        'project.featureFlags' => [
            'className' => \App\FeatureFlags::class,
        ],
    ],
    'readonly' => true,
],
```

Global services are registered first (`registerByGlobalSettings`). On `Loader::includeModule`, module `services` are registered; if `has($code)` is already true, the module entry is **skipped**.

## Retrieving a Service

### Autowire via Constructor (services only)

```php
final class PostService
{
    public function __construct(
        private readonly \Vendor\Module\Domain\Repository\PostRepositoryInterface $posts,
        private readonly \Psr\Log\LoggerInterface $logger,
    ) {}
}
```

Simply registering `PostService` itself is enough — its dependencies will be retrieved from the container by type.

### In a Controller (action parameters)

```php
final class Post extends \Bitrix\Main\Engine\Controller
{
    public function getAction(
        int $id,
        \Vendor\Module\Application\Service\PostService $postService,
    ): array {
        return ['post' => $postService->find($id)];
    }
}
```

Do **not** type-hint custom services in the controller constructor — `ControllerBuilder` passes `Request` only.

### In a Console Command / Event Handler

Not created by the container. Resolve explicitly:

```php
$service = \Bitrix\Main\DI\ServiceLocator::getInstance()
    ->get(\Vendor\Module\Application\Service\PostService::class);
```

### Explicit Container Access

```php
$sl = \Bitrix\Main\DI\ServiceLocator::getInstance();

if ($sl->has(PostService::class))
{
    /** @var PostService $posts */
    $posts = $sl->get(PostService::class);
}
```

Use only where DI is impossible (init.php, global functions, console `execute()`, event handlers, old callbacks).

## Service Overriding

**First registration wins.** When a module calls `registerByModuleSettings`, existing codes are skipped (`has()` → `continue`). Another module cannot override a service by registering the same key later with `readonly: false`.

Override via:

1. **`/local/.settings.php` or `/local/.settings_extra.php`** — global `services` (loaded before modules), or
2. **`ServiceLocator::getInstance()->addInstance($code, $object)`** / `addInstanceLazy()` at runtime (e.g. in `init.php`).

```php
// /local/.settings_extra.php — wins over later module registration for the same key
'services' => [
    'value' => [
        \Vendor\Blog\Domain\Repository\PostRepositoryInterface::class => [
            'className' => \Vendor\Override\Repository\CachedPostRepository::class,
        ],
    ],
    'readonly' => true,
],
```

## Lifecycle

- Services are **singletons** per process/request. Do not store per-request state in them; use request scope via method parameters.
- In long-running CLI processes (messenger-consumer), avoid global state and memory leaks.

## Antipatterns

- Constructor DI on `Controller` / console command / event handler.
- `$service = new PostService(...);` in a controller/command when the service is registered — use action-param DI or `ServiceLocator::get()`.
- `ServiceLocator::getInstance()->get(...)` in domain classes — they should not know about the container.
- Expecting a second module's `services` entry to override the first registration.
- Registering "config" as a service without a wrapper — pass config as an object/DTO rather than an array.
- Mixing global `\Bitrix\Main\Application::getInstance()->...` via statics instead of injection.

## Checklist

- [ ] All application services are in module `services` or global.
- [ ] The key matches FQCN where possible (autocompletion + clarity).
- [ ] Domain interfaces look at infrastructure implementations only via `ServiceLocator`.
- [ ] Controllers use action-parameter injection; commands/handlers use `ServiceLocator::get()`.
- [ ] Overrides go through global settings / `addInstance`, not a later module registration.
- [ ] No circular dependencies (the container throws an `Exception` in this case).

## Persistent Storage (**Since main 25.1100**)

`PersistentStorageInterface` is registered in kernel `services`. Retrieve via:

```php
$storage = ServiceLocator::getInstance()
    ->get(\Bitrix\Main\Data\Storage\PersistentStorageInterface::class);
$storage->set('vendor.module.key', $data, 3600);
```

See skill `bitrix-storage` for `DeferredStorageDecorator` and TTL rules.
