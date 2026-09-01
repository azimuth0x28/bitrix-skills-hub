# AGENTS.md

Guide for AI agents contributing to **bitrix-skills-hub** — a hub of 43 AI skills for **1C-Bitrix / Bitrix Framework** (D7).

## Project overview

- Plain markdown repository: 39 domain skills + 4 meta-skills under `skills/`. One skill = one folder.
- A skill teaches an agent one Bitrix domain: `SKILL.md` (router, ≤60 lines) + optional `rules/*.md` (45–135 lines each, progressive disclosure).
- No build, no test suite. Quality is enforced by mechanical checks (`skills/skill-validator/`), the review checklist, and the evaluation protocol in `skills/bitrix-skill-eval/`.
- User-facing docs: `README.md` (English, primary) and `README.ru.md` (Russian). The catalog of all 43 skills lives in both.

## Repository structure

```
skills/<name>/SKILL.md        # router: what the skill covers, which rules/*.md to open
skills/<name>/rules/*.md      # progressive-disclosure layers
skills/bitrix-api-skill-creator/  # meta-skill: authoring spec for API/kernel skills
skills/bitrix-workflow-skill-creator/  # meta-skill: authoring spec for workflow/process skills
skills/bitrix-skill-eval/     # meta-skill: Q1–Q10 rubric, blind-test protocol, hard gates
skills/skill-validator/       # meta-skill: format validation + prism security scanning
agents/bitrix-coder.md        # Bitrix canons for skill consumers (D7, DI, /local/, security)
README.md / README.ru.md      # project docs + skill catalog
.github/workflows/validate.yml  # CI: smoke test + prism scan on every PR
plugin.json                   # Codex plugin manifest
```

### Related rulebooks

| File | Governs |
| --- | --- |
| This file | Contribution workflow in this repo |
| `agents/bitrix-coder.md` | Bitrix canons for agents on Bitrix projects (skill consumers) |
| `skills/bitrix-api-skill-creator/` | Product spec a finished skill must satisfy |
| `skills/bitrix-workflow-skill-creator/` | Authoring spec for workflow/process skills (conventions, code style, environment setup) |
| `skills/bitrix-skill-eval/` | Quality gate for skill drafts |
| `skills/skill-validator/` | Pre-PR validation (format + security scan) |

Skills reference the Bitrix canons (DI, `/local/`, security, version policy) from project rulebooks; neither skills nor this file duplicate them.

## Skill authoring pipeline

A new skill passes six steps; the owner of every step is a house skill — read it before acting.

First classify the draft: an **API skill** (documents kernel or module code) follows `bitrix-api-skill-creator`; a **workflow skill** (processes, conventions, environment setup) follows `bitrix-workflow-skill-creator`. The six steps below apply to both types — the chosen creator and the `bitrix-skill-eval` §11 dispatch carry the per-type details.

| Step | Owner | Output |
| --- | --- | --- |
| 1. Morphology decision (monolith vs router + rules) | `bitrix-api-skill-creator` §1 | Shape + size budget |
| 2. Domain surface discovery | `bitrix-api-skill-creator` §9.0 | Enumerated classes, services, settings, events |
| 3. Draft (router first, then `rules/*.md` one by one) | `bitrix-api-skill-creator` §2–§8 | Partial delivery stays useful |
| 4. Kernel verification (targeted greps, sibling cross-check) | `bitrix-api-skill-creator` §9 | Every identifier confirmed |
| 5. Evaluation (blind test, Q1–Q10, hard gates) | `bitrix-skill-eval` | Grades with `file:line` evidence |
| 6. Acceptance + catalog registration | This file | PR green in CI (smoke + security), with catalog rows |

**Acceptance bar** (from `bitrix-skill-eval` §4): mean ≥8.5 across Q1–Q10, zero invented identifiers (kernel ids for API skills; paths, config keys, commands, tool versions for workflow skills), coverage ≥85% of the scenario-scoped domain surface, within the time cap. Below any of these — iterate (max three runs), then report the trend.

Editing an existing skill: follow `bitrix-api-skill-creator` (§1, §4, §8) and re-run kernel verification on every changed identifier.

## Content conventions

- Skills: English, imperative, telegraphic bullets, tables for choices, fenced code with language tags. Zero marketing, zero "what is Bitrix".
- READMEs are bilingual: update `README.md` and `README.ru.md` in the same change, keeping the language of each file.
- Commits: English only, [Conventional Commits](https://www.conventionalcommits.org/) format (`docs:`, `fix:`, `feat:`, `chore:`, `refactor:`), one concern per commit. A new skill and its catalog rows may go together; unrelated skills split.
- Chat with the maintainer in Russian.

## Fact discipline

- Verify every identifier against kernel source (`bitrix/modules/<module>/lib/...`) or a project-local module's own code (`local/modules/<vendor>.<module>/`), then user-provided docs, then docs.1c-bitrix.ru as last resort.
- Absence claims ("there is no X") require a positive search for X first.
- Version policy: baseline **main 23.0+**; newer features marked **Since main X.Y** with fallback advice; never invent version numbers. Project-local modules anchor to their `install/version.php`.
- Contradictions with sibling skills are release blockers — resolve before submitting.

## Automated skill checks (new skills, before PR)

A new skill passes two automated checks before a PR is opened; the procedure is packaged as the `skill-validator` skill. Both are local, read-only, and run against the final skill folder. The same gates run in CI on every PR (`.github/workflows/validate.yml`): the catalog smoke job and the prism security scan (`fail-on high`, action pinned by SHA).

### Format: skill-creator scripts

`quick_validate.py` from [anthropics/skills › skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) validates the agent-skills spec: `SKILL.md` present, valid YAML frontmatter, `name` kebab-case ≤64 chars, `description` ≤1024 chars without angle brackets, allowed frontmatter keys only.

```bash
uv run --with pyyaml https://raw.githubusercontent.com/anthropics/skills/main/skills/skill-creator/scripts/quick_validate.py skills/<name>/   # exit code 0 = pass
```

Fix every reported error at the source.

### Security: prism-scanner

[prism-scanner](https://github.com/aidongise-cell/prism-scanner) — static analysis of a skill folder (shell execution, data exfiltration, prompt injection, hardcoded credentials, persistence); grade A–F; never executes the scanned code.

```bash
uvx --from prism-scanner prism scan skills/<name>/                # full report + grade
uvx --from prism-scanner prism scan skills/<name>/ --fail-on high # gate: exit code 0 = pass
```

Gate: `--fail-on high` exits 0. Grade C (medium findings only) — attach a written justification to the PR; grade D or F — blocker. Known false positives: suppress via `.prismignore` with rule ID + justification, never by ignoring the exit code.

## Before submitting a PR

- [ ] Automated checks pass on the skill folder: `quick_validate.py` exits 0; `prism scan --fail-on high` exits 0 (see "Automated skill checks").

- [ ] `name` frontmatter = folder name.
- [ ] Line counts within budget (monolith 100–310; router ≤60; each `rules/*.md` 45–135). Cut, never pad.
- [ ] Every changed identifier kernel-verified; 2+ negative-knowledge statements present.
- [ ] Prohibitions bold at the error site and echoed in the checklist; checklist items verifiable.
- [ ] Cross-links use exact catalog names; AGENTS.md canons referenced, never duplicated.
- [ ] Catalog rows added to `README.md`, `README.ru.md`, and the skills index in `agents/bitrix-coder.md`.
- [ ] Eval drafts live in the eval archive only; `skills/` untouched by runs.

## Hard prohibitions

- Never invent skill names, class identifiers, service ids, or version numbers.
- Never let an eval draft overwrite a reference skill.
- Never grade a skill from its author's self-assessment — grades need `file:line` evidence.
- Never duplicate AGENTS.md canons inside skills or this file.
- Never widen a rubric criterion mid-series to fit a draft.

## Environment

- Any agent that reads files works here; verification tools are grep/read against Bitrix kernel source when available.
- `.gitignore` covers agent/eval working folders (`.cursor`, `.tmp` eval snapshots, tier dirs). Keep run artifacts out of git.
