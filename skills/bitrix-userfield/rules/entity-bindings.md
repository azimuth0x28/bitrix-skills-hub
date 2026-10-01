# Entity Bindings: the UF Instance and Its Surfaces

Layer: the field INSTANCE — where a UF of the type is created, how it is stored, and which
surfaces render it — for every binding. The type class is binding-agnostic: one class serves
all bindings; what differs is the `b_user_field` row (`ENTITY_ID`) and the surfaces that read
the stored values. Open this rule at the `Field instance`, `Native-type decision…`, and
`Rendering and optional integrations` stages of `workflow.md`.

## Binding matrix: ENTITY_ID, storage, and creation UI

The binding set (kernel-confirmed): CRM classic entities, smart processes, iblock sections,
HL-blocks, users. `ENTITY_ID` is uppercase `[0-9A-Z_]`, at most 50 chars (kernel-validated),
unique per binding; `FIELD_NAME` is unique within one `ENTITY_ID` (`workflow.md`).

- `CRM_DEAL`, `CRM_CONTACT`, `CRM_COMPANY`, `CRM_LEAD`, `CRM_QUOTE`, … — classic CRM (+ `_SPD` suspended twins)
- `CRM_<type id>` — smart processes; the id is the **type's DB id**, not its `entityTypeId`
- `IBLOCK_<id>_SECTION` — iblock sections; element characteristics are properties, not UF (below)
- `HLBLOCK_<id>` — HL-blocks
- `USER` — users
- `TASKS_TASK`, `CALENDAR_EVENT`, … — other module bindings (same mechanism)

| Binding | Storage |
|---|---|
| CRM classic / smart processes | column on `b_uts_<entity>`; multiple values → `b_utm_*` rows |
| Iblock sections | column on `b_uts_iblock_<id>_section` |
| HL-blocks | `UF_*` column on the HL table itself — NOT a UTS table |
| Users | column on `b_uts_user` |

| Binding | Where the field is created in the UI |
|---|---|
| CRM classic / smart processes | CRM field editor (`crm.config.fields.*`; smart-process type settings) |
| Iblock sections | section editor "User fields" tab, shown when the management right holds |
| HL-blocks | HL block editor → `userfield_admin.php?find=HLBLOCK_<id>&find_type=ENTITY_ID` |
| Users | `userfield_admin.php?ENTITY_ID=USER` — Settings → Users → User fields |

## Storage providers: UTS vs HL-block owned storage

Two storage providers, chosen per call. **UTS (default).** `CUserTypeEntity::Add()` fires
`OnBeforeUserTypeAdd` with `PROVIDE_STORAGE` still true, creates `b_uts_<entity>` / `b_utm_<entity>`,
adds the `FIELD_NAME` column (SQL type from `getDbColumnType()`), inserts the `b_user_field` row,
writes the labels, then fires `OnAfterUserTypeAdd`. A row-insert failure leaves an orphan column; a
DDL failure leaves nothing.

**HL below owns storage.** The highloadblock handler returns `PROVIDE_STORAGE => false` from
`OnBeforeUserTypeAdd` for `HLBLOCK_*`, so no UTS column is created; the row and labels land first,
and the `OnAfterUserTypeAdd` handler then `ALTER`s the HL table to add the `UF_*` column and builds
the multiple-value table `<hl_table>_<field_name>`. The cut is inverted: HL can hold a metadata row
with no backing column yet.

Recovery and rerun probes (`verification-recovery.md`) branch on the provider: the metadata row plus
the provider's own column (`b_uts_<entity>` versus the HL table) plus the multiple table. Never
drop a populated column or table without consent — a column that holds values is data-bearing.

HL multiple table naming and the `HLBLOCK_<id>` prefix are kernel constants; `b_uts_hlblock_*` is
not used. Verify in your kernel before assuming any provider binds to an `ENTITY_ID` not listed
above — arbitrary metadata `ENTITY_ID`s do not establish support.

## Render surfaces and rights per binding

Every binding renders through the same kernel surfaces: `system.field.view` / `.edit` with a
per-`USER_TYPE_ID` template on the classic path, or the `RENDER_COMPONENT` mode templates on the
modern path (`render-component.md`). The binding only decides which pages host them:

| Binding | Hosting pages |
|---|---|
| CRM classic / smart processes | entity card + editor; CRM grid filter |
| Iblock sections | section admin + public pages |
| HL-blocks | HL rows admin + public lists |
| Users | user edit + profile pages |

Three distinct rights exist; never merge them:

| Right | Meaning | Source |
|---|---|---|
| Metadata definition edit | create/change the field definition | `CUserTypeManager::GetRights(ENTITY_ID) >= 'W'` |
| Owner record value edit | change values on a concrete record | the record's own edit permission |
| Referenced object read | resolve saved IDs to names | the referenced object's read permission |

Names are resolved only under the third right (`render-component.md`): e.g. element reads pass
`CHECK_PERMISSIONS => 'Y'`, user names come from a rights-filtered user query. `>= 'W'` on the
metadata grants definition control, nothing about reading records or their values.

## Iblock elements: properties, not UF

Iblock element metadata is iblock properties — a different API. `OnUserTypeBuildList` registers
field types; an element's characteristics are properties on `CIBlockProperty` (`PROPERTY_TYPE` plus
optional property user types). A need for custom element characteristics is property work: follow
`bitrix-iblocks` (custom property types), it does not go through the UF type class.

A custom UF type targeting elements has no confirmed native consumer in this kernel: the element
admin editor renders properties, and no kernel read/write/render path for element UF rows was
found. An `ENTITY_ID = IBLOCK_<id>_ELEMENT` metadata row does not establish support by itself —
create it only when a real consumer is demonstrated (a component or API that reads, writes, or
renders the value end to end), and verify in your kernel that the consumer exists before promising
coverage. The kernel-proven iblock UF binding is the section one (`IBLOCK_<id>_SECTION`, the
"User fields" tab of the section editor).

## The type is binding-agnostic

The custom type class and its registration (`type-class.md`) know nothing about the binding: the
same `USER_TYPE_ID` serves CRM items, iblock sections, HL rows, and users. What differs per binding
is the instance row — which `ENTITY_ID` the field is created under — and the surfaces that read the
stored values. One custom type can back fields on several bindings at once.

Other module-level bindings — tasks (`TASKS_TASK`), calendar events (`CALENDAR_EVENT`), workgroups
and similar — work through the same mechanism: same UTS storage, same field editor, surfaces hosted
by their own pages. Only the `ENTITY_ID` and the hosting page differ; no dedicated rule. Binding
API and rights details follow the sibling canon when available: `bitrix-iblocks`, `bitrix-highloadblock`.

## Checklist

- [ ] `ENTITY_ID` in the kernel-confirmed set or verified in-kernel; smart-process id = type DB id, not its `entityTypeId`.
- [ ] Storage per provider: UTS columns on `b_uts_<entity>` / HL `UF_*` on the HL table — `b_uts_hlblock_*` unused.
- [ ] Iblock element work routed to `bitrix-iblocks` properties, not the UF type class; element-UF only with a demonstrated consumer.
- [ ] The three rights (metadata / record value / referenced object) kept separate; names resolved only under the read right.