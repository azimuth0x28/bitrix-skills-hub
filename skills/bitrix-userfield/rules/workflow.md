# End-to-End Workflow
Ordered process for creating a custom UF type for the kernel-confirmed bindings — CRM entities,
smart processes, iblock sections, HL-blocks, users — any portal, greenfield or long-lived. Iblock
element characteristics are iblock properties, a different API (`entity-bindings.md`). Prints the
order and the verifiable exits; every API detail lives in the knowledge rules (`type-class.md`,
`entity-bindings.md`, `render-component.md`, `js-extension.md`, `crm-filter.md`,
`bizproc-output.md`) — open as referenced; data safety and verification: `verification-recovery.md`.

## Field contract and identifiers

**Input:** the request. **Action:** fix the requirement in a written contract that records four
identifiers, each in its own slot:

| Identifier | Level | Uniqueness | When it exists |
|---|---|---|---|
| `USER_TYPE_ID` | Type | Portal-wide | At contract time |
| `FIELD_NAME` | Field instance | Per `ENTITY_ID` | At contract time |
| `ENTITY_ID` | Entity binding | Portal | At contract time |
| Numeric row ID | Field row (`b_user_field.ID`) | Portal | **After** the field is created |

The `ENTITY_ID` shape differs per binding — take it from the binding matrix (`entity-bindings.md`);
smart-process ids derive via
`Container::getInstance()->getFactory($entityTypeId)->getUserFieldEntityId()` — the type's DB id
differs from its `entityTypeId`. Record semantics, multiplicity, wanted integrations, and impact on
existing data. **Exit:** the contract names all four identifiers distinctly; nothing is created
before it; existing-field changes need the consent step of `verification-recovery.md`.

## Native-type decision, branches, and environment discovery

Two branches: **reuse** validates the stock field instance and rendering; **custom** runs the
type/registration and rendering stages (a stock type already carries storage, a widget, and the CRM
filter surface; a custom one starts inert there). Both branches fix the **environment mode** first:

| Requirement semantics | Rule |
|---|---|
| Text, number, boolean, date, enum, plain list | Reuse the matching kernel type |
| Reference to iblock elements / sections | Reuse kernel `iblock_element` / `iblock_section` |
| Reference to users | Reuse kernel `employee` (intranet module) |
| Reference to HL-block rows | Reuse kernel `hlblock` (highloadblock module) |
| Reference to CRM entities | Reuse kernel `crm` |
| Custom storage or widget semantics no stock type covers | Custom class per `type-class.md` |

| Mode | Portal state | Rule |
|---|---|---|
| A — existing | Long-lived portal: conventions, modules, `/local` | Discover and follow the portal's conventions |
| B — greenfield | Fresh kernel: no `/local`, no modules, no conventions | Record the defaults as the discovery exit |

**Mode A.** Read and follow the portal's sources: `AGENTS.md`/`CLAUDE.md` conventions, module
`composer.json` (merge-plugin, `psr-4`/autoload), module layout and event scheme, and tooling in
`local/vendor/bin` (`php-cs-fixer`, `phpcs`; `@bitrix/chef`); never export another project's vendor.

**Mode B (defaults).** Recorded defaults are the exit. Scaffold a minimal custom module at
`local/modules/<vendor>.<module>/` per the module canon (`make:module` when available, manual
skeleton), choose vendor and namespace explicitly — the portal's name or a declared project vendor —
place the class at `<module>/lib/UserField/Type/` (install skeleton below). No-module fallback:
`local/php_interface/init.php` (runtime-only, see `Type class and registration`).

An unverifiable fact is marked "verify in your project" and blocks the next stage. **Exit:** the
mode is recorded with evidence — A: discovered conventions quoted from the portal; B: the chosen
module path, vendor, and namespace as defaults.

## Type class and registration

Custom branch only. Open `type-class.md` for the class anatomy and mandatory methods, create the
class at `<module>/lib/UserField/Type/`, then make it loadable and register the type.

Minimal self-contained install skeleton (greenfield-safe):
- `install/index.php`: the installer class `extends CModule` with `$MODULE_ID`; the constructor
  reads `install/version.php` (`$arModuleVersion['VERSION']`) into `MODULE_VERSION`.
- `DoInstall`: `RegisterModule($this->MODULE_ID)`, then the persistent handler
  `RegisterModuleDependences('main', 'OnUserTypeBuildList', '<vendor>.<module>', MyType::class,
  'getUserTypeDescription')`; `InstallFiles()` ships the field's components when present.
- `DoUninstall`: `UnRegisterModuleDependences(...)` first (same args, no SORT), then `UnInstallFiles()`
  removes owned installed files; `UnRegisterModule($this->MODULE_ID)` follows. Retain user data until approved removal.
- `include.php`: `Loader::registerAutoLoadClasses('<vendor>.<module>', [MyType::class =>
  'lib/UserField/Type/MyType.php'])` — the type's file, mapped per request.
- Fresh requests: `ExecuteModuleEventEx` includes the handler's module (`CModule::IncludeModule`)
  before invoking it, so the class resolves and the type appears in `CUserTypeManager::GetUserType()`
  (keys by `USER_TYPE_ID`, last wins).

Runtime registration in `include.php` (via `EventManager::getInstance()->addEventHandler`) also
needs the module INSTALLED and included. True no-module alternative: `local/php_interface/init.php` —
`require_once` the class or `Loader::registerAutoLoadClasses(...)`, then the legacy
`AddEventHandler('main', 'OnUserTypeBuildList', [MyType::class, 'getUserTypeDescription'])`.

Mode A keeps the portal's **discovered** event scheme; a custom `getRunTimeEventHandlers()` map is
a project convention with its own dispatcher, not a kernel API — verify the dispatcher applies it.
Mode B uses the skeleton above. Static exit: `php -l` on every new PHP file plus the handler
present in the registration source; type availability (`GetUserType`) is a portal-manual check.

## Field instance

Open `entity-bindings.md` for the binding's `ENTITY_ID` form, storage mechanism, and where the
field is created in the UI; create it in that binding's field editor under `FIELD_NAME` with
`USER_TYPE_ID`. The row lands in `b_user_field` with the four identifiers and a numeric `ID`,
`SETTINGS` through `prepareSettings`. **Exit:** a row carries all four identifiers with the right
`ENTITY_ID` and settings save/read back; a save failure is fixed in `prepareSettings`, never by
deleting the row. Storage is provider-specific — UTS column before the row, HL `UF_*` after
(`entity-bindings.md`); probe the provider's column/multiple table (`verification-recovery.md`).

## Rendering and optional integrations

Open `render-component.md` and serve at least `main.view` and `main.edit`; the binding chooses the
pages hosting these surfaces (`entity-bindings.md`). Scalar kinds print the stored value directly;
reference kinds re-query names by ID; the edit surface fulfils the `FIELD_NAME` control contract.
Custom branch authors templates; reuse validates the round-trip. **Exit:** the view prints
correctly for the value kind and the edit round-trips a save.

Then choose integrations independently with the table; an unselected row is skipped and changes nothing:

| Situation | Rule |
|---|---|
| Reusable or non-trivial client logic (picker dialog) | `js-extension.md` |
| Field must appear and filter in the CRM entity grid | `crm-filter.md` — CRM only |
| BizProc templates must print names | `bizproc-output.md` — CRM only (see its iblock note) |
| Simple enum display | Server-side from `USER_TYPE['FIELDS']`; no extension |

Each selected integration meets the exit of its rule's checklist; unmet exits stop the run — record
the failing check and evidence in the handoff, never paper over it.

## Canon per stage (when the bitrix-* family is available)

| Stage | Canon |
|---|---|
| Module creation and install lifecycle | `bitrix-modules` |
| Component and template anatomy | `bitrix-components` |
| JS extension layout and build | `bitrix-extensions`, `bitrix-chef` |
| ORM/DB access for stored values | `bitrix-orm`, `bitrix-database` |
| CSRF, XSS, SQLi, access rights | `bitrix-security` |
| Server-side input validation | `bitrix-validation` |
| Operation results and error propagation | `bitrix-result-and-errors` |
| Settings and persistent state | `bitrix-settings`, `bitrix-storage` |
| Service wiring / DI | `bitrix-service-locator` |

Boundary: custom iblock element characteristics are **properties**, not UF — `bitrix-iblocks` (`entity-bindings.md`).
