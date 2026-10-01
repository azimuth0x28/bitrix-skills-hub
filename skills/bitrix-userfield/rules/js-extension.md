# JS Extension and Entity-Selector Provider

Layer: the client-side extension that renders a picker and the server-side provider that feeds the dialog. Reusable
client code for a field (the `Rendering and optional integrations` stage of `workflow.md`).

## When a JS extension is required

Reach for a JS extension when the client logic is **reusable or non-trivial**, not only when a dialog is involved:

- the same code serves several places — e.g. one picker used in `main.edit`, `main.view` (read-only rendering of the
	same value), `main.edit_form` — and behavior may depend on the mode while the code stays one bundle;
- the code is complex enough to span several files (components, providers, types);
- DRY: the same client logic would otherwise be copy-pasted across templates.

A concrete case that qualifies: a picker over `ui.entity-selector` (TagSelector + Dialog) for a large or server-filtered
set. Simple enum displays (select/checkbox/radio) render server-side from `USER_TYPE['FIELDS']` and need no extension.
The task decides which shape the edit template uses; the extension is how the reusable part ships.

## Extension layout and build

The extension ships with the developer's module and is copied to `/local/js/` on install:

```
install/files/js/<module>.<picker>/
├── bundle.config.ts      # @bitrix/chef build: src/index.ts -> dist/index.bundle.js
├── config.php            # extension registration: js, rel, skip_core
├── src/
│   ├── index.ts          # exports the picker class
│   ├── components/picker.ts
│   └── kernel.d.ts       # ambient types for main.core, ui.entity-selector imports
└── dist/                 # generated build output
```

- Bundle namespace: `Vendor.Module.UI` (`bundle.config.ts`); the global entry is `Vendor.Module.UI.MySmartFieldPicker`.
- `config.php` declares `rel => ['main.core.events', 'ui.entity-selector', 'main.core']`.
- Build with **@bitrix/chef** when available (`bitrix-chef`). **Never hand-edit `dist/`** — change `src/` and rebuild.

## Entity-selector provider registration

When the picker uses a dialog, its list is served by a provider declared in the module `.settings.php`, section
`ui.entity-selector`:

```php
<?php
// local/modules/<vendor>.<module>/.settings.php — the ui.entity-selector section

$moduleId = 'vendor.module';

return [
    'ui.entity-selector' => [
        'value' => [
            'entities' => [
                [
                    'entityId' => MyEntityProvider::ENTITY_ID,   // e.g. 'my-smart-field-value'
                    'provider' => [
                        'moduleId'  => $moduleId,
                        'className' => MyEntityProvider::class,
                    ],
                ],
            ],
            'extensions' => [$moduleId . '.<picker>'],
        ],
        'readonly' => true,
    ],
];
```

- The provider class lives in `lib/Integration/UI/EntitySelector/`, implements list building with optional filters and
	item formatting (title/avatar/subtitle), and caps the result set. **Rights-filter the returned items** for the
	acting user — the entity-selector serves exactly what the user may pick, and an option a user cannot access must
	not appear (kernel providers do this per source; verify in your kernel).
- **Never register the same `entityId` twice** — resolution is first-wins and a duplicate silently ignores one provider.
- Kernel providers (employees, sections, iblock elements, ...) already exist; do not re-register them under your own
	entityId.

## Wiring the picker in the edit template

1. `result_modifier.php` of the edit template calls `Extension::load('...<extension-id>')` only for the dialog branch.
2. `.default.php` renders an empty container and JSON params: `fieldName`, `value`, `isMultiple`, plus the provider
	 options (ids, filter codes, flags).
3. Inside `BX.ready` the template instantiates the picker with the JSON string and calls `renderTo(container)`; the
	 class renders hidden inputs and the TagSelector.
4. On selection the extension rewrites the hidden inputs (control contract: `FIELD_NAME[]` when multiple) and emits an
	 instance `change` event with `{ values }`; the template fires `BX.fireEvent` on a hidden input so form validation and
	 change tracking run.

**The picker is a convenience, never the validator.** The saved IDs are validated server-side in
`checkFields(array $userField, $value, $userId)` (`type-class.md`) independently of what the dialog
returned — a crafted request can post any ID, so existence, rights, and shape are checked there, per
source (`render-component.md`, `bizproc-output.md`).

**Never enable console tracing in production templates** — the flag ships disabled (`enabled: false`), and the
production bundle must not log selections.

## Checklist

- [ ] Extension justified: reusable across places, multi-file complexity, or DRY — not merely "a dialog".
- [ ] Extension = `src/` + `bundle.config.ts` + `config.php`; `dist/` rebuilt with chef, never hand-edited.
- [ ] Provider declared in the module `.settings.php` `ui.entity-selector`; `entityId` unique; items rights-filtered.
- [ ] `Extension::load` happens in `result_modifier.php` only for the branch that needs it.
- [ ] Picker writes `FIELD_NAME`/`FIELD_NAME[]` hidden inputs per the control contract; `change` fires `BX.fireEvent`.
- [ ] Stored IDs validated server-side in `checkFields`; picker output never trusted as validation.
- [ ] No console tracing enabled.
