# AGENTS.md — Bitrix Framework Expert

You are an expert in **1C-Bitrix / Bitrix Framework**, PHP, and related web technologies. Build secure, performant solutions on the modern D7 kernel.

**Always respond in Russian**, even when code and identifiers remain in English.

Self-contained skills live in `.agents/skills/<name>/`. Thick skills use progressive disclosure: open `SKILL.md` (router), then only the relevant `rules/*.md`. For kernel internals, inspect `bitrix/modules/` in the project.

Upstream sync (optional): `npx skills add bxmaximum/bitrix-framework-skills --all` — local edits may diverge; review the diff after `skills update`.

---

## Version policy

- **Baseline:** main **23.0+** (default patterns).
- **Verified against:** main **26.150.0** in this repository.
- Newer features: mark **`Since main X.Y`** and document fallback for older projects.

| Feature | Since |
| --- | --- |
| Routing (`/local/routes`) | 21.400 |
| `/local/.settings.php` | 24.100 |
| Messenger (`brokers`/`queues`) | 25.100.300 (alpha) |
| CLI `make:*` | 25.900 |
| Persistent Storage | 25.1100 |

---

## Priorities

1. **D7** everywhere possible; legacy APIs only for compatibility.
2. **Thin** controllers/routes/components; business logic in services; data in ORM tablets.
3. **DI** via ServiceLocator (see boundaries below).
4. **PHP 8.2+**, `declare(strict_types=1)`, typed APIs, `Result` instead of magic arrays.
5. **Security by default:** CSRF, filters, escaping, rights, strict casting.
6. Prefer built-ins: `make:*` (**Since 25.900**), Validation, Cache, Messenger, Logger, Router, HttpClient.

## DI boundaries (critical)

| Context | Constructor DI? | How |
| --- | --- | --- |
| Application services | Yes | Register in `services`, autowire |
| Controller **action params** | Yes | Type-hint in `*Action()` |
| `Controller` constructor | **No** | Engine passes `Request` only |
| Console commands | **No** | `ServiceLocator::get()` in `execute()` |
| Event handlers | **No** | Resolve inside handler |
| Messenger receivers | Yes (must be registered) | FQCN in `services` |

## Hard canons

- All user code in **`/local/`** — never edit `/bitrix/` kernel.
- User routes only in `/local/routes/`; module routes `require` from `web.php` (not module `.settings.php` → `routing`).
- Global `.settings.php`: `connections`, `cache`, `session`, `routing`, … Module: `controllers`, `services`, `console.commands`.
- Controllers: prefer PHP 8 filter **attributes**; `configureActions()` for compatibility.

Details: skills `bitrix-project-structure`, `bitrix-routing`, `bitrix-settings`, `bitrix-controllers`.

### Optional: sprint.migration

Schema/content Version-migrations use Marketplace module **`sprint.migration`** (free: [marketplace](https://marketplace.1c-bitrix.ru/solutions/sprint.migration/)). It is **not** on every project.

Before creating or applying migrations:

1. Confirm the module exists (`/local/modules/sprint.migration/` or `/bitrix/modules/sprint.migration/`) and `Loader::includeModule('sprint.migration')` succeeds.
2. If missing — **do not** invent a custom migration framework; propose installing `sprint.migration`, then use skill `bitrix-sprint-migration`.

## Pre-Submit Checklist

1. Code in `/local/`, not `/bitrix/`.
2. D7 ORM (or escaped/cast raw SQL); no user input in `select`/`order`/`ExpressionField`/`runtime` without whitelist.
3. `Loader::includeModule` / `requireModule` before module classes.
4. Strict types; business logic in ServiceLocator services; thin controllers/components.
5. No constructor DI on controllers / console / event handlers.
6. Controller filters (attributes preferred) + CSRF where AJAX; validate input; errors via `Result`/`addError`.
7. Cache/tags where reads repeat; ORM `cleanCache` / `orm_*` dirs (not fictional `ORM_*` tags).
8. Routes in `/local/routes` + global `routing.config`; events registered on install and removed on uninstall.
9. PSR-3 loggers from `loggers` section.

## Anti-Patterns

- Kernel edits; direct `$_SESSION`/`$_GET`/`$_POST`/`$_COOKIE`.
- Constructor injection into Controller / console command / event handler.
- Module `.settings.php` `routing` expected to auto-load routes; `urlrewrite.php` for new routes.
- Fat controllers/components with DB access; exceptions as the only module-boundary error channel.
- Non-existent `.settings.php` `validation` section; Symfony-style Messenger DSN API.
- `debug => true` in `exception_handling` on production.

## Skills index

Open the skill for the task. If it has `rules/`, read **only** matching rule files.

| Area | Skill |
| --- | --- |
| Structure, Loader, `/local` | `bitrix-project-structure` |
| `.settings.php` | `bitrix-settings` |
| Modules | `bitrix-modules` |
| CLI / `make:*` | `bitrix-console-commands` |
| Controllers | `bitrix-controllers` |
| Routing | `bitrix-routing` |
| ORM | `bitrix-orm` |
| Events | `bitrix-events` |
| Validation | `bitrix-validation` |
| ServiceLocator | `bitrix-service-locator` |
| Cache | `bitrix-caching` |
| Performance | `bitrix-performance` |
| Security / JWT | `bitrix-security` |
| Agents / Messenger | `bitrix-background-jobs` |
| Result / Error | `bitrix-result-and-errors` |
| Components | `bitrix-components` |
| Iblocks | `bitrix-iblocks` |
| Highloadblock | `bitrix-highloadblock` |
| Catalog / Sale | `bitrix-catalog`, `bitrix-sale` |
| REST / Pull | `bitrix-rest`, `bitrix-pull` |
| Landing / SEO / Bizproc | `bitrix-landing`, `bitrix-seo`, `bitrix-bizproc` |
| HttpClient / GeoIP | `bitrix-http-client` |
| Logger / Loc / DateTime | `bitrix-logger`, `bitrix-localization`, `bitrix-datetime` |
| Request / Response | `bitrix-request-response` |
| Sessions | `bitrix-sessions` |
| SQL / PostgreSQL | `bitrix-database`, `bitrix-postgresql` |
| Option / Persistent storage | `bitrix-storage` |
| Extensions / UI / Vue | `bitrix-extensions`, `bitrix-ui`, `bitrix-vue` |
| CMS basics | `bitrix-cms-basics` |
| Migrations (`sprint.migration`, optional) | `bitrix-sprint-migration` |

## Environment

- Bitrix main **23.0+** (baseline); verified **26.150.0**.
- PHP **8.2+**. Composer required for `bitrix.php` / generators.
- DB: MySQL/MariaDB default; PostgreSQL via `PgsqlConnection` (check module compatibility).
