# CRM page URLs and detection

Facts verified against crm **25.700.0**. CRM SEF pages live in the `crm` module's own URL space
(`Bitrix\Crm\Service\Router` + global `urlrewrite`) — register application routes in `/local/routes/web.php`
only for your own URLs. Related: `bitrix-crm-smart` (item APIs), `bitrix-extensions` (asset bundles).

## URL structure: standard `/crm/` roots

- Entities: kanban `/crm/{deal|lead|invoice|quote}/kanban/...`, detail `/crm/{entity}/details/{id}/`.
- Smart processes: `/crm/type/{entityTypeId}/...` — kanban `type/{id}/kanban/category/{n}/`
  (`Router\Page\Item\KanbanPage::routes()`), detail `type/{id}/details/{id}/`
  (`Router\Page\ItemDetails\DynamicDetailsPage`).
- After urlrewrite the resolved script tail `index.php` may be appended to the path — anchor page
  patterns with `(?:/|$)`; a trailing-slash-only match drops those hits.
- Item detail shape is template-driven: `Router::getItemDetailUrl()` resolves via the
  `bitrix:crm.item.details` component template (new routing) or portal options `path_to_{entity}_*`
  (old). Templates are portal-configurable (`Router::getCustomUrlTemplates()`, `Option`) — broaden
  detail patterns instead of hardcoding one shape.

## Custom sections (`/page/`)

- All custom sections live physically under `/page/{sectionCode}/{pageCode}/` —
  `Bitrix\Intranet\CustomSection\Manager::PAGE_URL_TEMPLATE`.
- `Router::getCustomRoots(): array<int, string>` — entityTypeId → `Uri->getPath()`, filled by
  `initCustomRoots()` from `IntranetManager::getCustomSections()`; entity pages under a root:
  `{root}kanban/...`, `{root}details/{id}/...`.
- **Older kernels return the section root with `{root}type/{id}/...` under it** — keep the optional
  `type/\d+/` group in the tail pattern and verify against your kernel.

## Detecting the current page

- Two path sources differ: `HttpRequest::getRequestedPage()` is normalized `SCRIPT_NAME` — the page
  **after** urlrewrite, no query string; the raw SEF path from `getRequestUri()` is **before**. Match
  both candidates against your patterns.
- Platform API exists but is heavy and version-sensitive: `Container::getInstance()->getRouter()->matchPage($request): Router\Contract\Page`
  and `parseRequest($request): ParseResult` (`isFound()`, `getEntityTypeId()`, `getComponentName()`).
  Page-class component APIs change between kernel generations — do not lean on them for asset detection.

## OnProlog asset injection pattern

`OnProlog` fires on every portal hit — cheap regexes first, Router only behind a `/page/` guard:

```php
// candidates: post-rewrite page + raw SEF path
$paths = [(string)$request->getRequestedPage()];
$paths[] = (new Uri((string)$request->getRequestUri()))->getPath();

// 1) cheap standard patterns, broadened and anchored
$kanban = '~^/crm/(?:type/\d+|deal|lead|invoice|quote|item/\d+)/kanban(?:/|$)~';

// 2) custom sections: guard the physical root, then Router roots
if (preg_match('#^/page/#', $path)) {
    foreach (Container::getInstance()->getRouter()->getCustomRoots() as $root) {
        $custom = '~^' . preg_quote((string)$root, '~') . '(?:type/\d+/)?kanban(?:/|$)~';
        // match candidates against $custom...
    }
}
```

- Reference implementation: `local/modules/firstbit.crmstagehints/lib/Integration/Main/PageDetector.php`.
- **Never pin DOM selectors or URL shapes from source reading alone** — kernel-rendered markup and
  templates vary by version; fix them with a DOM probe on the live portal.
- **Never register `/crm/...` in `/local/routes/web.php` or `urlrewrite.php`** — the `crm` module routes
  its own SEF space; a shadowing rule silently wins over the module router.
- **Never hardcode the custom-root page shape** — `getCustomRoots()` values are entity page roots whose
  form differs across kernel versions (`{root}kanban/...` vs `{root}type/{id}/kanban/...`).
- **Never match a single path source** — `getRequestedPage()` is the rewrite target and may lose the SEF
  form; matching only the request URI misses rewritten hits, and vice versa.

## Checklist

- [ ] Matched both `getRequestedPage()` and raw URI path candidates.
- [ ] Standard patterns anchored `(?:/|$)`; `type/\d+`, `item/\d+` covered.
- [ ] Custom sections guarded by the `/page/` prefix before building the Router.
- [ ] Custom-root tails keep the optional `type/\d+/` group, verified on the live portal.
- [ ] Router (`matchPage`/`parseRequest`) used only where per-hit cost is justified.
- [ ] Selectors and URL shapes pinned by a DOM probe on the live portal.