---
name: bitrix-userfield
metadata:
  type: knowledge
  version: "1.0.0"
description: >-
  Use when adding a custom user field (UF) type for any binding — CRM, smart
  processes, iblock sections, HL-blocks, users — or the contract-to-handoff
  workflow: type class (getDbColumnType, prepareSettings), registration,
  field instance, rendering, JS picker, filters, BizProc output. Key terms -
  OnUserTypeBuildList, USER_TYPE_ID, FIELD_NAME.
---
# Custom User Field (UF) Types: end to end

Kernel APIs here were verified on one 25.750.0 installation; re-verify against your portal's kernel.

Router: start at `rules/workflow.md` for the order; an API question opens the matching rule.

## Related canon (optional)

Optional, never a prerequisite: `bitrix-modules`, `bitrix-project-structure`, `bitrix-components`,
`bitrix-events`, `bitrix-extensions`, `bitrix-orm`, `bitrix-security`, `bitrix-chef`. When available,
the whole wiring follows them (`workflow.md` maps each stage to its canon); otherwise this skill's
own conventions govern.

## Choose a rule file

- `rules/workflow.md` — field contract and identifiers, native-type decision, environment discovery, type class and registration, field instance, rendering, optional integrations, canon per stage.
- `rules/verification-recovery.md` — static and portal-manual checks, data safety, error propagation, safe rerun, handoff record.
- `rules/type-class.md` — anatomy of the type class, portal registration, server-side data providers, where provider code lives.
- `rules/entity-bindings.md` — binding matrix (ENTITY_ID, storage, creation UI), UTS vs HL-block storage, render surfaces and rights, iblock elements (properties, not UF), binding-agnostic type.
- `rules/render-component.md` — render paths (RENDER_COMPONENT vs system.field.*), template inventory, main.view / main.edit contracts.
- `rules/js-extension.md` — when a JS extension is required, layout and build, entity-selector provider, picker wiring in the edit template.
- `rules/crm-filter.md` — CRM grid filter: what the kernel gives, extending for your type, provider composition (replace by UF-ID), legacy GetFilterData (admin lists only).
- `rules/bizproc-output.md` — modifier chain printable/friendly, making a type printable, resolve names by ID.

## Cross-cutting invariants

- `USER_TYPE_ID` (type, portal-wide), `FIELD_NAME` (instance, per entity), `ENTITY_ID`, numeric row ID — never merged.
- Static checks run here; portal-manual checks are never claimed as done in this environment.

## Checklist

- [ ] Opened only the rule file(s) needed for this task.
- [ ] Followed the invariants and the canons of the active mode.