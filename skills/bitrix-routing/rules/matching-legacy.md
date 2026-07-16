# Matching, PublicPageController, site-guard

## Matching and safety

- All files from `/local/routes/` and `/bitrix/routes/` merge into one `Router`. Matching is **first-match-wins** within the compiled set; order **inside one file** matters. Do not rely on order **across** files — each file must be self-correct.
- Legacy `$arUrlRewrite` from `urlrewrite.php` is checked **before** modern routes. A conflicting rewrite means the modern route never runs — remove the legacy rule when migrating.
- Compiled route regex is cached (`CompileCache` by file `mtime`). After edits that “don’t apply”, clear routing cache on the stand.
- **Do not** use routing `->middleware()` for auth, CSRF, or authorization. Middleware runs early (before normal prolog/controller filters). Protect Engine controllers via ActionFilter/attributes (`bitrix-controllers`); protect `PublicPageController` targets inside the included PHP.

## PublicPageController (legacy bridge)

Use `Bitrix\Main\Routing\Controllers\PublicPageController` only to include an existing public PHP page. Do not put new business logic behind it — new features go to Engine controllers.

```php
use Bitrix\Main\Routing\Controllers\PublicPageController;
use Bitrix\Main\Routing\RoutingConfigurator;

return function (RoutingConfigurator $routes): void {
    $siteDir = '/'; // leading slash — path under document root
    $sitePrefix = ltrim($siteDir, '/');

    $routes
        ->prefix($sitePrefix . 'docs')
        ->group(function (RoutingConfigurator $routes) use ($siteDir) {
            $routes->get('item/{id}/', new PublicPageController($siteDir . 'docs/item.php'))
                ->where('id', '[0-9]+')
                ->default('download', '0');

            $routes->any('{any}', new PublicPageController($siteDir . 'docs/index.php'))
                ->where('any', '.*');
        });
};
```

Caveats:

- `PublicPageController` `include`s the file and ends the request (`die()`). Engine prolog/filters do **not** wrap it — the page must validate input, rights, CSRF itself.
- Route parameters are copied into `$_GET` / `$_REQUEST`. Use `->default()` for flags the page reads from query.
- `$siteDir` (with leading `/`) for file paths; `$sitePrefix` (no leading `/`) for `prefix()`.

## Site-guard (multisite)

If routes belong to one site only, guard at the start of the closure and `return` without registering when the current request site does not match. Without a guard, those routes register for every site.

```php
use Bitrix\Main\SiteTable;

return function (RoutingConfigurator $routes): void {
    // Global/service routes (all sites) — register before guard
    // $routes->any('.well-known/{any}', …);

    $request = \Bitrix\Main\Context::getCurrent()->getRequest();
    $site = SiteTable::getByDomain($request->getHttpHost(), $request->getRequestUri())->fetch();
    if (!$site || ($site['LID'] ?? '') !== 's1') {
        return;
    }

    // site-specific routes…
};
```

Site-guard is not authorization — still check rights in the handler/controller.

## Migration from `urlrewrite.php`

1. For **new** routes, use `/local/routes/web.php` — `urlrewrite.php` is no longer needed.
2. Old `urlrewrite.php` can be left for legacy component SEF.
3. Migration rule: entry

    ```php
    ['CONDITION' => '#^/catalog/section/(\d+)/?$#', 'RULE' => 'SECTION_ID=$1', 'PATH' => '/catalog/section.php']
    ```

    is replaced by

    ```php
    $routes->get('/catalog/section/{id}', [Catalog::class, 'sectionAction'])->where('id', '\d+');
    ```

4. Clear `urlrewrite` cache when migrating: `CUrlRewriter::ReIndexAll()`.

## Checklist

- [ ] Web server forwards to `routing_index.php`.
- [ ] Global `routing.config` lists basenames; user files under `/local/routes/`.
- [ ] Module route files are `require`d from `/local/routes/web.php` (not module `.settings.php` `routing`).
- [ ] No conflicting `urlrewrite.php` rule for the same path.
- [ ] Groups use fluent `->prefix()->name()->group(fn)`; narrow routes before catch-all.
- [ ] State-changing routes use explicit verbs, not `any()`.
- [ ] Parameters constrained with `->where(...)`; names unique for `router()->route()`.
- [ ] Auth/CSRF via controller filters — not routing middleware.
- [ ] `PublicPageController` only for legacy includes; page handles security itself.
- [ ] Multisite: site-guard when routes are site-specific.
