# Bizproc Output: printable and friendly (BizProc-specific)

> **BizProc — CRM only (kernel-confirmed):** this rule is the bizproc-consumer integration point for
> CRM documents. The field itself is built like any UF (the `Field instance` and `Rendering and
> optional integrations` stages of `workflow.md`); nothing here changes the type. It covers how the
> `>printable` / `>friendly` modifiers produce text in CRM business-process templates, and what the
> render surface must do to print names instead of a false empty caption.
>
> Iblock note: `CIBlockDocument` makes iblock ELEMENTS BizProc documents (document type
> `['iblock', 'CIBlockDocument', 'iblock_<id>']`); sections are related data, and no section BP
> document is established by that path. `GetDocumentFields()` covers stock element fields and
> iblock properties (custom property user types included) — not `b_user_field` rows. A custom UF
> type has no native iblock BP `printable` surface in this kernel; verify in your kernel whether a
> newer kernel exposes one before wiring it.

## Modifier chain: printable and friendly

`CBPActivity::getRealParameterValue()` reaches `applyPropertyValueModifiers()` on the BizProc
activity class:

1. The modifier is not a registered document-field class (no `typeClass`), so `format = 'printable'`.
2. `getFieldTypeObject()` returns `null` for a custom `UF:*` type → the legacy branch runs:
   `CCrmDocument::GetFieldValuePrintable()` → `PreparePrintableValue()`.
3. The pseudo-field gets `SETTINGS` only for kernel types (iblock_element, iblock_section, crm_status,
   boolean, crm); `USER_TYPE['FIELDS']` is never passed.
4. `BaseType::renderField()` includes the type's render surface (`RENDER_COMPONENT` or
   `system.field.*`) with that pseudo-field.

**How the field is addressed in BP templates.** Two identifiers play different roles, and the kernel
keeps them separate:

- the document field **name** is the row's `FIELD_NAME` (the document-field map is built from user
  fields by field name), e.g. `{=Document:UF_MY_FIELD>printable}`;
- the field **type** for a custom UF is the `'UF:'`-prefixed type id: the legacy CRM document path
  registers a custom UF type as `'UF:' . USER_TYPE_ID`, and the modern smart-process document item
  returns `'UF:' . $type` the same way.

So `UF:my_smart_field` names the type, `UF_MY_FIELD` names the field — never swap them. A custom type
never gets a `typeClass` in the document map, so the legacy printable chain above is the one its
`printable` runs. Smart-process documents run through the modern document classes (`Dynamic`
extends `Item`): verify the document service in your kernel and confirm whether a kernel-type field
gets its `typeClass` there — custom types do not.

## Making a type printable: resolve names by ID

Use the same canonical pattern the kernel uses in view (`render-component.md`): the view surface
re-queries names by the saved IDs from the data source, and an unresolvable ID prints as the raw ID.

- Put the re-query in `result_modifier.php` (or the component class) — it runs once per render, before
  the template loop, exactly like the kernel `iblock_element` view template's result modifier
  (`CIBlockElement::GetList(['SORT' => 'DESC', 'NAME' => 'ASC'], ['ID' => $arResult['VALUE']], false)`).
- Scope known (e.g. iblock id) → pass `CHECK_PERMISSIONS => 'Y'` to `CIBlockElement::GetList`
  (rights apply only under that flag) or rights-filter the ORM query, since `ElementTable` is a
  plain ORM `DataManager` with no rights:
- Scope unknown (bizproc pseudo-field) → direct ID-only lookup retrieves the candidate name; a
  stored value does **not** by itself grant the **BP execution user** read rights on the referenced
  object. Resolve the acting user from the runtime context (workflow owner/starter — the legacy
  chain passes no user to the surface; verify per your bizproc setup) and check read rights through
  the source's rights API before releasing a name; when the user or the right cannot be established,
  render rights-safe — the raw/escaped ID or the empty caption, never a name. Treat empty value,
  `0`, a missing ID, a deleted record, and an inaccessible record each as "no name"; only a truly
  empty value prints the empty caption.
- **HTML-encode the names the resolver returns** — they are raw DB strings, never pre-encoded by the
  manager (and the classic-path pre-encoding does not apply to your own `result_modifier.php`); the
  raw-ID fallback (unresolvable, deleted, or inaccessible ID) is escaped the same way.
- Multiple values print comma-separated, like the kernel `iblock_element` view template does.

**Do not rely on BP `Options`.** The document-field map collects `Options` (XML_ID => NAME) for a
type with a callable `GetList`, but the legacy printable chain drops them — the renderer never sees
the map. The ID re-query is the only trustworthy name source (`type-class.md` marks the `GetList`
feed itself as **verify in your kernel**).

## friendly vs printable

- `printable` — human-readable text (names), built through the render-surface path above.
- `friendly` — for a custom type without `typeClass` it returns the **raw** value, unformatted. It is
  not the names printer; use `printable` in BP templates when names are wanted.

**Never edit the kernel chain** — the CRM document type and the BizProc activity chain — to
special-case a custom type; the fix belongs in the render surface, which keeps kernel upgrades safe.

## Checklist

- [ ] Document field name (`FIELD_NAME`) and type (`UF:<USER_TYPE_ID>`) kept separate in BP templates.
- [ ] Read rights for the BP execution user checked before a name is released; else rights-safe fallback.
- [ ] View surface re-queries names by ID (kernel pattern); raw ID printed when unresolved incl. 0/deleted/inaccessible.
- [ ] Re-query lives in `result_modifier.php` / the component class, not in template loops.
- [ ] Empty caption shown only for truly empty values.
- [ ] Names HTML-encoded at output.
- [ ] `friendly` used only where raw values are acceptable; `printable` for names.
- [ ] No reliance on BP `Options` for printable names.
- [ ] No edits to the kernel `bizproc`/`crm` chain.