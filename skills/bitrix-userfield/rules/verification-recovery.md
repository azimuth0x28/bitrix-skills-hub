# Verification, Data Safety, and Recovery

The run's proof and its guardrails: which checks run here, which run on the portal, how errors travel,
how partial failure is handled without losing data, and the handoff record. Read this rule before any
mutation and at the end of every run.

## Static and portal-manual checks

Two lists that are never merged. **Static checks** run here, now: `php -l` on new files, autoload
present, the handler present in the registration source, the control named `FIELD_NAME` in the edit
template. Static evidence shows source presence — it does not prove runtime behavior. **Portal-manual
checks** run on the portal by a human or a later session with portal access: module installed and the
type selectable in the field editor's type list (runtime registration through `OnUserTypeBuildList`),
field visible on card and edit form, filter widget serves values, bizproc `printable` prints names.
A portal-manual check is never claimed as performed in a session that cannot run it — it stays pending.

## Data safety, error propagation, and safe rerun

- **Consent before mutation.** Changing an existing field or its stored data requires explicit user
  consent; without it the run stops at the contract stage. Create of a brand-new field needs no consent,
  but the recovery rules below still apply.
- **Original errors, with context.** Every failing operation propagates its real cause — the caught
  `\Throwable`, `$APPLICATION->GetException()`, or the `Result` error — into the next result and the
  handoff. Never replace a real message with a generic one; add context, keep the cause.
- **Partial metadata failure — per storage provider.** `CUserTypeEntity::Add()` fires
  `OnBeforeUserTypeAdd` (a handler returning `PROVIDE_STORAGE => false` takes storage over), inserts
  the `b_user_field` row and the labels, then fires `OnAfterUserTypeAdd`. Default (UTS) provider:
  storage tables, then the `b_uts_<entity>` column DDL, then the row, then labels — a row-insert
  failure leaves an orphan **column** (or a column+row without labels), a DDL failure leaves
  nothing. HL provider: storage is disabled up front, the row and labels land first, and
  `OnAfterUserTypeAdd` creates the HL `UF_*` column and the multiple table — a failure can leave a
  metadata **row with no column** (`entity-bindings.md`). Probe the metadata row plus the
  provider's own column and multiple table; record which artifacts exist. Clean up only the created
  part with consent — dropping a populated column or table, or a row that can own data, is a
  data-bearing deletion, never silent. Never run a generic rollback that could drop populated
  artifacts.
- **Safe idempotent rerun.** The contract is the source of truth: a rerun compares the metadata
  row under `ENTITY_ID` + `FIELD_NAME` with the storage its provider left behind and skips stages
  whose exits already hold. For UTS, mirror the kernel's own probe: column presence in
  `b_uts_<entity>` via `$DB->GetTableFields()` — the existence check `CUserTypeEntity::Add()` runs
  before its `ALTER`. For HL, the kernel never probes: `onAfterUserTypeAdd` `ALTER`s the HL table
  directly, so check the actual HL schema yourself (`$DB->GetTableFields($hlTable)` for the `UF_*`
  column, the `<hl_table>_<field>` table when multiple) and create what is missing. Re-running
  install does not re-register handlers; rerun detection is the contract vs the artifacts, not
  install flags.
- **Snapshot before change.** Before modifying an existing field, record its metadata (`SETTINGS`,
  multiplicity) and a count of stored values; keep the snapshot with the handoff. **Never delete
  stored values to make a problem disappear** — values are real data on real entities.
- **Kernel never edited.** A render or bizproc gap is fixed in the render surface; kernel edits would
  break upgrades and are a release blocker.

## Handoff record

The final evidence block, written at the end of every run and part of the run's proof:

```text
Type id (USER_TYPE_ID): <type>   Field name (FIELD_NAME): <UF_...>
Entity (ENTITY_ID): <entity>     Field row ID (b_user_field.ID): <numeric or "pending">
Branch and decision: <reuse | custom> — <reason>
Stages completed: <exits confirmed>; stopped: <failing check if any>
Static checks run: <result each>
Portal-manual checks pending: <listed, never claimed done>
Integrations selected: <each with its exit>
Snapshot (existing-field changes): <metadata + value count>
Notes: <verify-in-your-kernel / verify-in-your-project markers>
```

The handoff is what the reviewer and the next session consume; a run may finish with pending
portal-manual items but never with a skipped static item it could have run.

## Checklist

- [ ] Static checks run and listed; portal-manual checks pending, never claimed done.
- [ ] Snapshot taken before any existing-field change; stored values never deleted to mask a problem.
- [ ] Cleanup (if any) covered only created artifacts, with consent; no generic rollback that could drop populated columns, tables, or rows.
- [ ] Original error causes propagated with context; no real message replaced by a generic one.
- [ ] Kernel files untouched; the handoff block written with evidence for every stage.