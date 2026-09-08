---
name: skill-validator
description: Use when a skill is ready for a PR, when asked to validate, or after mass edits. Covers mechanical validation of a skill folder — format check via quick_validate.py, security scan via prism-scanner, exit-code and grade A–F gates, .prismignore, batch validation. Key terms — quick_validate.py, prism-scanner, --fail-on, grade A–F, .prismignore.
metadata:
  type: workflow
---

# Skill Validation (Format + Security)

Mechanical gate for a skill folder before a PR. Editorial quality (blind test, Q1–Q10 rubric) is owned by `bitrix-skill-eval`; authoring rules by `bitrix-knowledge-skill-creator`; the PR gate policy lives in `AGENTS.md` ("Automated skill checks") — reference them, never duplicate.

| Check | Tool | Command |
| --- | --- | --- |
| Format (agent-skills spec) | `quick_validate.py` — [anthropics/skills › skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) | `uv run --with pyyaml <raw-url> skills/<name>/` |
| Security (static analysis, grade A–F) | [prism-scanner](https://github.com/aidongise-cell/prism-scanner) | `uvx --from prism-scanner prism scan skills/<name>/ --fail-on high` |

Both tools are local, read-only, and never execute the scanned code.

## Validate one skill

1. Format check (exit code 0 = pass):

```bash
uv run --with pyyaml https://raw.githubusercontent.com/anthropics/skills/main/skills/skill-creator/scripts/quick_validate.py skills/<name>/
```

`quick_validate.py` enforces: `SKILL.md` present, valid YAML frontmatter, only allowed keys (`name`, `description`, `license`, `allowed-tools`, `metadata`, `compatibility`), `name` kebab-case ≤64 chars, `description` ≤1024 chars without `<`/`>`, `compatibility` ≤500 chars. Nested keys under `metadata` are not checked — the collection uses `metadata: {type: workflow|knowledge}` to declare the skill type; values outside that pair pass validation too.

2. Security scan (exit code 0 = pass):

```bash
uvx --from prism-scanner prism scan skills/<name>/ --fail-on high
```

Drop `--fail-on high` for the full report with the grade; add `--format json` for machine-readable findings.

3. Report as a table: skill, check, grade, finding, action. State only observed output.

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

## Known false positives

- P6 "Prompt injection detected in skill description" fires on angle-bracket path templates like `` `/bitrix/js/<module>/<extension>/` `` — observed on `bitrix-extensions` (`SKILL.md:12`, grade F). Suppression path: `.prismignore` in the skill folder with the rule ID and a written justification. **Never suppress a finding by ignoring the exit code.**
- After adding `.prismignore`, re-run the scan and confirm remaining findings are empty or justified.

## Batch validation

After mass edits, run both checks over every folder:

```bash
for d in skills/*/; do
  uv run --with pyyaml https://raw.githubusercontent.com/anthropics/skills/main/skills/skill-creator/scripts/quick_validate.py "$d" >/dev/null 2>&1 || echo "FORMAT: $d"
  uvx --from prism-scanner prism scan "$d" --fail-on high >/dev/null 2>&1 || echo "SECURITY: $d"
done
```

Every folder must appear in either the pass set or the report — a folder checked by zero checks is an incomplete run.

## Negative knowledge

- The package executable is `prism`; `uvx prism-scanner ...` fails with "executable not provided" — use `uvx --from prism-scanner prism`.
- `quick_validate.py` never compares `name` with the folder name and never checks line budgets or cross-links — those stay in the `AGENTS.md` PR checklist.
- prism-scanner performs no format validation — a format-broken skill can grade A.
- `--fail-on` accepts `critical`, `high`, `medium` — there is no `low` threshold.

## Checklist

- [ ] Format command exits 0 on the final skill folder.
- [ ] `prism scan --fail-on high` exits 0 on the final skill folder.
- [ ] Grade C findings each carry a written justification in the PR.
- [ ] Every `.prismignore` entry carries the rule ID and a justification.
- [ ] No finding was resolved by ignoring or weakening a check.
- [ ] After batch runs: folder count checked equals folder count in `skills/`.
- [ ] `name` = folder name confirmed by reading the frontmatter — the script does not check it.
- [ ] Report table cites observed output only; no invented rule IDs or grades.

## Related skills

- `bitrix-knowledge-skill-creator` — authoring spec a validated skill must satisfy.
- `bitrix-skill-eval` — editorial quality gate beyond mechanical checks.
