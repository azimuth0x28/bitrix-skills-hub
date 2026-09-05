# Enable routing and module wiring

## Enabling New Routing

### Web server

Route non-existent files to `routing_index.php`:

**Apache** (`.htaccess`):

```apache
RewriteCond %{REQUEST_FILENAME} !/bitrix/routing_index.php$
RewriteRule ^(.*)$ /bitrix/routing_index.php [L]
```

**Nginx**:

```nginx
try_files $uri $uri/ /bitrix/routing_index.php;
```

### Global config only

Register the section in `.settings_extra.php` — the **preferred** file (create `/local/.settings_extra.php` if absent, **Since main 24.100**):

```php
// /local/.settings_extra.php
'routing' => [
    'value' => [
        'config' => ['web.php'], // basename only — searched in /local/routes/ and /bitrix/routes/
    ],
    'readonly' => true,
],
```

The kernel loads the extra file after the primary config and each same-named section replaces the primary section entirely. An existing `/local/.settings_extra.php` replaces `/bitrix/.settings_extra.php`. On kernels older than main 24.100, add the section to `/bitrix/.settings_extra.php`.

> Do **not** create a partial `/local/.settings.php` for this. That file **replaces** `/bitrix/.settings.php` entirely (no merge) — without `connections` it breaks the site on deploy. No `.settings*` file in `/bitrix/` is a partial-codebase signal: the replace stays invisible in a sandbox yet is fatal on the real site — verify the target environment first.

How the kernel loads files (`Application::initializeRouter`):

1. For each name in `routing.config`, look for `/local/routes/<name>` **and** `/bitrix/routes/<name>` (both may be included).
2. Then append system `/bitrix/routes/web_bitrix.php` if present.
3. Each file must `return` a `callable(RoutingConfigurator $routes): void`.

> **User routes belong only in `/local/routes/`.** `/bitrix/routes/` is reserved for the system.

### Module routes — require pattern

A `routing` section in **module** `.settings.php` is **not** read by the router. Keep module files under `/local/modules/<id>/routes/` and include them from `/local/routes/web.php`:

```php
<?php declare(strict_types=1);

use Bitrix\Main\Routing\RoutingConfigurator;

return function (RoutingConfigurator $routes): void {
    $moduleRoutes = $_SERVER['DOCUMENT_ROOT']
        . '/local/modules/vendor.module/routes/web.php';
    if (is_file($moduleRoutes)) {
        (require $moduleRoutes)($routes);
    }

    // project-level routes…
};
```
