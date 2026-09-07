# Typical Project Directory Structure (from scratch)

<context>
  <system_context>
    Directory structure and modularity of 1C-Bitrix (on-premise): the typical project tree,
    the layout of the module, complex and simple components, class placement, namespaces, and naming conventions.
  </system_context>

  <domain_context>
    `/local/` (custom code) · modules `local/modules/{{vendor_name}}.<module>/` ·
    components `install/components/{{vendor_name}}/` · PSR-4 · namespace `\{{VENDOR_NAME}}\` (set in `AGENTS.md`).
  </domain_context>
</context>

<critical_rules enforcement="strict">
  <rule id="vendor-components" scope="components">
    Custom module components live in `install/components/{{vendor_name}}/` (copied to
    `local/components/{{vendor_name}}/` on install) or directly in `local/components/{{vendor_name}}/`.
    Component name: `{{vendor_name}}.<module>.<component_name>`.
  </rule>

  <rule id="class-location" scope="classes">
    Place new classes in `local/lib/` for monolith projects (e.g. DDD-based)
  </rule>

  <rule id="psr4-autoload" scope="classes">
    Follow the PSR-4 standard for autoloading
  </rule>

  <rule id="namespace-format" scope="classes">
    Format: `\{{VENDOR_NAME}}\<ModuleName>\<SubNamespace>\<ClassName>`; the fully qualified class name has
    the form: `\<NamespaceName>(\<SubNamespaceNames>)*\<ClassName>`
  </rule>

  <rule id="vendor-namespace" scope="classes">
    In Bitrix projects the vendor-level namespace is `\{{VENDOR_NAME}}\`
    (set in `AGENTS.md`); module example: `{{vendor_name}}.catalog` ->
    `\{{VENDOR_NAME}}\Catalog\Agents\PriceUpdateAgent`
  </rule>

  <rule id="file-namespace-match" scope="classes">
    File names in a namespace must match the namespace notation:
    `{{VENDOR_NAME}}\Billing\Internal\QueueMessenger\Message\BalanceSyncMessage` =>
    `local/modules/{{vendor_name}}.billing/lib/Internal/QueueMessenger/Message/BalanceSyncMessage.php`
  </rule>

  <rule id="one-class-per-file" scope="classes">
    One class per file; the file name must match the class name
  </rule>

  <rule id="file-naming-convention" scope="classes">
    Name files in a namespace using the same notation as the namespace:
    `{{VENDOR_NAME}}\Billing\Internal\QueueMessenger\Message\BalanceSyncMessage` =
    `/local/modules/{{vendor_name}}.billing/lib/Internal/QueueMessenger/Message/BalanceSyncMessage.php`
  </rule>

  <rule id="singular-namespace" scope="classes">
    Use SINGULAR for folder (class) names in namespace paths: `lib\Agent\`,
    `lib\Model`, etc.
  </rule>

  <rule id="class-php-only" scope="components">
    Each new component: only `class.php` (MUST NOT: `component.php`); service-call logic lives in
    `executeComponent()` or in data-preparation methods
  </rule>

  <rule id="template-dumb" scope="components">
    Component template: `templates/.default/template.php`, `style.css`, `script.js` — minimal
    PHP logic in the template
  </rule>

  <rule id="namespace-vendor" scope="classes">
    Namespaces: `{{VENDOR_NAME}}\Main\Service`, `{{VENDOR_NAME}}\Helpdesk\Model`, etc.
    (or the chosen vendor)
  </rule>
</critical_rules>

## Standards & conflicts

Normative sources define how new artifacts are built. Existing code is evidence of current
state, never a structural standard.

Priority ladder (highest wins):

1. Explicit user instruction for the current task
2. Domain skill canon (e.g. `bitrix-modules` for module structure — normative: scaffolded
   skeletons, generated core)
3. Tier-1 rule files
4. The root `AGENTS.md`
5. Existing repo code — reference ONLY when no suitable skill covers the case, no rule covers
   the case, and skill + rules give no solution approach; otherwise prefer kernel examples
   (`/bitrix/modules`)

Conflict protocol:

- **Norm vs norm** (skill vs Tier-1 rule vs root file vs task doc): STOP — request explicit
  user confirmation. Never resolve silently.
- **Norm vs existing code:** the norm wins. Flag the code deviation; copying it is a defect.
- A stale fact found in any rules file is fixed in the same change; distrust is scoped to
  that fact only.
- Every plan creating a module or component carries a canon-conformance self-review item;
  deviations go under "Deviations — requires user approval".

---

## Typical Project Structure

```
<project-root>/
└── .gitignore                 	   # Git ignore for the project
├── .editorconfig                  # Editor settings
├── .gitattributes                 # Git attributes
├── .gitlab-ci.yml                 # CI/CD configuration
├── AGENTS.md                      # Instructions for AI agents
├── README.md                      # Project description and conventions for developers
│
└── local/                         # Custom code (main development)
    ├── activities/                # Business Process editor operations (activities)
    │   └── custom/
    │       ├── /<BusinessProcessActivity>
    │
    ├── components/                # Components
    │   ├── bitrix/                # Overridden system components
    │   └── <vendor>/            # Custom components
    │       ├── <Component>
    │
    ├── js/                        # JavaScript
    │   └── <vendor>/
    │       ├── <extension>/      # Bitrix extension @bitrix/cli
    │
    ├── modules/                   # Modules
    │   └── <vendor>.<modulename>  # Custom modules
    │
    ├── php_interface/             # Bitrix integration
    │   ├── lib/                   # Shared libraries for cases when developers don't know where to put code
    │   ├── cron_events.php        # Cron tasks
    │   ├── init.php               # Initialization - minimal content - only composer autoload
    │   └── this_site_support.php  # Site support info in the admin footer
    │
    ├── vendor/                    # Composer dependencies
    ├── composer.json              # Project dependencies with module composer.json includes
    ├── .phpcs.xml                 # PHP CodeSniffer config
    ├── .php-cs-fixer.dist.php     # PHP CS Fixer config
    └── .gitignore                 # Git ignore for local
```

## Typical module structure:

```
{{vendor_name}}.<module>/
├── install/                      # module installation
│   ├── components/               # components (public)
│   │   └── {{vendor_name}}/
│   │       ├── <module>.<component_name_1>/
│   │       │   ├── class.php              # component class
│   │       │   ├── .description.php       # description for the admin panel
│   │       │   ├── .parameters.php        # parameters
│   │       │   ├── lang/                  # language files
│   │       │   │   └── ru/
│   │       │   │       └── .description.php
│   │       │   └── templates/              # templates
│   │       │       └── .default/
│   │       │           ├── template.php   # main template
│   │       │           ├── style.css     # styles
│   │       │           └── script.js     # scripts
│   │       ├── <module>.<component_name_2>/        # other components
│   │       └── (other module components)
│   ├── db/                        # SQL scripts
│   │   ├── install.sql            # DB schema on install
│   │   └── update_0.0.1.sql       # migrations (if needed)
│   └── index.php                  # module registration
├── lib/                           # main code
│   ├── Agent/                     # agents (CRON tasks)
│   │   └── SyncAgent.php
│   ├── Component/                 # base component classes
│   │   ├── AbstractEntityComponent.php
│   │   └── (abstract classes for inheritance in /local/components/)
│   ├── Controller/                # Ajax|Rest controllers
│   │   ├── Entity1Controller.php       # Controller in the module root scope
│   │   └── <Scope>
│   │       └── Entity2Controller.php   # Controller in a dedicated scope
│   ├── Integration/               # integration with external systems and modules
│   │   └── <ExternalSystem>/      # Name of the integrated system
│   │   └── <ExternalModuleName>/  # name of the project module the current one integrates with
│   │       └── Service|Factory|.../   # Classes extending the external module's functionality
│   │       └── EventHandler/      # event handlers of the external module
│   │           └── (integration event handlers)
│   │   └── <module>/
│   │        └── EventHandler.php  # event handlers of the current module
│   ├── Internal/                  # internal module components
│   │   ├── Util|Tool/             # internal helper classes
│   │   ├── Error/                 # custom error classes
│   │   ├── Exception/             # custom exception classes
│   │   └── QueueMessenger/       # message queue
│   │       ├── Message/
│   │       │   └── SyncMessage.php
│   │       └── Receivers/
│   │           └── SyncReceiver.php
│   ├── Model/                     # ORM entities (Bitrix ORM)
│   │   ├── Entity1Table.php       # Simple table
│   │   ├── Entity2                # Orm Annotated tables (https://docs.1c-bitrix.ru/pages/orm/annotations.html)
│   │   		└── Entity2Table.php        #
│   │   		└── Entity2Collection.php   #
│   │   		└── Entity2.php             #
│   ├── Module/                   # module configuration
│   │   ├── Configuration.php     # configuration management
│   │   ├── Constants.php         # module constants
│   │   ├── EventManager.php      # event subscription (single place)
│   ├── Repository/               # repositories for ORM - extended data access methods
│   │   ├── Entity1Repository.php
│   │   └── (entity registries)
│   └── Service/                  # business logic and domain-specific methods
│       ├── Container.php         # service container (ServiceLocator)
│       ├── Entity1Service.php
│       ├── Entity2Service.php
│       └── (services per entity)
└── AGENTS.md                      # module documentation for AI agents
└── README.md                      # module documentation for humans
```

---

## Components: Complex and Simple

Custom module components live in `install/components/{{vendor_name}}/` (copied to
`local/components/{{vendor_name}}/` on install) or directly in `local/components/{{vendor_name}}/`.
Component name: `{{vendor_name}}.<module>.<component_name>`.

### Complex component

Manages several pages via SEF routing. The page file is included by name via
`IncludeComponentTemplate($componentPage)` — hence `templates/.default/` contains **one file per page**
(list.php, detail.php...), not a single `template.php`.

```
{{vendor_name}}.<module>.start/          # complex component (reference: deputy.schedule.start)
├── .description.php                     # description for the admin panel
├── .parameters.php                      # parameters: SEF_MODE, SEF_FOLDER, SEF_URL_TEMPLATES, ...
├── class.php                            # class: \{{VENDOR_NAME}}\<Module>\Component\<Name>Component
│   ├── extends \CBitrixComponent, implements Errorable
│   ├── const SEF_DEFAULT_TEMPLATES      # ['list' => 'list/', 'detail' => 'detail/#ID#/']
│   ├── const DEPENDENCY_MODULES         # modules checked with Loader::includeModule()
│   ├── const DEPENDENCY_EXTENSIONS      # UI extensions loaded with Extension::load()
│   ├── onPrepareComponentParams()       # merge and normalize $arParams
│   ├── executeComponent()
│   │   ├── checkRequirements()          # dependency check → ErrorCollection
│   │   ├── CComponentEngine::makeComponentUrlTemplates(...)
│   │   ├── CComponentEngine::parseComponentPath(...)    # resolve the current page
│   │   ├── CComponentEngine::initComponentVariables(...)
│   │   ├── Tools::process404(...)       # 404 if the page is not found
│   │   └── IncludeComponentTemplate($componentPage)     # includes the page file
│   └── showErrors()
├── lang/ru/
│   ├── .parameters.php
│   └── class.php                        # Loc::loadMessages(__FILE__)
└── templates/.default/
    ├── list.php                         # list page (instead of template.php)
    ├── detail.php                       # detail view page
    ├── error_page.php                   # error page
    └── lang/ru/                         # page language files
        ├── list.php
        └── detail.php
```

### Simple component

One page — one `template.php` template. The class inherits the module's base component class
(`lib/Component/`, reference: `TabletGridComponent`) or `\CBitrixComponent`; all logic lives in `executeComponent()`.

```
{{vendor_name}}.<module>.<name>/         # simple component (reference: deputy.schedule.item.list, deputy.schedule.item.detail)
├── .description.php
├── .parameters.php
├── class.php                            # class: \{{VENDOR_NAME}}\<Module>\Component\<Name>Component
│   └── extends <BaseComponent>|CBitrixComponent
│       └── executeComponent()           # logic + IncludeComponentTemplate()
├── lang/ru/
│   └── class.php
└── templates/.default/
    ├── template.php                     # the only template
    ├── style.css                        # styles
    ├── script.js                        # scripts
    ├── result_modifier.php              # data preparation before the template (optional)
    ├── component_epilog.php             # runs after the template (optional)
    ├── .parameters.php                  # template parameters (optional)
    └── lang/ru/
        └── template.php
```

---

## Class and Namespace Placement

**Mandatory requirements:**

1. **Class placement**
    - Place new classes in `local/lib/` for monolith projects (e.g. DDD-based)
    - Recommended for module-based projects: `local/modules/{{vendor_name}}.<modulename>/lib/`
    - Follow the PSR-4 standard for autoloading
    - Use composer-compatible autoloading when possible within the project

2. **Namespace**
    - Format: `\{{VENDOR_NAME}}\<ModuleName>\<SubNamespace>\<ClassName>`
    - The fully qualified class name has the form: `\<NamespaceName>(\<SubNamespaceNames>)*\<ClassName>`
    - In Bitrix projects the vendor-level namespace is `\{{VENDOR_NAME}}\` (set in `AGENTS.md`)
    - Module example: `{{vendor_name}}.catalog` -> `\{{VENDOR_NAME}}\Catalog\Agents\PriceUpdateAgent`
    - Module in the file system: `local/modules/{{vendor_name}}.catalog/`
    - File names in a namespace must match the namespace notation: `{{VENDOR_NAME}}\Billing\Internal\QueueMessenger\Message\BalanceSyncMessage` => `local/modules/{{vendor_name}}.billing/lib/Internal/QueueMessenger/Message/BalanceSyncMessage.php`

3. **File naming**
    - One class per file
    - The file name must match the class name
    - Example: class `PriceUpdateAgent` in the file `PriceUpdateAgent.php`

**Example of a module-based project structure:**
```
local/
└── modules/
    └── {{vendor_name}}.catalog/
        ├── install/
        │   └── index.php
        ├── lib/
        │   ├── Agent/
        │   │   └── PriceUpdateAgent.php
        │   ├── Service/
        │   │   └── PriceService.php
        │   └── Model/
        │       └── Product.php
        └── .settings.php
```

---

## Conventions

- Use SINGULAR for folder (class) names in namespace paths: `lib\Agent\` `lib\Model`, etc.
	- Prefer singular (e.g.,
		App\Service, User\Repository), since a namespace logically groups classes and represents a single entity, not a
		collection. Plural (Controllers, Models) is acceptable when it reflects the content more accurately, but
		singular is considered the standard in most ecosystems (PHP, C#, Java)
- Name files in a namespace using the same notation as the namespace
	`{{VENDOR_NAME}}\Billing\Internal\QueueMessenger\Message\BalanceSyncMessage` =
	`/local/modules/{{vendor_name}}.billing/lib/Internal/QueueMessenger/Message/BalanceSyncMessage.php`
- Each new component: only `class.php` (MUST NOT: `component.php`), service-call logic in `executeComponent()` or in
	data-preparation methods.
- Component template: `templates/.default/template.php`, `style.css`, `script.js` — minimal PHP logic in the template.
- Namespaces: `{{VENDOR_NAME}}\Main\Service`, `{{VENDOR_NAME}}\Helpdesk\Model`, etc. (or the chosen vendor).
