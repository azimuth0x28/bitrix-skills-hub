# Render Component and Template Layout

Layer: how the kernel renders a custom type in every context (the `Rendering and optional
integrations` stage of `workflow.md`), what the render surface must output, and how it must escape
and resolve values. The type class and JS live in their own rule files.

## Render paths: RENDER_COMPONENT vs system.field.*

Two kernel paths render a field; a custom type should pick one and stay consistent.

**Modern path — `USE_FIELD_COMPONENT` + `RENDER_COMPONENT`.** `BaseType::getUserTypeDescription()`
sets `USE_FIELD_COMPONENT => true`, and the renderer calls `BaseType::getHtml()`, which includes the
component; `BaseType::getComponentName()` returns `RENDER_COMPONENT` as-is when it contains `:`,
else prefixes `bitrix:`. The component receives the field plus an `additionalParameters['mode']`;
its templates switch on the mode. The kernel's own types ship this way — `StringType::RENDER_COMPONENT
= 'bitrix:main.field.string'`.

**Classic path — `system.field.*` templates.** The manager falls back to `bitrix:system.field.view` /
`bitrix:system.field.edit` with a template named by `USER_TYPE_ID` (`template.php` + optional
`result_modifier.php`). A portal override, when present, lives in
`local/templates/<site>/components/bitrix/system.field.view/<USER_TYPE_ID>/`. This path is the
fallback when `USE_FIELD_COMPONENT` is off.

**Escaping differs by path — do not assume the kernel escapes for you.** On the classic path, the
`system.field.view` component pre-encodes string values: it switches on `USER_TYPE['BASE_TYPE']` —
`double` rounds, `int` casts, and the default branch runs `htmlspecialcharsbx($res)` **only when
`USE_FIELD_COMPONENT` is empty**. On the modern path the kernel does **not** pre-encode — the render
surface escapes, as the stock templates do (`main.field.string`'s `main.view` result modifier calls
`HtmlFilter::encode($value)`). So: classic path may rely on the component's encoding; modern path
must encode every printed value. Escape per context — text content with `htmlspecialcharsbx`/
`HtmlFilter::encode`, attribute values at the attribute site, and never trust stored values as safe.

## Template inventory and their roles

A `RENDER_COMPONENT`-based component serves every context from one template set — the kernel
`main.field.*` family ships exactly this set for stock types:

| Template | Mode | Context |
|---|---|---|
| `main.view` | view | read-only: card, lists, bizproc print |
| `main.edit` | edit | entity edit form UI |
| `main.edit_form` | edit | entity editor (slider) variant |
| `main.admin_list_edit_html` / `main.admin_list_view_html` | admin-list | admin grid cells |
| `main.admin_settings` | admin-settings | field settings form |
| `main.filter_html` | filter-html | admin filter row |
| `main.public_text` | public-text | text exports |

A missing context template falls back to `.default`; the kernel selects the template by mode, not by
the type.

## main.view: resolve names by ID

**Never print the empty caption unless the value is truly empty.** The renderer does not guarantee
`USER_TYPE['FIELDS']` on the view surface — a saved value can miss the enumeration (inactive/hidden
items), and some render contexts (bizproc pseudo-field) pass a bare value with **no** name map.

**How the kernel solves it (canonical):** the view surface itself re-queries names by the saved IDs,
from the same data source the type reads. The `system.field.view` template for `iblock_element` does
exactly this in its `result_modifier`:
`CIBlockElement::GetList(['SORT' => 'DESC', 'NAME' => 'ASC'], ['ID' => $arResult['VALUE']], false)`
re-queries names by the saved IDs. Mirror the pattern for your type:

- put the ID→NAME re-query into the view surface (`result_modifier.php` or the component class),
  using the same data-source API the kernel uses;
- an unresolvable ID prints as the raw ID — the truth;
- handle the value shapes: empty value, the integer `0` (a real ID, not "empty"), a missing ID, a
  deleted record, and an inaccessible record — each prints as the raw ID except a truly empty value;
- access: `CIBlockElement::GetList` applies rights only under `CHECK_PERMISSIONS => 'Y'`, and
  `ElementTable` — an ORM `DataManager` — has no rights wiring at all. Known scope → pass
  `CHECK_PERMISSIONS => 'Y'` or rights-filter the ORM query for the acting user; BizProc pseudo-field
  → ID-only lookup retrieves the candidate name, and releasing it is gated on the BP execution user's
  read rights — rights-safe fallback per the policy in `bizproc-output.md`; the raw-ID fallback is
  escaped like every name;
- **HTML-encode the names the resolver returns** — they are raw DB strings, never pre-encoded by the
  manager; the empty caption renders only when no value exists.

> **BizProc note:** bizproc `printable` hands the surface a pseudo-field with no `FIELDS` and no
> `SETTINGS` (`bizproc-output.md`) — the re-query by ID above is mandatory there.

## main.edit: the form control contract

The edit surface's invariant: **the field must leave on the form a control — hidden or explicit, one
or several — named after the field (`FIELD_NAME`), whose value is serialized when the form submits to
the backend.** Multi-valued fields serialize as `FIELD_NAME[]`. Validate on the server, never only in
JS: `checkFields(array $userField, $value, $userId)` runs per value on save (`type-class.md`),
so the edit surface must round-trip exactly what the backend validation expects. Everything else is a
concrete shape chosen by the task:

- enum display — `<select>` / checkbox / radio built from `USER_TYPE['FIELDS']`; re-fetch the
  enumeration when the options depend on another field's value in the current request;
- dialog — an empty container plus JSON params; a JS extension renders the `ui.entity-selector`
  picker and writes the hidden inputs (`js-extension.md`);
- any other markup the task requires — as long as the control-name contract above holds, the value
  round-trips.

## Checklist

- [ ] Render path chosen: `RENDER_COMPONENT` component + mode templates, or `system.field.*` per-type template.
- [ ] Templates for the contexts this field appears in exist (at least `main.view` + `main.edit`).
- [ ] Encoding per path: classic path may rely on the component pre-encoding; modern path escapes values.
- [ ] `main.view` re-queries names by ID (kernel pattern); empty caption only for truly empty values; others print raw.
- [ ] Lookups check the acting user's read rights; names HTML-encoded; rights-safe fallback (no name) when unverifiable.
- [ ] `main.edit` fulfills the control contract: `FIELD_NAME` (± `[]`), value serialized on submit.
- [ ] No debug output, no enabled console tracing in production templates.