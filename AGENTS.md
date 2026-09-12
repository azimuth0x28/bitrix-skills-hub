# AGENTS.md

Guide for AI agents contributing to **bitrix-skills-hub** — a hub of AI skills for **1C-Bitrix / Bitrix Framework** (D7).

## Project overview

- Plain markdown repository: domain skills + meta-skills under `skills/`. One skill = one folder.
- A skill teaches an agent one Bitrix domain: `SKILL.md` (router, ≤60 lines) + optional `rules/*.md` (45–135 lines each, progressive disclosure).
- No build, no test suite. Quality is enforced by mechanical checks (`skills/skill-validator/`), the review checklist, and the evaluation protocol in `skills/bitrix-skill-eval/`.
- User-facing docs: `README.md` (English, primary) and `README.ru.md` (Russian). The catalog of all skills lives in both.

## Repository structure

```
skills/<name>/SKILL.md        # router: what the skill covers, which rules/*.md to open
skills/<name>/rules/*.md      # progressive-disclosure layers
skills/<name>/references/     # template assets (workflow skills): copied verbatim into the target project
skills/bitrix-knowledge-skill-creator/  # meta-skill: authoring spec for knowledge skills
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
| This file | How to contribute here: authoring pipeline, content conventions, fact discipline, PR checklist |
| `agents/bitrix-coder.md` | How agents write Bitrix code on consumer projects (D7, DI, `/local/`, security, version policy) |
| `skills/bitrix-knowledge-skill-creator/` | How to author knowledge skills (correct/incorrect usage of a dev aspect, best practices): structure, content layers, kernel verification |
| `skills/bitrix-workflow-skill-creator/` | How to author workflow skills: decision tables, project facts, procedures, tool versions |
| `skills/bitrix-skill-eval/` | How skill drafts are graded: blind test, Q1–Q10 rubric, hard gates |
| `skills/skill-validator/` | How to run mechanical checks (quick_validate.py, prism scan) before a PR |

Skills reference the Bitrix canons (DI, `/local/`, security, version policy) from project rulebooks; neither skills nor this file duplicate them.

## Skill authoring pipeline

A new skill passes six steps; the owner of every step is a house skill — read it before acting.

First classify the draft: a **knowledge skill** (teaches correct and incorrect usage of a development aspect and conveys best practices: kernel/module code, APIs) follows `bitrix-knowledge-skill-creator`; a **workflow skill** (processes, conventions, environment setup) follows `bitrix-workflow-skill-creator`. The six steps below apply to both types — the chosen creator and the `bitrix-skill-eval` §11 dispatch carry the per-type details. The type is fixed in the frontmatter (`metadata: {type: knowledge|workflow}`) at step 3 and drives both the creator spec and the eval dispatch.

| Step | Owner | Output |
| --- | --- | --- |
| 1. Morphology decision (monolith vs router + rules) | `bitrix-knowledge-skill-creator` §1 | Shape + size budget |
| 2. Domain surface discovery | `bitrix-knowledge-skill-creator` §9.0 | Enumerated classes, services, settings, events |
| 3. Draft (router first, then `rules/*.md` one by one) | `bitrix-knowledge-skill-creator` §2–§8 | Partial delivery stays useful |
| 4. Kernel verification (targeted greps, sibling cross-check) | `bitrix-knowledge-skill-creator` §9 | Every identifier confirmed |
| 5. Evaluation (blind test, Q1–Q10, hard gates) | `bitrix-skill-eval` | Grades with `file:line` evidence |
| 6. Acceptance + catalog registration | This file | PR green in CI (smoke + security), with catalog rows |

**Acceptance bar** (from `bitrix-skill-eval` §4): mean ≥8.5 across Q1–Q10, zero invented identifiers (kernel ids for knowledge skills; paths, config keys, commands, tool versions for workflow skills), coverage ≥85% of the scenario-scoped domain surface, within the time cap. Below any of these — iterate (max three runs), then report the trend.

Editing an existing skill: follow `bitrix-knowledge-skill-creator` (§1, §4, §8) and re-run kernel verification on every changed identifier.

## Content conventions

- Skills: English, imperative, telegraphic bullets, tables for choices, fenced code with language tags. Zero marketing, zero "what is Bitrix".
- Skill descriptions are situation-first per the creator specs: the trigger clause leads (`Use when` — an operation on a code artifact for knowledge skills; `Use before/after/when asked to` — a process point for workflow skills), then `Covers <topics>. Key terms — <unique tokens>`. Soft limit 350 chars, hard 400. Run the live-prompt test: 3–5 prompts in user wording, every prompt word must have a foothold in the description.
- READMEs are bilingual: update `README.md` and `README.ru.md` in the same change, keeping the language of each file.
- Commits: English only, [Conventional Commits](https://www.conventionalcommits.org/) format (`docs:`, `fix:`, `feat:`, `chore:`, `refactor:`), one concern per commit. A new skill and its catalog rows may go together; unrelated skills split.
- Chat with the maintainer in Russian.

### Skill versioning

- Every `SKILL.md` declares `metadata: {type: knowledge|workflow, version: "X.Y.Z"}` — semver per skill, travels with the folder when installed on consumer projects.
- Bump table:

| Bump | What warrants it |
| --- | --- |
| patch | typos, formatting, wording without meaning change |
| minor | rule-content changes, new/edited rules file, description changes (description optimization included), new examples |
| major | baseline change, reversed recommendation, deprecation |

- A new skill starts at `1.0.0`.
- Any file change under `skills/<name>/` requires a version bump in the same PR. CI gate: `python3 .github/scripts/check-versions.py <base-sha>`.
- minor+ bumps reference a fresh eval record (`bitrix-skill-eval` archive) in the PR; patch bumps need mechanical checks only.
- Line budgets are ratcheted: violations listed in `.github/scripts/budget-baseline.txt` are grandfathered; a fix must remove its baseline line (stale lines fail CI).
- `plugin.json` version tracks the latest release tag; the catalog smoke fails on drift.

## Fact discipline

- Verify every identifier against kernel source (`bitrix/modules/<module>/lib/...`) or a project-local module's own code (`local/modules/<vendor>.<module>/`), then user-provided docs, then docs.1c-bitrix.ru as last resort.
- Absence claims ("there is no X") require a positive search for X first.
- Version policy: baseline **main 23.0+**; newer features marked **Since main X.Y** with fallback advice; never invent version numbers. Project-local modules anchor to their `install/version.php`.
- Contradictions with sibling skills are release blockers — resolve before submitting.

## Automated skill checks (new skills, before PR)

A new skill passes two automated checks before a PR is opened; the procedure is packaged as the `skill-validator` skill. Both are local, read-only, and run against the final skill folder. The same gates run in CI on every PR (`.github/workflows/validate.yml`): the catalog smoke job and the prism security scan (`fail-on high`, action pinned by SHA).

Run the line-budget ratchet locally too: `bash .github/scripts/check-budgets.sh` (exit 0 = pass; a stale baseline entry fails). The version gate (`python3 .github/scripts/check-versions.py <base-sha>`) runs in CI on every PR against the base SHA — see "Skill versioning".

### Format: skill-creator scripts

`quick_validate.py` from [anthropics/skills › skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) validates the agent-skills spec: `SKILL.md` present, valid YAML frontmatter, `name` kebab-case ≤64 chars, `description` ≤1024 chars without angle brackets, allowed frontmatter keys only.

```bash
uv run --with pyyaml skills/skill-validator/scripts/quick_validate.py skills/<name>/   # exit code 0 = pass (vendored Apache-2.0 copy; raw-URL fallback in skill-validator's negative knowledge)
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

- [ ] `name` frontmatter = folder name; `metadata: {type: knowledge|workflow}` present; description situation-first per the creator spec (soft ≤350 / hard ≤400 chars) and live-prompt tested.
- [ ] Line counts within budget (monolith 100–310; router ≤60; each `rules/*.md` 45–135). Cut, never pad.
- [ ] Changed skill folders carry a bumped `metadata.version` per "Skill versioning"; minor+ bumps carry a fresh eval record in the PR.
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
