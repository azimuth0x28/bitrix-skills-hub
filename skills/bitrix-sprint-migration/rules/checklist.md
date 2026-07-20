# Safety and finish checklist

## Safety rules

- Write migrations under configured `migration_dir` only — never patch
  `sprint.migration` module source for product needs.
- Treat `up`/`down` as **production-capable**: they may alter schema and data.
- Do not embed secrets, tokens, or personal dumps in migration files or exchange
  dirs.
- Prefer identifying records by stable business keys (CODE, XML_ID), not by IDs
  copied from a local DB.
- Avoid `delete` / mass `down` on shared environments unless explicitly requested.
- `mark --as=installed` skips code execution — use only to align status after a
  known manual change, never as a substitute for a failed `up`.
- Applying migrations on production requires explicit human approval; do not
  treat a successful local `up` as permission to change production.

## Anti-patterns

| Anti-pattern | Do instead |
| --- | --- |
| Hand-editing installed migration that already ran on other copies | Add a **new** migration |
| Hard-coded element/section IDs from local DB | Resolve by CODE/XML_ID via helpers |
| Non-idempotent `add` that fails on second env | `save*` / `*IfNotExists` |
| Empty `description` | Write a clear one-line purpose |
| Giant irreversible data wipe in `down` “for symmetry” | Document one-way `down()` or omit |
| Committing builder output without review | Diff-check generated arrays/files |
| Using migrations for runtime business logic | Put logic in module services; migration only bootstraps/schema |

## Author checklist

- [ ] Created via `add` or a builder (valid class name + timestamp).
- [ ] `namespace Sprint\Migration;` and class name = file name.
- [ ] `$description` filled.
- [ ] `up()` is idempotent or safe to run once per environment.
- [ ] `down()` implemented or explicitly documented as one-way.
- [ ] Helpers used where available; modules `includeModule`'d for custom code.
- [ ] No secrets; no `/bitrix/` edits.
- [ ] Exchange files (if any) committed alongside the Version when required.

## Verify checklist

- [ ] `ls --new` shows the migration before apply (or expected status).
- [ ] `up` (or `up VersionName`) succeeds on a local/dev copy.
- [ ] Spot-check admin / ORM / page that depends on the change.
- [ ] If `down` is supported, `redo VersionName` once on a disposable copy.
- [ ] Status in `ls` is `installed` after success.

## Review focus

- Destructive deletes without filters or backups.
- Reliance on environment-specific IDs.
- Missing module checks before using custom classes.
- Silent failures (`Result` ignored, no `outError` / `return false`).
- Schema drift: `addIfNotExists` where an update (`save*`) was required.
