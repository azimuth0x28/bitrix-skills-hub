---
name: bitrix-modules
description: Use when creating, installing, or including modules. Covers module creation and anatomy in /local/modules/vendor.module/ — CModule, lib/ subdirectories (Agent, Controller, Model, Service), Loader inclusion, events, agents, options, make:module. Key terms — CModule, DoInstall, DoUninstall, lib/, PSR-4, Loader, requireModule, vendor.module.
---

# Bitrix Modules

## Identifier and Namespace

- Identifier: `<vendor>.<module>` (lowercase, no `_`, no digit at start).
- Installer class: `<vendor>_<module>` (dot → `_`).
- Namespace: `\<Vendor>\<Module>\...` (dot → `\`, CamelCase) for partner modules with a dot in the id.
- One-word module id (no partner prefix), e.g. `mymodule`: installer class `mymodule`, PSR-4 namespace **`\Bitrix\Mymodule`** (Loader uses `Bitrix\` + `ucfirst($moduleName)`), not `\Mymodule`.

## Quick Creation

```bash
php bitrix/bitrix.php make:module vendor.module
```

**Since main 25.900.** On older versions, scaffold files manually.

`make:module` creates a **minimal** skeleton only: `install/index.php` + `version.php`, empty `install/mysql/install.sql` / `uninstall.sql` stubs, `default_option.php`, `lang/ru/install/index.php`. It does **not** create `.settings.php`, `/lib/`, routes, or controllers — add those yourself or via further `make:*` / `dev:module-skeleton`.


## Minimal Structure

```
/local/modules/vendor.module/
├── install/
│   ├── index.php
│   ├── version.php
│   └── mysql/                   # optional SQL stubs from make:module
├── lang/ru/install/index.php
├── default_option.php
├── lib/                         # PSR-4, Vendor\Module\... (add manually)
├── views/                       # PHP views for renderView() in controllers
├── routes/                      # Module route files — require from /local/routes/web.php
├── .settings.php                # controllers, services, console (add manually)
└── include.php                  # optional, for registerNamespace/registerAutoLoadClasses
```

## Base Module Anatomy

```
/local/modules/vendor.module/
├── install/
│   ├── components/<vendor>/     # module components, copied to /local/components/
│   │   └── <module>.<name>/
│   ├── db/
│   │   ├── install.sql          # schema on install
│   │   └── update_0.0.1.sql     # migrations
│   ├── index.php                # installer class (CModule)
│   └── version.php
├── lib/                         # PSR-4, \Vendor\Module\... (add manually)
│   ├── Agent/                   # agents (cron)
│   ├── Component/               # base component classes
│   ├── Controller/              # Ajax|Rest controllers
│   ├── Integration/             # external systems + EventHandler/
│   ├── Internal/                # Util, Error, Exception, QueueMessenger/
│   ├── Model/                   # ORM entities (PostTable.php)
│   ├── Module/                  # Configuration.php, Constants.php, EventManager.php
│   ├── Repository/              # data access over ORM
│   └── Service/                 # business logic, Container.php (ServiceLocator)
├── views/                       # PHP views for renderView() in controllers (optional)
├── routes/                      # Module route files — require from /local/routes/web.php
├── .settings.php                # controllers, services, console (add manually)
└── include.php                  # optional, for registerNamespace/registerAutoLoadClasses
├── composer.json                # Module dependencies  (recommended)
└── .gitignore                   # Git ignore for module  (optional)
```

## lib/ Anatomy Rules

- **One class per file; file name = class name.** Namespace folders are **singular**: `lib\Agent\`, `lib\Model` — never `lib\Agents\`, `lib\Models\`.
- Namespace: `\Vendor\Module\<SubNamespace>\<ClassName>` — `vendorname.catalog` → `\VendorName\Catalog\Agent\PriceUpdateAgent`.
- Vendor-level namespace `\Vendor\` is declared in the project's `AGENTS.md` (`{{VENDOR_NAME}}`); class placement at project level → skill `bitrix-project-structure`.
- Module components ship in `install/components/<vendor>/` and are copied to `/local/components/` on install; name `vendor.module.component_name`. Component anatomy → skill `bitrix-components`.

## Module Routing

Routing is **global-only** — the kernel loads route files listed in global `routing.config` from `/local/routes/` and `/bitrix/routes/` only. A `routing` section in the module's `.settings.php` is **not** auto-loaded. Connect module routes by `require` from `/local/routes/web.php`:

```php
// /local/routes/web.php
return function (\Bitrix\Main\Routing\RoutingConfigurator $routes): void {
    $moduleRoutes = $_SERVER['DOCUMENT_ROOT'] . '/local/modules/vendor.module/routes/web.php';
    if (is_file($moduleRoutes))
    {
        (require $moduleRoutes)($routes);
    }
};
```

## `install/version.php`

```php
<?php
$arModuleVersion = [
    'VERSION' => '1.0.0',
    'VERSION_DATE' => '2026-04-16 12:00:00',
];
```

## `install/index.php`

Inherit from `CModule`, implement `DoInstall`/`DoUninstall`. Base template:

```php
<?php

use Bitrix\Main\Localization\Loc;
use Bitrix\Main\ModuleManager;
use Bitrix\Main\EventManager;

Loc::loadMessages(__FILE__);

final class vendor_module extends CModule
{
    public $MODULE_ID = 'vendor.module';
    public $MODULE_VERSION;
    public $MODULE_VERSION_DATE;
    public $MODULE_NAME;
    public $MODULE_DESCRIPTION;
    public $PARTNER_NAME = 'Vendor';
    public $PARTNER_URI = 'https://vendor.example.com';

    public function __construct()
    {
        $arModuleVersion = [];
        include __DIR__ . '/version.php';

        $this->MODULE_VERSION = $arModuleVersion['VERSION'] ?? '';
        $this->MODULE_VERSION_DATE = $arModuleVersion['VERSION_DATE'] ?? '';

        $this->MODULE_NAME = (string)Loc::getMessage('VENDOR_MODULE_NAME');
        $this->MODULE_DESCRIPTION = (string)Loc::getMessage('VENDOR_MODULE_DESCRIPTION');
    }

    public function DoInstall(): void
    {
        global $USER, $APPLICATION;

        if (!$USER->IsAdmin())
        {
            $APPLICATION->ThrowException('Access denied');
            return;
        }

        ModuleManager::registerModule($this->MODULE_ID);

        $this->installDb();   // create tables via ORM — see DB Tables
        $this->installEvents();
        $this->installAgents();
        $this->installFiles();
    }

    public function DoUninstall(): void
    {
        global $USER;
        if (!$USER->IsAdmin()) return;

        $this->uninstallAgents();
        $this->uninstallEvents();
        $this->uninstallDb(); // drop tables — see DB Tables
        $this->uninstallFiles();

        ModuleManager::unRegisterModule($this->MODULE_ID);
    }

    private function installEvents(): void
    {
        EventManager::getInstance()->registerEventHandler(
            fromModule: 'main',
            eventType: 'OnAfterUserAdd',
            toModuleId: $this->MODULE_ID,
            toClass: \Vendor\Module\Integration\Main\EventHandler\OnAfterUserAddHandler::class,
            toMethod: 'handle',
        );
    }

    private function uninstallEvents(): void
    {
        EventManager::getInstance()->unRegisterEventHandler(
            fromModule: 'main',
            eventType: 'OnAfterUserAdd',
            toModuleId: $this->MODULE_ID,
            toClass: \Vendor\Module\Integration\Main\EventHandler\OnAfterUserAddHandler::class,
            toMethod: 'handle',
        );
    }

    private function installAgents(): void
    {
        \CAgent::AddAgent(
            \Vendor\Module\Agent\QueueAgent::class . '::run();',
            $this->MODULE_ID,
            'N',
            300,
            '',
            'Y',
            '',
            100,
        );
    }

    private function uninstallAgents(): void
    {
        \CAgent::RemoveModuleAgents($this->MODULE_ID);
    }

    private function installFiles(): void
    {
        CopyDirFiles(
            __DIR__ . '/components',
            $_SERVER['DOCUMENT_ROOT'] . '/local/components',
            true,
            true,
        );
    }

    private function uninstallFiles(): void
    {
        DeleteDirFilesEx('/local/components/vendor');
    }
}
```

## Language Files

`/local/modules/vendor.module/lang/ru/install/index.php` (created by `make:module`) defines `$MESS['VENDOR_MODULE_NAME']`, `$MESS['VENDOR_MODULE_DESCRIPTION']`; add `lang/en/` (and other locales) for multi-language admin UI.

Lang paths **mirror the source path** relative to the module root: `/install/index.php` → `/lang/<code>/install/index.php`, `/admin/my_page.php` → `/lang/<code>/admin/my_page.php`. `MODULE_NAME` / `MODULE_DESCRIPTION` are read from these phrases in the installer constructor; a wrong path or phrase code shows the module with an empty name in the admin modules list.

## DB Tables

Do not use raw SQL for table creation. Describe the entity in `/lib/Model/PostTable.php`; include the module, then create via `\Vendor\Module\Model\PostTable::getEntity()->createDbTable()` and drop via `\Bitrix\Main\Application::getConnection()->dropTable(PostTable::getTableName())`.

## Module Options (`options.php`)

Module options (`Option` + `default_option.php`) are for **permanent** settings. For TTL runtime state vs cache vs Option, see skill `bitrix-storage`.

If you need a settings page in Admin Panel (*Settings → Module Settings → Vendor Module*):

```php
<?php
/** @var CMain $APPLICATION */
/** @var string $mid */ // module id

use Bitrix\Main\Config\Option;
use Bitrix\Main\Localization\Loc;

$options = [
    ['api_key', Loc::getMessage('VENDOR_API_KEY'), '', ['text', 40]],
    ['debug_mode', Loc::getMessage('VENDOR_DEBUG'), 'N', ['checkbox', 'Y']],
];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && check_bitrix_sessid())
{
    foreach ($options as [$code, , $default])
    {
        Option::set($mid, $code, $_POST[$code] ?? $default);
    }
}

// render the form via CAdminTabControl
```

## Including a Module (`Loader`)

Prefer `Bitrix\Main\Loader` in new code; treat `CModule::IncludeModule*` as legacy compatibility. `includeModule` / `requireModule` include the module's `include.php` and `/lib/autoload.php`, register the module namespace for PSR-4 autoloading — with the rules above, nothing needs manual registration — and register module **`services`** into `ServiceLocator`.

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

**Do not** call `includeModule` without handling `false` when the dependency is actually required — use `requireModule`. Load a required module once near the scenario boundary; do not repeat the same check deep in call stacks. **Do not** flip global behaviour with `Loader::setRequireThrowException(false)` to fake a bool API — call `includeModule` instead. **Do not** introduce new `CModule::IncludeModule()` in greenfield code.

## Manual Registration (Legacy Folders)

For non-PSR-4 legacy folders, register in module `include.php`:

```php
\Bitrix\Main\Loader::registerNamespace(
    'Vendor\\Module\\Legacy',
    $_SERVER['DOCUMENT_ROOT'] . '/local/modules/vendor.module/legacy',
);
```

Prefer `registerNamespace` for a PSR-4-shaped folder; `registerAutoLoadClasses` is a last resort — keep `include.php` **empty** otherwise.

## Composer

Module `composer.json` declares dependencies and configures PSR-4 autoloading for the module namespace. The project-level `composer.json` includes module manifests via `wikimedia/composer-merge-plugin` (see `bitrix-project-structure`).

Minimal module `composer.json`:

```json
{
	"name": "vendor/module",
	"type": "bitrix-d7-module",
	"license": "MIT",
	"require": {
		"php": "^8.0",
		"composer/installers": "^2.0"
	},
	"replace": {
		"psr/log": "*",
		"psr/container": "*",
		"psr/http-client": "*",
		"psr/http-message": "*"
	},
	"autoload": {
		"psr-4": {
			"Vendor\\Module\\": "lib/"
		}
	},
	"config": {
		"vendor-dir": "vendor",
		"allow-plugins": {
			"composer/installers": true
		}
	}
}
```

| Field | Purpose |
| --- | --- |
| `type: bitrix-d7-module` | Lets `composer/installers` auto-place the package into `/local/modules/` |
| `replace` | Stubs PSR interfaces that Bitrix kernel provides at runtime — prevents conflicts with standalone PSR packages |
| `autoload.psr-4` | Maps module namespace to `lib/`; must match the namespace convention from Identifier and Namespace section |
| `vendor-dir` | Keeps module-specific dependencies isolated within the module directory |

The `replace` block is optional when the module has no PSR dependency conflicts. When omitted, `vendor-dir` defaults to the module root.

## Checklist

- [ ] Module identifier follows `vendor.module` format (or one-word → `\Bitrix\...` namespace).
- [ ] After `make:module`, `.settings.php` / `lib/` added if needed (generator is minimal).
- [ ] Module routes are `require`d from `/local/routes/web.php` — not expected from module `.settings.php` `routing`.
- [ ] `DoInstall`/`DoUninstall` are implemented and idempotent.
- [ ] Event handlers and agents are registered upon installation and removed upon uninstallation.
- [ ] DB tables are managed via ORM or `SqlHelper` (DDL).
- [ ] Language files exist where needed (`lang/ru/` from generator; add `lang/en/` etc.); no hardcoded strings in `index.php` — use `Loc`.
- [ ] Services and controllers are registered in `.settings.php`.
- [ ] `lib/` follows the anatomy (Agent, Component, Controller, Integration, Internal, Model, Module, Repository, Service); namespace folders singular; one class per file; PSR-4-compatible.
- [ ] Module components in `install/components/<vendor>/`, name `vendor.module.component_name`; files copied to `/local/`, never `/bitrix/`.
- [ ] Mandatory dependencies load via `Loader::requireModule`; `includeModule` result is handled.
