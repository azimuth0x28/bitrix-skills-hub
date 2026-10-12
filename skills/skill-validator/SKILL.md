---
name: skill-validator
description: Use when a skill is ready for a PR, when asked to validate, or after mass edits. Covers mechanical validation of a skill folder — format check via vendored quick_validate.py, security scan via prism-scanner, grade A–F gates, .prismignore, batch validation, vendor neutrality. Key terms — quick_validate.py, vendored, prism-scanner, --fail-on, .prismignore, check-vendors.sh, metadata.vendor.
metadata:
  type: workflow
  version: "1.2.0"
---

# Skill Validation (Format + Security + Vendors)

Mechanical gate for a skill folder before a PR. Editorial quality (blind test, Q1–Q11 rubric) is owned by `bitrix-skill-eval`; authoring rules by `bitrix-knowledge-skill-creator`; the PR gate policy lives in `AGENTS.md` ("Automated skill checks") — reference them, never duplicate.

| Check | Tool | Command |
| --- | --- | --- |
| Format (agent-skills spec) | `quick_validate.py` — vendored at `scripts/quick_validate.py`, source [anthropics/skills › skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) (Apache-2.0) | `uv run --with pyyaml skills/skill-validator/scripts/quick_validate.py skills/<name>/` |
| Security (static analysis, grade A–F) | [prism-scanner](https://github.com/aidongise-cell/prism-scanner) | `uvx --from prism-scanner prism scan skills/<name>/ --fail-on high` |
| Version bump (changed skills) | `.github/scripts/check-versions.py` | `python3 .github/scripts/check-versions.py <base-sha>` |
| Line budgets (ratchet) | `.github/scripts/check-budgets.sh` + `budget-baseline.txt` | `bash .github/scripts/check-budgets.sh` |
| Vendor neutrality (allowlist) | `scripts/check-vendors.sh` — default-deny on concrete vendors | `bash skills/skill-validator/scripts/check-vendors.sh skills/<name>/` |

All these tools are local, read-only, and never execute the scanned code.

## Validate one skill

1. Format check (exit code 0 = pass):

```bash
uv run --with pyyaml skills/skill-validator/scripts/quick_validate.py skills/<name>/
```

The script is vendored inside this skill (`scripts/quick_validate.py`, Apache-2.0, pinned to an upstream commit) — it travels with the folder and needs no download. When pyyaml is already installed, plain `python3 skills/skill-validator/scripts/quick_validate.py skills/<name>/` works too.

`quick_validate.py` enforces: `SKILL.md` present, valid YAML frontmatter, only allowed keys (`name`, `description`, `license`, `allowed-tools`, `metadata`, `compatibility`), `name` kebab-case ≤64 chars, `description` ≤1024 chars without `<`/`>`, `compatibility` ≤500 chars. Nested keys under `metadata` are not checked — the collection uses `metadata: {type: workflow|knowledge}` to declare the skill type; values outside that pair pass validation too.

2. Security scan (exit code 0 = pass):

```bash
uvx --from prism-scanner prism scan skills/<name>/ --fail-on high
```

Drop `--fail-on high` for the full report with the grade; add `--format json` for machine-readable findings.

3. Vendor neutrality (exit code 0 = pass):

```bash
bash skills/skill-validator/scripts/check-vendors.sh skills/<name>/
```

A token in a vendor slot must be the neutral placeholder `acme`/`vendor`, or the vendor the skill declares as `metadata.vendor` in its `SKILL.md` frontmatter. The declaration covers the whole skill folder (`SKILL.md`, `rules/*`, `references/*`).

4. Budget + version gates (exit code 0 = pass):

```bash
bash .github/scripts/check-budgets.sh
python3 .github/scripts/check-versions.py <base-sha>
```

Line budgets are ratcheted via `.github/scripts/budget-baseline.txt`; the version gate compares `metadata.version` between base and HEAD per AGENTS.md "Skill versioning".

5. Report as a table: skill, check, grade, finding, action. State only observed output.

## Interpret grades

| Grade | Meaning | Action |
| --- | --- | --- |
| A | no findings, or informational only | pass |
| B | LOW findings only | pass |
| C | 1–4 MEDIUM | attach a written justification to the PR |
| D | 1–2 HIGH, or 5+ MEDIUM | blocker — fix before the PR |
| F | any CRITICAL, or 3+ HIGH | blocker — fix before the PR |

The gate is the exit code; the grade is the report. **Never ship a skill on a non-zero validator exit code.**

## Read the errors

Format-check messages map to fixes at the source — never weaken or bypass a check:

| Message | Fix |
| --- | --- |
| `SKILL.md not found` | the folder has no `SKILL.md` — wrong path or missing file |
| `No YAML frontmatter found` / `Invalid frontmatter format` | file must open with a `---` fenced block |
| `Unexpected key(s) in SKILL.md frontmatter` | remove keys outside the allowed set above |
| `Name ... should be kebab-case` / `too long` | lowercase-hyphen name ≤64 chars |
| `Description cannot contain angle brackets (< or >)` | rewrite `<...>` placeholders in words |
| `Description is too long` | trim to ≤1024 chars |

Security findings carry a rule ID (`S*` behavior, `M*`/`P*` metadata and patterns, `R*` residue) and `file:line` — read them before reacting.

## Vendor slots

The gate checks three vendor slots; the token in each must be allowed (`acme`/`vendor`, or the skill's declared `metadata.vendor`):

| Slot | Shape |
| --- | --- |
| Module path prefix | `local/modules/<vendor>.` and `bitrix/modules/<vendor>.` |
| AJAX action prefix | `runAction('<vendor>:` and `action=<vendor>:` |
| Module load id | `includeModule('<vendor>.<module>')` |

Vendor findings print `file:line  vendor '<token>'  (<slot>)` — replace the token with `acme`/`vendor`, or declare the assigned vendor once as `metadata.vendor: "<vendor>"` in `SKILL.md`. **Never widen the allowlist to silence a finding.** Namespace roots (`Bitrix\`, `Main\`) are platform namespaces, not slots; a brand used only as a namespace root escapes the gate (known coverage limit).

## Known false positives

- P6 "Prompt injection detected in skill description" fires on angle-bracket path templates like `` `/bitrix/js/<module>/<extension>/` `` — observed on `bitrix-extensions` (`SKILL.md:12`, grade F). Suppression path: `.prismignore` in the skill folder with the rule ID and a written justification. **Never suppress a finding by ignoring the exit code.**
- After adding `.prismignore`, re-run the scan and confirm remaining findings are empty or justified.

## Batch validation

After mass edits, run every check over each folder:

```bash
for d in skills/*/; do
  uv run --with pyyaml skills/skill-validator/scripts/quick_validate.py "$d" >/dev/null 2>&1 || echo "FORMAT: $d"
  uvx --from prism-scanner prism scan "$d" --fail-on high >/dev/null 2>&1 || echo "SECURITY: $d"
  bash skills/skill-validator/scripts/check-vendors.sh "$d" >/dev/null 2>&1 || echo "VENDOR: $d"
  bash .github/scripts/check-budgets.sh >/dev/null 2>&1 || echo "BUDGETS: $d"
done
```

Every folder must appear in either the pass set or the report — a folder checked by zero checks is an incomplete run.

## Negative knowledge

- The package executable is `prism`; `uvx prism-scanner ...` fails with "executable not provided" — use `uvx --from prism-scanner prism`.
- `quick_validate.py` never compares `name` with the folder name and never checks line budgets or cross-links — those stay in the `AGENTS.md` PR checklist.
- A top-level `version` frontmatter key fails `quick_validate.py` (allowed-keys list) — the version lives inside `metadata`, never at the top level.
- The version gate (`check-versions.py`) only checks folders changed between base and HEAD; untouched skills are never compared.
- A legacy base without `metadata.version` passes the gate once HEAD carries a valid version (adoption).
- A fixed violation still listed in `budget-baseline.txt` fails as "stale baseline entry" — fixes must remove their baseline line.
- The version gate runs on `pull_request` events only; pushes to `main` skip it (`validate.yml` job condition).
- prism-scanner performs no format validation — a format-broken skill can grade A.
- `--fail-on` accepts `critical`, `high`, `medium` — there is no `low` threshold.
- The vendored copy is pinned to upstream commit `34040c9c` (Apache-2.0, `scripts/LICENSE.txt`); upstream evolves independently — re-sync deliberately with a diff, never assume parity.
- Sibling scripts in the upstream `scripts/` (`run_eval.py`, `run_loop.py`, `improve_description.py`, `generate_report.py`, `aggregate_benchmark.py`) shell out to `claude -p` — evaluation tooling owned by `bitrix-skill-eval`, out of scope here.
- `package_skill.py` upstream packages `.skill` archives and imports `scripts.quick_validate` package-relative — it breaks when copied standalone and stays out of this skill.
- `check-vendors.sh` is an allowlist, not a denylist: `acme`/`vendor` pass globally and everything else in a slot fails — a new concrete vendor is caught with no code change.
- The declared vendor is read once from `SKILL.md` and applies to the whole folder; `rules/*.md` and `references/*` inherit it, and a folder without `SKILL.md` declares nothing.
- `check-vendors.sh` skips every `scripts/` directory, so it never scans itself or the vendored `quick_validate.py`.
- A module segment followed by a file extension (`bitrix/modules/error.log`) is a file path, not a vendor — `error` is not flagged.
- Namespace roots (`Bitrix\`, `Main\`, `Sale\`...) are intentionally not scanned — they are platform namespaces; a brand used only there escapes the gate.
- Canonical non-allowed vendor for negative tests and docs is `Contoso`; never a real brand. A literal slot-shaped example containing a non-allowed token inside a scanned skill self-flags — write `<vendor>` placeholders in examples.

## Checklist

- [ ] Format command exits 0 on the final skill folder.
- [ ] `prism scan --fail-on high` exits 0 on the final skill folder.
- [ ] `check-vendors.sh` exits 0 on the final skill folder: every slot token is `acme`/`vendor` or the declared `metadata.vendor`.
- [ ] Any `metadata.vendor` names a real product the user assigned, declared once in `SKILL.md`.
- [ ] Grade C findings each carry a written justification in the PR.
- [ ] Every `.prismignore` entry carries the rule ID and a justification.
- [ ] No finding was resolved by ignoring or weakening a check.
- [ ] After batch runs: folder count checked equals folder count in `skills/`.
- [ ] `name` = folder name confirmed by reading the frontmatter — the script does not check it.
- [ ] Report table cites observed output only; no invented rule IDs or grades.

## Related skills

- `bitrix-knowledge-skill-creator` — authoring spec a validated skill must satisfy.
- `bitrix-skill-eval` — editorial quality gate beyond mechanical checks.
