---
name: bitrix-project-structure
description: Covers Bitrix project structure — /local vs /bitrix, PSR-4 autoloading, .settings.php, Loader includeModule vs requireModule, placement of components, templates, modules, routes and php_interface, namespaces like Vendor\Module. Applied for "where to put code" questions, module loading boundaries and configuring autoloading. Key terms — /local, /bitrix, PSR-4, .settings.php, Loader, requireModule, includeModule, autoload.
---

# Project Structure and Autoloading in Bitrix

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

## Three Root Sections

- `/bitrix/` — **system files**. Never edit them directly: any hotfix will be lost during an update.
- `/local/` — **all user code**. If a file doesn't exist — create it manually. With the same path, a file in `/local/` takes precedence over `/bitrix/`.
- `/upload/` — files uploaded by users and modules.

## What to Put in `/local/`

```
/local/
├── modules/<vendor>.<module>/   # Custom modules (PSR-4 autoloading)
├── components/<vendor>/<name>/  # Components (class.php, templates/.default/)
├── templates/<id>/              # Site templates + /components/, /page_templates/
├── routes/
│   └── web.php                  # Routing entry (Since main 21.400)
├── activities/                  # Business process actions
├── gadgets/                     # Desktop gadgets
├── blocks/                      # Sites24 blocks
├── js/                          # Custom JS extensions
├── php_interface/
│   ├── init.php                 # Loaded on every hit
│   ├── after_connect_d7.php     # After DB connect (charset, sql_mode, TZ)
│   ├── dbconn.php               # Since main 24.100 — can live here
│   └── user_lang/               # User interface translations
├── .settings.php                # Kernel configuration (Since main 24.100)
└── .settings_extra.php          # Overrides (Since main 24.100)
```

Set the same permissions for `/local/php_interface/` as for `/bitrix/php_interface/` — it may contain sensitive files.

## Including a Module (`Loader`)

Prefer `Bitrix\Main\Loader` in new code. Treat `CModule::IncludeModule*` as legacy compatibility.

| Situation | API |
| --- | --- |
| Module is mandatory; failure must abort | `Loader::requireModule('vendor.module')` |
| Optional integration with a real `false` branch | `Loader::includeModule(...)` and handle `false` |
| Shareware/demo status codes | `Loader::includeSharewareModule()` / legacy `CModule::IncludeModuleEx()` — not plain `includeModule` |

```php
use Bitrix\Main\Loader;

// Mandatory — fail-fast (preferred when no fallback exists)
Loader::requireModule('vendor.module');

// Optional — must handle false explicitly
if (Loader::includeModule('vendor.analytics'))
{
    // enrich behaviour
}
```

`includeModule` / `requireModule`:

- Includes `include.php` and `/lib/autoload.php` of the module.
- Registers the module namespace for PSR-4 autoloading.
- Registers module **`services`** into `ServiceLocator`.

Rules:

- Do not call `includeModule` without handling `false` when the dependency is actually required — use `requireModule`.
- Load a required module once near the scenario boundary; do not repeat the same check deep in call stacks.
- Do not flip global behaviour with `Loader::setRequireThrowException(false)` to fake a bool API — call `includeModule` instead.
- Do not introduce new `CModule::IncludeModule()` in greenfield code.

## PSR-4 Autoloading of Classes in `/lib/`

The rule is simple: **folder name = namespace part, file name = class name** (both in PascalCase).

```
/local/modules/vendor.module/lib/
├── Application/Service/PostService.php        # \Vendor\Module\Application\Service\PostService
├── Infrastructure/Controller/Post.php         # \Vendor\Module\Infrastructure\Controller\Post
├── Model/PostTable.php                         # \Vendor\Module\Model\PostTable
└── Cli/Command/Feature/RebuildCommand.php      # \Vendor\Module\Cli\Command\Feature\RebuildCommand
```

Namespace from module id:

- Partner module `vendor.module` → `\Vendor\Module`
- One-word module `mymodule` → **`\Bitrix\Mymodule`** (kernel rule in `Loader`)

If the PSR-4 structure is followed — **nothing needs to be registered manually**.

## Manual Registration (When Needed)

In rare cases (mixed folders, non-PSR-4 legacy), you can specify in `/local/modules/vendor.module/include.php`:

```php
\Bitrix\Main\Loader::registerNamespace(
    'Vendor\\Module\\Legacy',
    $_SERVER['DOCUMENT_ROOT'] . '/local/modules/vendor.module/legacy',
);

\Bitrix\Main\Loader::registerAutoLoadClasses('vendor.module', [
    'Vendor\\Module\\OldClass' => 'classes/old_class.php',
]);
```

Prefer `registerNamespace` for a folder with PSR-4 structure. `registerAutoLoadClasses` is a last resort.

## Composer

Composer dependencies are placed in `/local/vendor/` (`/local/composer.json`). Keep `composer.json` **outside** `DOCUMENT_ROOT` when possible.

In `.settings.php`:

```php
'composer' => [
    'value' => ['config_path' => '../composer.json'], // path relative to DOCUMENT_ROOT
    'readonly' => true,
],
```

Required for `bitrix/bitrix.php` (`make:*` commands, **Since main 25.900**). Do not install packages in `/bitrix/vendor/` — they disappear on kernel update.

## Additional Files

- `/bitrix/routing_index.php` — entry point for new routing (configure web server to forward here).
- `/local/php_interface/after_connect_d7.php` — included after successful DB connection (`ConnectionPool` → `include_after_connected`). Typical uses: `SET NAMES`, `sql_mode`, DB timezone.
- `/local/php_interface/virtual_file_system.php` — virtual filesystem overrides.

## JS Extensions

Custom frontend code lives in `/local/js/<module>/<extension>/`. Load via `Extension::load('module.extension')`. See skill `bitrix-extensions`.

## Configuration Files

- `/bitrix/.settings.php` or `/local/.settings.php` — primary D7 kernel config.
- `/bitrix/.settings_extra.php` or `/local/.settings_extra.php` — overrides without API.
- `/bitrix/php_interface/dbconn.php` or `/local/php_interface/dbconn.php` — constants for old kernel and compatibility.

### Global vs module `.settings.php`

| Section | Where | Notes |
| --- | --- | --- |
| `connections`, `cache`, `session`, `routing`, `crypto`, `exception_handling`, `loggers`, `messenger` | **Global** only | Read by kernel config |
| `controllers`, `services`, `console` | **Module** (and optionally global for `services`) | Module `services` register on `includeModule` |
| `routing` in module `.settings.php` | **Not used by router** | See below |

### Module routes (not auto-loaded)

The router loads only files listed in **global** `routing.config` from `/local/routes/` and `/bitrix/routes/`.

Canonical pattern — keep module route file and require it from `/local/routes/web.php`:

```php
// /local/routes/web.php
return function (\Bitrix\Main\Routing\RoutingConfigurator $routes): void {
    $file = $_SERVER['DOCUMENT_ROOT'] . '/local/modules/vendor.module/routes/web.php';
    if (is_file($file)) {
        (require $file)($routes);
    }
};
```

See skill `bitrix-routing`.

## File Priority

- Components: `/local/components/<vendor>/<name>/` override `/bitrix/components/<vendor>/<name>/`.
- Component templates in a site template: `/local/templates/<id>/components/...` override everything else.
- System files (e.g., `header.php`) are searched first in `/local/`, then in `/bitrix/`.
- Modules: `/local/modules/<id>/` takes precedence over `/bitrix/modules/<id>/` when both exist.

## When `php_interface/init.php` is Needed

Only for:

- Registering **dynamic** event handlers that cannot be tied to the installation of a specific module.
- Project constants that must be available before modules are included.
- Compatibility hooks.

For everything else — create a module and use its `install/index.php`, `include.php`, and `.settings.php`.
