# Anatomy: complex vs simple

A component fetches data via module APIs and renders HTML. Decide the anatomy **first**: complex (SEF, several pages) or simple (one page).

## Common Rules

- **Only `class.php` — never `component.php`.** All logic lives in `executeComponent()` or data-preparation methods; the template stays thin (`templates/.default/template.php`, `style.css`, `script.js` — minimal PHP).
- Component class namespace: `\{{VENDOR_NAME}}\<Module>\Component\<Name>Component` (module components).
- Module components ship in `install/components/<vendor>/` and are copied to `/local/components/` on install; standalone — directly in `/local/components/<vendor>/`. Name: `vendor.module.component_name`. Module anatomy → skill `bitrix-modules`; project placement → skill `bitrix-project-structure`.

## Complex Component (SEF, Several Pages)

One class file, several pages via SEF routing. `templates/.default/` contains **one file per page** (list.php, detail.php, error_page.php), not a single `template.php` — the page is included by name via `IncludeComponentTemplate($componentPage)`.

```
vendor.module.start/                 # complex (reference: acme.schedule.start)
├── .description.php
├── .parameters.php                  # SEF_MODE, SEF_FOLDER, SEF_URL_TEMPLATES
├── class.php                        # \Vendor\Module\Component\StartComponent
│   ├── extends \CBitrixComponent, implements Errorable
│   ├── const SEF_DEFAULT_TEMPLATES  # ['list' => 'list/', 'detail' => 'detail/#ID#/']
│   ├── const DEPENDENCY_MODULES     # checked with Loader::includeModule()
│   ├── const DEPENDENCY_EXTENSIONS  # loaded with Extension::load()
│   ├── onPrepareComponentParams()   # merge + normalize $arParams
│   └── executeComponent()
│       ├── checkRequirements()      # dependency check → ErrorCollection
│       ├── CComponentEngine::makeComponentUrlTemplates(...)
│       ├── CComponentEngine::parseComponentPath(...)
│       ├── CComponentEngine::initComponentVariables(...)
│       ├── process404(...)          # 404 if page not found
│       └── IncludeComponentTemplate($componentPage)
├── lang/ru/ (.parameters.php, class.php)
└── templates/.default/
    ├── list.php / detail.php / error_page.php
    └── lang/ru/ (list.php, detail.php)
```

## Simple Component

One page — one `template.php`. The class inherits the module's base component class (`lib/Component/`, reference: `ScheduleGridComponent`) or `\CBitrixComponent`; all logic in `executeComponent()`.

```
vendor.module.item.list/             # simple (reference: acme.schedule.item.list)
├── .description.php
├── .parameters.php
├── class.php                        # \Vendor\Module\Component\ItemListComponent
├── lang/ru/class.php
└── templates/.default/
    ├── template.php                 # the only template
    ├── style.css / script.js
    ├── result_modifier.php          # data prep before template (optional)
    ├── component_epilog.php         # runs after template (optional)
    └── lang/ru/template.php
```

## Checklist

- [ ] Decided complex vs simple before scaffolding.
- [ ] **`class.php` only — no `component.php`**; logic in `executeComponent()`.
- [ ] Complex: one file per page in `templates/.default/`, `IncludeComponentTemplate($componentPage)`.
- [ ] Simple: single `template.php`, base class from `lib/Component/` or `\CBitrixComponent`.
- [ ] Template thin — minimal PHP, no business logic.