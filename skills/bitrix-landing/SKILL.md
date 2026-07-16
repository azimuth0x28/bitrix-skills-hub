---
name: bitrix-landing
description: Covers Landing module — sites/landings, blocks repository, publish/unpublish flow, hooks (Metrika/GA/pixels), customization limits vs classic CMS. Applied for Sites24/landing pages, storefronts, knowledge bases on landing. Key terms — Landing, Site, Block, BlockRepo, publication, unpublic, hooks, PAGE, STORE.
---

# Landing Sites (`landing`)

Baseline: **main 23.0+**. Verified against kernel module `landing` in this repo.

Block-based sites (Sites24 / Landing) live in module `landing`, not in classic site templates. For classic CMS sites/templates/menus see skill `bitrix-cms-basics`.

```php
\Bitrix\Main\Loader::includeModule('landing');
```

## Entity Model

| Layer | Facade | Internal ORM |
| --- | --- | --- |
| Site | `\Bitrix\Landing\Site` | `\Bitrix\Landing\Internals\SiteTable` |
| Page (landing) | `\Bitrix\Landing\Landing` | `\Bitrix\Landing\Internals\LandingTable` |
| Block instance | `\Bitrix\Landing\Block` | `\Bitrix\Landing\Internals\BlockTable` |
| Domain / folder | `\Bitrix\Landing\Domain`, `\Bitrix\Landing\Folder` | internals tables |

`Site` and `Landing` extend `\Bitrix\Landing\Internals\BaseTable` and expose ORM-style `getList` / `add` / `update` / `delete`. Prefer facades over raw internals.

Site types (see `\Bitrix\Landing\Site\Type`): `PAGE`, `STORE`, `SMN`, scopes `KNOWLEDGE`, `GROUP`, `MAINPAGE`, pseudo-scope `crm_forms`.

Publication paths (constants on `\Bitrix\Landing\Manager`):

- `Manager::PUBLICATION_PATH` — `/pub/site/`
- `Manager::PUBLICATION_PATH_SITEMAN` — `/lp/`

## Create / Read Pages

```php
use Bitrix\Landing\Landing;
use Bitrix\Landing\Site;

// List pages of a site
$res = Landing::getList([
    'select' => ['ID', 'TITLE', 'CODE', 'ACTIVE', 'PUBLIC', 'SITE_ID'],
    'filter' => ['SITE_ID' => $siteId, '=DELETED' => 'N'],
]);

// Instance for block/publish operations
$landing = Landing::createInstance($landingId);
if (!$landing->exist()) {
    // missing / inaccessible
}

// Create page from demo template code
$addResult = Landing::addByTemplate($siteId, 'empty', [
    'TITLE' => 'Promo',
    'CODE' => 'promo',
]);
```

Sites:

```php
$siteUrl = Site::getPublicUrl($siteId, full: true, hostInclude: true);
$addSite = Site::addByTemplate('empty', 'PAGE');
```

## Blocks Overview

Blocks are HTML fragments from a repository (`BlockRepo::BLOCKS_DIR = 'blocks'`). Paths resolved via `BlockRepo::getGeneralPaths()` — typically `/bitrix/blocks/` and `/local/blocks/` (`getLocalPath('blocks')`).

```php
use Bitrix\Landing\Block;
use Bitrix\Landing\Block\BlockRepo;

$landing = Landing::createInstance($landingId, ['skip_files' => false]);

// Add block by repository code (e.g. '01.big_with_text')
$block = $landing->addBlock('01.big_with_text', [
    // optional content overrides
]);

$blocks = $landing->getBlocks(); // id => Block
$one = $landing->getBlockById($blockId);

// Repository catalog (sections + codes)
$repo = (new BlockRepo())->getRepository();
```

Useful block APIs: `Block::createFromRepository()`, `Block::publicationBlocks()`, `getManifest()`, `saveContent()` / content mutators on the instance.

Custom blocks: place under `/local/blocks/<namespace>/<code>/` with `block.php` + `.description.php` (same layout as kernel `install/blocks/bitrix/...`). Clear repo cache after deploy: `Block::clearRepositoryCache()` / `BlockRepo` cache.

## Publish Flow

Orienting APIs (do not invent REST wrappers):

| Action | API |
| --- | --- |
| Publish one page | `$landing->publication()` → bool |
| Dry-run publish errors | `$landing->fakePublication()` |
| Unpublish page | `$landing->unpublic()` |
| Publish whole site | `Site::publication($siteId, mark: true)` → `Result` |
| Unpublish site | `Site::unpublic($siteId)` / `Site::publication($id, false)` |
| Public URL | `$landing->getPublicUrl()`, `Site::getPublicUrl()` |
| Rights | `$landing->canPublication()`, `$landing->canEdit()` |

```php
$landing = Landing::createInstance($landingId);
if ($landing->canPublication() && $landing->publication()) {
    $url = $landing->getPublicUrl();
} else {
    $errors = $landing->getError(); // \Bitrix\Landing\Error
}

$siteResult = Site::publication($siteId, true);
if (!$siteResult->isSuccess()) {
    foreach ($siteResult->getErrors() as $error) {
        // verification / access errors
    }
}
```

AJAX/public-action layer (admin UI): `\Bitrix\Landing\PublicAction\Landing::publication($lid)` and related methods in `publicaction/landing.php` — same domain, UI-oriented.

Soft delete: `Landing::markDelete` / `markUnDelete`, `Site::markDelete` — recycle bin, not hard `delete()`.

## Hooks (SEO / Counters)

Page/site extras via `\Bitrix\Landing\Hook` / `Landing::getAdditionalFields` / `saveAdditionalFields`. Relevant hook classes under `lib/hook/page/`:

- `YaCounter` — Yandex.Metrika counter ID
- `GaCounter`, `Gtm` — Google Analytics / GTM
- `MetaMain`, `MetaOg`, `MetaRobots`, `MetaYandexVerification`, `MetaGoogleVerification`
- `PixelFb`, `PixelVk`, `Robots`

Do **not** confuse with `\Bitrix\Landing\Metrika\Metrika` — that is Bitrix product analytics (`AnalyticsEvent`) on publish, not Yandex.Metrika.

## Landing vs Classic CMS

| Need | Prefer |
| --- | --- |
| Marketing LP, block builder, STORE landing | `landing` |
| Multisite + PHP templates, menus, includes | classic CMS (`bitrix-cms-basics`) |
| Structured catalog/news with properties | `iblock` (`bitrix-iblocks`) |
| Deep custom PHP page logic | classic template / component — not a landing block |

Landing pages are not site templates under `/local/templates/`. Mixing: a Bitrix site (`CSite`) can host publication paths; content model is still Landing entities.

## Customization Limits

- Prefer hooks, custom blocks in `/local/blocks/`, REST/placements — avoid editing `/bitrix/modules/landing/`.
- Tariff/restriction gates: `\Bitrix\Landing\Restriction\Manager`, `Manager::FEATURE_*` constants.
- Rights: `\Bitrix\Landing\Rights`, `\Bitrix\Landing\Role`.
- Dynamic blocks / CRM forms have separate scopes — check `Site\Type` before assuming public URL.
- Internal URL rules: `\Bitrix\Landing\Internals\UrlRewriteTable` (`b_landing_urlrewrite`) maps RULE → LANDING_ID inside a landing site — not a global SEO 301 table.

## Checklist

- [ ] `Loader::includeModule('landing')` before facades.
- [ ] Mutate via `Landing` / `Site` / `Block`, not ad-hoc SQL on `b_landing_*`.
- [ ] Publish through `publication()` / `Site::publication()` after `canPublication()`.
- [ ] Custom blocks under `/local/blocks/`, cache cleared.
- [ ] Counters/meta via hooks / additional fields — not hardcoded in every block.
- [ ] Classic CMS tasks stay outside Landing (see `bitrix-cms-basics`).
