---
name: bitrix-seo
description: Covers SEO module — sitemap generation, robots.txt, webmaster/search-engine engines, keywords/tools orientation; links to iblock IPROPERTY / InheritedProperty for page meta. Applied for crawl maps, Webmaster/Search Console wiring, SEO tooling. Key terms — Sitemap, Generator, Job, RobotsFile, Webmaster, SearchEngine, InheritedProperty, IPROPERTY_TEMPLATES.
---

# SEO Module (`seo`)

Baseline: **main 23.0+**. Verified against kernel module `seo` in this repo.

```php
\Bitrix\Main\Loader::includeModule('seo');
```

The `seo` module covers **sitemap generation**, **robots.txt helpers**, **search-engine / webmaster integrations**, keyword tools, and ads/analytics connectors. It does **not** replace iblock SEO templates — page title/description for catalog/news live in `iblock` InheritedProperty (see below and skill `bitrix-iblocks`).

## Sitemap

ORM config: `\Bitrix\Seo\Sitemap\Internals\SitemapTable` → `b_seo_sitemap` (`SITE_ID`, `ACTIVE`, `NAME`, `DATE_RUN`, `SETTINGS`).

Generation:

| Class | Role |
| --- | --- |
| `\Bitrix\Seo\Sitemap\Generator` | Multistep build for one sitemap id (`run()`) |
| `\Bitrix\Seo\Sitemap\Job` | Job/agent orchestration (`addJob`, `markToRegenerate`, `doJobAgent`) |
| `\Bitrix\Seo\Sitemap\Type\Step` | Step constants for the generator |
| `\Bitrix\Seo\Sitemap\Source\Iblock` | Iblock URL source during generation |
| `\Bitrix\Seo\Sitemap\File\*` | XML file writers |

```php
use Bitrix\Seo\Sitemap\Internals\SitemapTable;
use Bitrix\Seo\Sitemap\Job;
use Bitrix\Seo\Sitemap\Generator;

$row = SitemapTable::getById($sitemapId)->fetch();
// SETTINGS is serialized array (dirs, iblocks, file mask, …)
// prepare via SitemapTable::prepareSettings($arSettings) when saving from forms

// Queue background regeneration (agent-driven)
Job::markToRegenerate($sitemapId);

// Or drive steps in-process (admin/stepper style)
$generator = new Generator($sitemapId);
$done = $generator->run(); // false while more steps remain
```

`Job::addJob($sitemapId)` registers a row; `Job::doJobAgent($sitemapId)` is the agent entry. Statuses: `Job::STATUS_REGISTER|PROCESS|FINISH|ERROR`.

Admin UI: `/bitrix/admin/seo_sitemap.php`, `seo_sitemap_edit.php`. Prefer `Job`/`Generator` over reimplementing XML writers.

## robots.txt

`\Bitrix\Seo\RobotsFile` extends `Bitrix\Main\IO\File` for site document root `robots.txt`.

```php
use Bitrix\Seo\RobotsFile;

$robots = new RobotsFile($siteId); // SITE_ID like 's1'
$robots->addRule(['Sitemap', 'https://example.com/sitemap.xml']);
// SECTION_RULE = 'User-Agent', SITEMAP_RULE = 'Sitemap'
```

Useful when sitemap generation should register a Sitemap line. Admin: `seo_robots.php`.

## Webmaster / Search Engines

Engine registry: `\Bitrix\Seo\SearchEngineTable` (`b_seo_search_engine`, field `CODE`).

Concrete engines under `\Bitrix\Seo\Engine\`:

- `\Bitrix\Seo\Engine\Yandex` — Yandex Webmaster API (`ENGINE_ID = 'yandex'`)
- `\Bitrix\Seo\Engine\Google` — Google Search Console oriented client
- Bases: `YandexBase`, shared `\Bitrix\Seo\Engine` / `IEngine`

Webmaster service facade:

```php
use Bitrix\Seo\Webmaster\Service;

// GROUP = 'webmaster', TYPE_GOOGLE = 'google'
$sites = Service::getSites(); // host => binded/verified flags or error
```

OAuth / client callback uses `\Bitrix\Seo\Service::REDIRECT_URI` (`/bitrix/tools/seo_client.php`) — **OAuth redirect**, not HTTP 301 SEO redirects.

Domain helpers: `\CSeoUtils::getDomainsList()`, `getDirStructure()` (autoloaded from `classes/general/seo_utils.php`).

## Keywords and Page Tools

Legacy helpers (still in module):

- `\CSeoKeywords` — keywords by URL (`Add` / `Update` / `GetByURL`)
- `\CSeoPageChecker` — page SEO check used by admin tools
- Panel hooks: `CSeoEventHandlers` on `main` / `fileman`

Admin entry points: `seo_tools.php`, `seo_search_yandex.php`, `seo_search_google.php`.

## “Redirects” Boundary (no invented API)

There is **no** `seo` DataManager for SEO HTTP 301/302 rules in this kernel.

| Concern | Where it lives |
| --- | --- |
| Crawl allow/deny + sitemap URL | `RobotsFile`, sitemap `SETTINGS` |
| OAuth callback URL | `Bitrix\Seo\Service::REDIRECT_URI` |
| Open-redirect allowlist | `security` — `CSecurityRedirect`, `\Bitrix\Security\RedirectRuleTable` |
| App/page redirects | Routing / web server / `LocalRedirect` — not `seo` |

Do not invent `SeoRedirectTable`. After URL changes: update content URLs, regenerate sitemap (`Job::markToRegenerate`), adjust robots if needed.

## Iblock Meta (cross-ref `bitrix-iblocks`)

Catalog/section/element title, description, and related SEO strings are **not** stored in `seo` module tables. Use InheritedProperty:

```php
\Bitrix\Main\Loader::includeModule('iblock');

// Resolved values for an element
$values = (new \Bitrix\Iblock\InheritedProperty\ElementValues($iblockId, $elementId))
    ->getValues();
// e.g. ELEMENT_META_TITLE, ELEMENT_META_DESCRIPTION, …

// Templates (IPROPERTY_TEMPLATES) when saving element/section/iblock
$templates = new \Bitrix\Iblock\InheritedProperty\ElementTemplates($iblockId, $elementId);
$templates->set([
    'ELEMENT_META_TITLE' => '{=this.Name}',
    // …
]);
```

Related: `SectionValues` / `SectionTemplates`, `IblockTemplates`, ORM `\Bitrix\Iblock\InheritedPropertyTable`. Sitemap generation **reads URLs** from iblocks via `Sitemap\Source\Iblock`; meta tags still come from InheritedProperty / page components.

Landing-page counters/meta use Landing hooks (`YaCounter`, `MetaMain`, …) — skill `bitrix-landing` — not `seo` Sitemap.

## Analytics / Ads (orientation only)

Same module hosts retargeting/ads/analytics namespaces (`Bitrix\Seo\Analytics\`, `Retargeting\`, `LeadAds\`, …). Use when wiring ad cabinets; not required for classic sitemap/robots tasks.

## Checklist

- [ ] `Loader::includeModule('seo')` for Sitemap/Robots/Engine classes.
- [ ] Persist sitemap rows via `SitemapTable`; regenerate via `Job` / `Generator`.
- [ ] Register Sitemap in robots with `RobotsFile` when appropriate.
- [ ] Element/section meta via InheritedProperty — not custom columns in `b_seo_*`.
- [ ] Do not invent SEO redirect CRUD in `seo`; use server/routing or document the real module.
- [ ] Webmaster OAuth callback ≠ SEO URL redirect.
