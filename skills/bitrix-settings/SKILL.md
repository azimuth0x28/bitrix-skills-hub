---
name: bitrix-settings
description: Covers kernel configuration — .settings.php sections (connections, cache, session, crypto, exception_handling, routing, messenger, pull, smtp, loggers, composer), .settings_extra.php, readonly flag. Applied when configuring kernel behavior. Key terms — .settings.php, settings, readonly, connections, exception_handling.
---

# Kernel Configuration (.settings.php)

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

Primary config: `/bitrix/.settings.php` or `/local/.settings.php` (**Since main 24.100**). Overrides: `/bitrix/.settings_extra.php` or `/local/.settings_extra.php` (**Since main 24.100**).

> Errors in `.settings.php` can break the site. Back up before changes.

Also maintain `/local/php_interface/dbconn.php` for legacy kernel compatibility even when using D7 only.

## Structure

Each section:

```php
'section_name' => [
    'value' => [ /* settings */ ],
    'readonly' => true,  // true = no runtime API changes
],
```

## Global vs Module `.settings.php`

| Scope | Typical sections | Behavior |
| --- | --- | --- |
| **Global** (`/local/.settings.php`) | `connections`, `cache`, `cache_flags`, `session`, `cookies`, `crypto`, `exception_handling`, `routing`, `messenger`, `loggers`, `composer`, `http_client_options`, `pull`, `smtp`, `default_language`, `rest` | Loaded as kernel `Configuration` |
| **Module** (`/local/modules/<id>/.settings.php`) | `controllers`, `services`, `console` (`commands` key — not `cli`) | On `Loader::includeModule`, **`services`** are registered into ServiceLocator. Other module sections are not a full merge into global config |

**Routing is global-only:** the router loads files listed in global `routing.config` from `/local/routes/` and `/bitrix/routes/` only. Module route files must be `require`d from `/local/routes/web.php` — a module `.settings.php` `routing` section does **not** auto-load them.

There is **no** `validation` section in `.settings.php`. Use `ValidationService` via ServiceLocator (`main.validation.service` in `main` module services). See skill `bitrix-validation`.

## Key Sections

| Section | Purpose |
| --- | --- |
| `connections` | **Required.** DB and additional connections |
| `cache` | Cache engine (files / redis / memcache / …) |
| `cache_flags` | Per-entity / named TTL caps (e.g. `config_options`, `b_<table>_max_ttl` / `_min_ttl` for ORM) |
| `session` | Session handlers, lifetime, separated mode |
| `cookies` | Cookie flags (`secure`, `http_only`) |
| `crypto` | Encryption keys for cookies and fields |
| `exception_handling` | Debug, error masks, log (see below) |
| `routing` | Route config files (`web.php`, etc.) |
| `messenger` | Queue brokers and handlers (**Since main 25.100.300**, alpha) |
| `loggers` | PSR-3 logger registration |
| `http_client_options` | Default options for `Bitrix\Main\Web\HttpClient` |
| `rest` | REST controller defaults (e.g. `defaultNamespace` in `main/.settings.php`) |
| `controllers` | Controller namespaces (often module-level) |
| `services` | DI container entries |
| `console` | CLI commands (`commands` => FQCN list) |
| `composer` | Path to `composer.json` |
| `pull` | Push/pull server settings |
| `smtp` | Mail transport |
| `default_language` | Default language code |

## exception_handling

Keys applied in `Application::initializeExceptionHandler()` (verified):

| Key | Role |
| --- | --- |
| `debug` | Show errors on screen — **never `true` in production** |
| `handled_errors_types` | PHP error bitmask logged / handled |
| `exception_errors_types` | Subset that becomes exceptions |
| `ignore_silence` | If true, ignore `@` operator |
| `assertion_throws_exception` | Assertions throw |
| `assertion_error_type` | Assertion error level |
| `track_modules` | Optional list of modules to track |
| `log` | Logger config: optional `class_name` / `extension` / `required_file`, plus `settings` (`file`, `log_size`, …) |

```php
'exception_handling' => [
    'value' => [
        'debug' => false,
        'handled_errors_types' => E_ALL & ~E_NOTICE & ~E_USER_NOTICE,
        'exception_errors_types' => E_ALL & ~E_NOTICE & ~E_WARNING & ~E_USER_NOTICE & ~E_USER_WARNING & ~E_COMPILE_WARNING & ~E_DEPRECATED,
        'ignore_silence' => false,
        'assertion_throws_exception' => true,
        'assertion_error_type' => E_USER_ERROR,
        'log' => [
            'settings' => [
                'file' => 'bitrix/modules/error.log',
                'log_size' => 1000000,
            ],
        ],
    ],
    'readonly' => false,
],
```

## cookies / http_client_options / cache_flags (examples)

```php
'cookies' => [
    'value' => [
        'secure' => false,
        'http_only' => true,
    ],
    'readonly' => false,
],

'http_client_options' => [
    'value' => [
        // merged into every new HttpClient — redirect, timeouts, etc.
        'socketTimeout' => 30,
        'streamTimeout' => 60,
    ],
    'readonly' => false,
],

'cache_flags' => [
    'value' => [
        'config_options' => 3600,
        // ORM: "b_tablename_max_ttl" / "b_tablename_min_ttl" (see Entity::getCacheTtl)
    ],
    'readonly' => false,
],
```

## composer

```php
'composer' => [
    'value' => ['config_path' => '../composer.json'],
    'readonly' => true,
],
```

## crypto

Encryption keys for `CryptoField`, encrypted cookies. Store keys outside git — use `.settings_extra.php` or environment.

## readonly

- `true` — protects critical settings (DB, services) from runtime modification.
- `false` — allows runtime changes (e.g. `exception_handling`).

## Checklist

- [ ] User overrides in `/local/.settings.php`, not edited `/bitrix/.settings.php`.
- [ ] `debug => false` on production.
- [ ] Secrets in `.settings_extra.php` or env vars.
- [ ] `readonly => true` for connections and services.
- [ ] Module `services` / `controllers` / `console` in module `.settings.php`; routing only via global + `/local/routes/`.
- [ ] No fictional `validation` section — use `main.validation.service`.
