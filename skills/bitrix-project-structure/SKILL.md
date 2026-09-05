---
name: bitrix-project-structure
description: Covers Bitrix project structure — /local vs /bitrix, project tree, class placement and namespaces, .settings.php, composer, routing, init.php. Applied for "where to put code" and autoloading decisions. Module anatomy and inclusion → bitrix-modules; component anatomy → bitrix-components. Key terms — /local, PSR-4, namespace, .settings.php, composer, /local/routes/, init.php.
---

# Project Structure and Autoloading in Bitrix

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

## Three Root Sections

- `/bitrix/` — **system files**. Never edit them directly: any hotfix will be lost during an update.
- `/local/` — **all user code**. If a file doesn't exist — create it manually. With the same path, a file in `/local/` takes precedence over `/bitrix/`.
- `/upload/` — files uploaded by users and modules.

## Project Tree (`/local/`)

The tree below is a general skeleton of a 1C-Bitrix project. The project should preferably be organized according to this layout and its inline comments: put new files, directories, components, and extensions in the places shown here, and follow the comments when deciding where code belongs. If an entry is missing from the tree, add it so the tree keeps reflecting the actual project
structure.

```
<project-root>/
├── .gitignore / .editorconfig / .gitattributes
├── .gitlab-ci.yml                  # CI/CD  (optional)
├── AGENTS.md                       # instructions for AI agents
├── README.md                       # project conventions for developers
└── local/                          # all custom code
    ├── activities/custom/          # business process activities
    ├── blocks/                     # Sites24 blocks
    ├── components/
    │   ├── bitrix/                 # overridden system components
    │   └── <vendor>/               # custom components (see bitrix-components)
    ├── gadgets/                    # desktop gadgets
    ├── js/<vendor>/<extension>/    # JS extensions (see bitrix-extensions)
    ├── modules/<vendor>.<module>/  # custom modules (see bitrix-modules)
    ├── php_interface/
    │   ├── lib/                    # shared libs — when no module fits
    │   ├── init.php                # loaded on every hit; minimal: composer autoload only
    │   ├── cron_events.php         # cron tasks
    │   ├── after_connect_d7.php    # after DB connect (charset, sql_mode, TZ)
    │   ├── dbconn.php              # Since main 24.100 — can live here
    │   ├── this_site_support.php   # site support info in admin footer? (html document)
    │   └── user_lang/              # user interface translations. overwrite system messages
    ├── routes/
    │   └── web.php                 # routing entry — global routing.config lists files here  (optional)
    ├── templates/<id>/             # site templates + /components/, /page_templates/
    ├── vendor/                     # composer dependencies
    ├── composer.json               # Project dependencies with module composer.json includes
    ├── .settings.php               # full kernel config — replaces /bitrix/.settings.php entirely — Since main 24.100
    ├── .settings_extra.php         # section overrides — preferred for additions — Since main 24.100
    ├── .phpcs.xml                 # PHP CodeSniffer config (optional)
    ├── .php-cs-fixer.dist.php     # PHP CS Fixer config (optional)
    └── .gitignore                 # Git ignore for local
```

Set the same permissions for `/local/php_interface/` as for `/bitrix/php_interface/` — it may contain sensitive files.

## Class Placement

| Project type | Classes go to | Namespace |
| --- | --- | --- |
| Monolith (e.g. DDD-based) | `/local/lib/` | `\Vendor\...` |
| Module-based | `/local/modules/<vendor>.<module>/lib/` | `\Vendor\Module\...` |

PSR-4: **folder name = namespace part, file name = class name** (PascalCase, singular folders). If the PSR-4 structure is followed — **nothing needs to be registered manually**.

Module `lib/` subdirectories, namespace-from-module-id rules and `Loader` inclusion → skill `bitrix-modules`.

## Composer

Composer dependencies are placed in `/local/vendor/` (`/local/composer.json`). Keep `composer.json` **outside** `DOCUMENT_ROOT` when possible. Module `composer.json` files are included from the project one.

Minimal `/local/composer.json` skeleton:

```json
{
	"name": "vendor/project",
	"type": "project",
	"license": "MIT",
	"minimum-stability": "dev",
	"prefer-stable": true,
	"require": {
		"composer/installers": "^2.0",
		"wikimedia/composer-merge-plugin": "dev-master"
	},
	"autoload": {
		"psr-4": {
		}
	},
	"extra": {
		"bitrix-dir": "../bitrix",
		"merge-plugin": {
			"require": [
				"../bitrix/composer-bx.json",
				"./modules/<vendor>.<module>/composer.json"
			]
		},
		"installer-paths": {
			"./modules/{$vendor}.{$name}/": [
				"type:bitrix-d7-module",
				"type:bitrix-module"
			],
			"./components/{$vendor}/{$name}/": [
				"type:bitrix-d7-component",
				"type:bitrix-component"
			],
			"./templates/{$vendor}_{$name}/": [
				"type:bitrix-d7-template",
				"type:bitrix-theme"
			]
		}
	},
	"config": {
		"vendor-dir": "vendor",
		"allow-plugins": {
			"composer/installers": true,
			"wikimedia/composer-merge-plugin": true
		}
	}
}
```

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
- `/local/php_interface/cron_events.php` — cron task registration.
- `/local/php_interface/this_site_support.php` — support info in the admin footer.

## JS Extensions

Custom frontend code lives in `/local/js/<module>/<extension>/`. Load via `Extension::load('module.extension')`. See skill `bitrix-extensions`.

## Configuration Files

- `/bitrix/.settings.php` — primary D7 kernel config. `/local/.settings.php` (**Since main 24.100**) **replaces** it entirely, no merge — must contain the full mandatory config, `connections` included.
- `/bitrix/.settings_extra.php` — overrides without API; preferred for adding sections. `/local/.settings_extra.php` (**Since main 24.100**) replaces it the same way; the kernel loads the extra file after the primary and each same-named section replaces the primary section entirely.
- No `.settings*` file in `/bitrix/` — signal of a partial codebase (agent sandbox, partial checkout). Verify the real environment before config changes.
- `/bitrix/php_interface/dbconn.php` or `/local/php_interface/dbconn.php` — constants for old kernel and compatibility.

Global-only `.settings.php` sections — read by kernel config: `connections`, `cache`, `session`, `routing`, `crypto`, `exception_handling`, `loggers`, `messenger`. Module-level sections (`controllers`, `services`, `console`), module route wiring and `Loader` inclusion → skill `bitrix-modules`; router mechanics → skill `bitrix-routing`.

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

`init.php` stays **minimal — composer autoload only** for new code. For everything else — create a module and use its `install/index.php`, `include.php`, and `.settings.php`.

## Checklist

- [ ] All custom code lives in `/local/`, never in `/bitrix/`.
- [ ] New classes go to `lib/` of a module (or `/local/lib/` for monoliths), PSR-4, one class per file.
- [ ] Module anatomy, naming and inclusion follow skill `bitrix-modules`; component anatomy follows skill `bitrix-components`.
- [ ] Router reads only global `routing.config` (`/local/routes/`, `/bitrix/routes/`); module wiring per `bitrix-modules`.
- [ ] Composer packages in `/local/vendor/`, never `/bitrix/vendor/`.
- [ ] `init.php` minimal — composer autoload only; event handlers live in modules.
