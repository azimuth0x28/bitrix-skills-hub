---
name: bitrix-chef
description: Use when building, creating, or configuring Bitrix JS extensions with @bitrix/chef — scaffold, dev/production builds, tests, lint, diag — and when migrating from deprecated @bitrix/cli. Covers bundle.config(.ts|.js) schema and chef.config.ts rules. Key terms — chef build, chef init, chef create, bundle.config.ts, chef.config, resolveNodeModules.
metadata: {type: knowledge}
---

# @bitrix/chef — build tool for Bitrix JS extensions

Baseline: **@bitrix/chef 1.24.x** (npm, Node.js >= 22), verified against v1.24.1 (published 2026-09-07). The CLI binary is `chef`; `bitrix ...` commands belong to deprecated `@bitrix/cli`.

Chef owns scaffold (`create`), environment init (`init build`/`init tests`), build (Rollup + Babel + PostCSS + Terser), TypeScript, testing (Playwright), linting, diagnostics, and the Flow.js → TypeScript migration for Bitrix JS extensions. Extension anatomy (directory structure, `config.php` semantics, `\Bitrix\Main\UI\Extension::load`, `config.php rel`) — see skill `bitrix-extensions`. Vue 3 components — see skill `bitrix-vue`.

## Install and requirements

```bash
npm uninstall -g @bitrix/cli       # remove the deprecated tool
npm install -g @bitrix/chef        # Node.js >= 22 required
```

- Commands run from the Bitrix project root; chef scans `bundle.config.ts`/`bundle.config.js`.
- Build writes only into `local/` (`local/js/`, `local/modules/*/install/js/`). `bitrix/` is read-only — used solely to resolve kernel-extension dependencies and namespaces.
- All tooling ships inside chef (`typescript`, `@playwright/test`, `mocha`, `chai`). For IDE support install locally: `npm install --save-dev typescript @playwright/test @types/mocha @types/chai`.

## Command matrix

| Task | Command |
| --- | --- |
| Project setup: `tsconfig.json`, `aliases.tsconfig.json`, `.browserslistrc` | `chef init build` |
| Test environment: `playwright.config.ts`, `.env.test` | `chef init tests` |
| Scaffold an extension | `chef create <name> [-t ts\|js] [-p path] [-f]` |
| Dev build (source maps, env = development) | `chef build [ext...|glob] [-w] [-p path] [-v] [-f]` |
| Production build (Terser, env = production) | `chef build ... --production` |
| Aliases regeneration (for scripts/hooks) | `chef aliases [-q]`; auto-run via `chef init hooks` |
| Types check without full build | `chef typecheck [ext...|glob] [--file ...] [--exclude ...]` |
| Lint via ESLint | `chef lint [ext...] [--fix] [--file ...] [--exclude ...] [--no-cache]` |
| Tests | `chef test [unit\|e2e\|module] [ext...|modules...] [flags]` |
| Web-features vs browser targets | `chef baseline [query] [--list]` |
| Project-wide diagnostics | `chef diag <subcommand>` |
| Flow.js → TypeScript | `chef flow-to-ts [ext...|glob] [--rm-ts] [--rm-js]` |

## Build

```bash
chef build main.core ui.buttons    # named extensions
chef build ui.bbcode.*             # glob: one nesting level
chef build im.v2.**                # glob: all levels
chef build                         # scan current directory
chef build ui.buttons -w           # dev build + watch
chef build ui.buttons --production # production build
```

- Globs: `*` = direct children, `**` = all descendants. In zsh escape them: `chef build ui.\*`.
- `-f/--force` skips checks and rebuilds; `-v/--verbose` shows build details. `--production`/`--development` set `NODE_ENV` before config load; `--reporter default|json` gives machine-readable output (denied with `-w`).
- Packages build **sequentially**; per package chef: parses config → Rollup (TS compile, Babel transpile, PostCSS autoprefix/SVGO/image-inline, Terser if enabled) → rewrites `config.php rel` from analyzed imports → emits source maps when enabled.
- Env replacement is static at build: `process.env.NODE_ENV`, `import.meta.env.MODE/PROD/DEV`. Plain `chef build` = dev values; `--production` = production values (this is what tree-shakes dev-only npm code).
- Dev mode: source maps **on**, minification **off**, Vue `__file` markers. Production: source maps **off**, minification **on**. **Release artifacts always come from `chef build --production`.**
- `protected: true` extensions are skipped in directory scans and glob runs — built only when named explicitly.
- **Never rely on a plain `chef build` for artifacts** — that is a dev build.
- **Never edit generated `dist/*.js`** — rebuild from sources instead.

### config.php interplay

Chef rewrites the `rel` array from ES-imports of the entry point, prepends `main.polyfill.core` when `main.core` is not a dependency, and adds `'skip_core' => true` when `main.core` is unused. **Never hand-edit `rel`** — the build overwrites it:

```php
<?php
if (!defined('B_PROLOG_INCLUDED') || B_PROLOG_INCLUDED !== true)
{
    die();
}

return [
    'js'  => './dist/ui.buttons.bundle.js',
    'css' => './dist/ui.buttons.bundle.css',
    'rel' => ['main.core'],   // auto-written by the build from imports
    'skip_core' => false,     // auto-added when main.core is not imported
];
```

### Extension name and namespace

- Name derives from the path: `local/js/ui/buttons/` → `ui.buttons`; in a module `install/js/crm-entity-selector/` → `firstbit.main.crm-entity-selector`. Project rule: extension IDs are `firstbit.<module>...`, bundle namespaces are `FirstBit.*`.
- `namespace` defaults to `window` — exports become bare globals. **Always set `namespace` explicitly** (e.g. `FirstBit.Deputy.UI`).
- A missing dependency namespace at runtime is fatal unless `safeNamespaces: true` compiles `?.`/`??` into the IIFE argument list.

## bundle.config(.ts|.js)

`bundle.config.ts` in the extension directory (JS config also supported). Live example with js+css split:

```ts
export default {
  input: './src/index.ts',            // .ts, .js or .css entry
  output: {
    js: './dist/my.bundle.js',
    css: './dist/my.bundle.css',      // extract CSS instead of inlining into JS
  },
  namespace: 'BX.FirstBit.Main.UI',
};
```

| Parameter | Type / default | Meaning |
| --- | --- | --- |
| `input` | `string`, default `./script.es6.js` | Entry: `.ts`, `.js` or `.css` (CSS-only: only `css` output needed) |
| `output` | `string \| {js?, css?}`, default `bundle.js`/`bundle.css` | Bundle path(s); object form splits JS/CSS |
| `namespace` | `string`, default `window` | Global namespace for entry exports |
| `concat` | `{js?, css?}` | Concatenate files in given order |
| `targets` | `string \| string[]` | Babel/PostCSS targets; supersedes deprecated `browserslist` |
| `sourceMaps` | `boolean` | Source maps generation |
| `minification` | `boolean \| object`, default `false` | Terser settings; `--production` flips on unless set here |
| `treeshake` | `boolean \| string \| object`, default `true` | Rollup preset (`'smallest'`, `'safest'`, `'recommended'`) or options |
| `plugins` | `Plugin[]` | Rollup-compatible plugins, appended after built-ins |
| `adjustConfigPhp` | `boolean`, default `true` | Rewrite `config.php rel` from imports; set `false` in template/component configs |
| `types` | `string` | Extra `.d.ts` for design-time resolution (aliases); zero runtime effect |
| `resolveNodeModules` | `boolean`, default `false` | Inline npm deps from `node_modules` (otherwise all npm deps stay external) |
| `babel` | `boolean`, default `true` | Babel transpilation to targets |
| `standalone` | `boolean \| object` | Inline all Bitrix + npm deps; `remap` maps ext names to other exts or `{npm, from}` |
| `protected` | `boolean` | Skip in scans |
| `rebuild` | `string[]` | Rebuild listed dependent extensions after this build |
| `transformClasses` | `boolean \| string[]` | Transpile classes (all, or named ones) for `BX.merge`/legacy patterns |
| `emitDeclaration` | `boolean \| 'ambient'\|'module'\|'both'`, default `true`/ambient | Emit `*.bundle.d.ts` with JSDoc for namespace hints (TS + real namespace only) |
| `safeNamespaces` | `boolean` | Optional chaining on dependency namespaces in IIFE args |
| `cssImages` | `object` | CSS `url()`: `type: 'inline'\|'copy'`, `maxSize` (KB, default 14), `output`, `absolutePaths` |
| `baseline` | `boolean`, default `true` | Fail build on unsupported web features for targets |

Babel removal strips JSDoc from the runtime bundle while keeping it in `.d.ts`. `cssImages.absolutePaths: true` rewrites `url(./icon.png)` to a computed public path (`/local/js/...`, `/bitrix/js/...`).

### CSS-only and images

```ts
export default {
  input: './src/style.css',            // CSS-only extension
  output: { css: './dist/style.bundle.css' },
  cssImages: { type: 'copy', output: './dist/images' },
};
```

## chef.config.ts (project root)

Rules for all extensions; per-extension `bundle.config` interacts as: `defaults` overridable, `enforce` final, `deny` blocks.

```ts
export default {
  deny: {
    sfc: true,                                  // ban Vue SFC (error)
    exportDefault: { severity: 'error', message: 'Use named exports' },
    standalone: { severity: 'warning' },        // warn only
  },
  defaults: { targets: 'last 2 versions' },     // bundle.config may override
  enforce: { sourceMaps: false },               // bundle.config may NOT override
};
```

Deny keys: `sfc`, `exportDefault`, `standalone`, `minification`, `resolveNodeModules`, `transformClasses`, `sourceMaps`. Severity `error` stops the build, `warning` prints a message.

## Browserslist

Resolution order: `targets` in bundle.config → nearest `.browserslistrc` walking up from the extension → `baseline widely available`. Migrate `browserslist: [...]` → `targets: [...]`; legacy key still works but is deprecated.

## Tests

```bash
chef init tests                      # playwright.config.ts + .env.test (BASE_URL, LOGIN, PASSWORD)
npx playwright install               # browser binaries
chef test ui.buttons                 # unit + e2e
chef test unit ui.buttons            # unit only, real browser (Chromium/Firefox/WebKit)
chef test e2e ui.buttons --update-snapshots   # unknown flags pass through to Playwright
chef test module crm                 # module scenario tests (multi-extension)
chef test ui.buttons --grep "render" --project chromium --headed --debug --console
```

- Layout: `tests/unit/*.test.ts` (Mocha + Chai), `tests/e2e/*.spec.ts` (Playwright Test); legacy `test/` directory is also discovered.
- Authenticated e2e: `import { test, expect } from 'ui.test.e2e.auth'` — `page` arrives logged in via `.env.test`.
- `.env.test` holds credentials — gitignore it, never commit.
- Unit tests run in real browsers via Playwright; Playwright comes from the project since v1.23.1 (declare `@playwright/test` in the project for consistent browsers).

## Diagnostics (`chef diag`)

| Subcommand | Reports |
| --- | --- |
| `top-used` / `top-deps` / `top-deps-tree` | Most depended-on / biggest direct / biggest transitive dependency sets |
| `top-bundle-size` / `top-total-size` | Heaviest artifacts (JS+CSS+assets) / own+deps code size; `--sort js\|own` |
| `deps-tree <ext>` | Dependency tree; `--depth 2`, `--why <ext>` finds a path to a dep |
| `bundle-size <ext>` | Bundle size; `--with-deps` adds dependencies |
| `config` | Extensions by bundle.config parameter: `--key namespace [--missing] [--except]` |
| `unused-deps` / `circular-deps` / `circular-imports` | Dead deps / dependency cycles / file-level import cycles |
| `find-usages <ext>` | JS usages (imports, namespace, extends); `--imports`, `--namespace`, `--kind extends`, `--list` |
| `find-loaders <ext>` | PHP-side loads (`Extension::load`, `CJSCore::Init`, `rel`) |
| `unused` / `re-exports` | Unreferenced extensions / re-export wrappers |
| `baseline` | Features unsupported by current targets |

Common flags: `-p path`, `-l limit` (default 20), `-i include`, `-x exclude` (glob patterns, comma or repeated).

## Migration: @bitrix/cli → @bitrix/chef

Config is fully compatible — existing `bundle.config.js` builds unchanged. Key deltas:

| @bitrix/cli | @bitrix/chef |
| --- | --- |
| `module.exports` | `export default` (TS config also supported) |
| `browserslist: true / [...]` | `targets: [...]`; `.browserslistrc` found automatically |
| `plugins: {resolve, babel, custom}` | `resolveNodeModules`, `babel`, `plugins: [...]` (legacy object still accepted) |
| default targets `IE >= 11, last 4 version` | default `baseline widely available` |
| `bitrix test` (Mocha + JSDom) | `chef test` (Playwright, real browsers) |
| build by path only | build by name + globs |

Steps: uninstall `@bitrix/cli` → install `@bitrix/chef` → `chef init build` → verify `chef build <ext>` → rename configs to `.ts` (optional) → `chef init tests` + `npx playwright install` → CI: `bitrix build`/`bitrix test` → `chef build`/`chef test`, Node >= 22. `chef init hooks` and `chef flow-to-ts` are Git-only (Mercurial dropped in v1.19.0).

## Negative knowledge

- The binary is `chef`. `bitrix build` belongs to `@bitrix/cli` and fails after migration — CI with `bitrix build` must switch to `chef build`.
- npm imports resolve to **external globals by default** — `import X from 'lodash'` lands as an unresolved external unless `resolveNodeModules: true` (or `standalone`).
- Omitted `namespace` exports to `window` — bare globals, collisions with other extensions.
- `chef lint` silently skips extensions when no `eslint.config.{js,mjs,cjs,ts,...}` exists in the project.
- Directory scans never build `protected: true` extensions — an "extension built by name only" surprise.
- Builds write only under `local/`; system extensions live in read-only `bitrix/js/` (override by copying into `local/js/`).
- v1.24.1 fixed a `.d.ts` feedback loop: earlier builds emitted declarations that broke the next build/typecheck with `TS2339` (`BX.PopupWindow`...) — upgrade if you see it.
- Chef compiles nothing from `lang/*.php` — `BX.message`/`Loc` loading stays kernel territory via `Extension::load`; expect zero lang processing in the bundle pipeline.
- Open bug [bitrix-tools/chef#3](https://github.com/bitrix-tools/chef/issues/3) (since 1.8.3, open at 1.24.1): `chef create` and `chef init` crash with `CF9002: The "paths[0]" argument must be of type string. Received null`. Root detection in `src/environment/utils/get-context.ts` requires **all** docroot markers in one directory — `bitrix/` + `index.php` + `urlrewrite.php` (`indicators.every(...)`); module source repos need `main` + `ui` + `crm`. Git repos that skip tracking `index.php`/`urlrewrite.php` resolve root to `null` and crash; `--path` does not rescue `init`. Workaround: `touch index.php urlrewrite.php` in the repo root (gitignore them if undesired).

## Checklist

- [ ] Built from sources; zero manual edits to `dist/*.js` or `config.php rel`.
- [ ] Release artifacts produced by `chef build --production` (dev build left for local work only).
- [ ] `namespace` set explicitly in every bundle.config (default `window` avoided).
- [ ] npm dependencies either declared externals intentionally or inlined via `resolveNodeModules`/`standalone`.
- [ ] Browser targets resolved consciously: `targets` or project `.browserslistrc` (fallback `baseline widely available`).
- [ ] `chef init build` run once per project (tsconfig + aliases + browserslist); aliases refreshed via `chef aliases`/hooks.
- [ ] `.env.test` gitignored; credentials never committed.
- [ ] CI uses `chef build`/`chef test` with Node.js >= 22.
- [ ] No Mercurial reliance: hooks and `flow-to-ts` are Git-only.
- [ ] Docroot markers present in the repo root: `bitrix/` + `index.php` + `urlrewrite.php` — `chef init`/`create` require all three (CF9002 otherwise, issue #3).
- [ ] Glob patterns escaped in zsh (`chef build ui.\*`).
