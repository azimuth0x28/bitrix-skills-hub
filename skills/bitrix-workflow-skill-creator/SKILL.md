---
name: bitrix-workflow-skill-creator
description: Covers authoring conventions for workflow skills — process, convention, and environment skills (code style, project rules, DevOps setup, review rules). Project-fact verification, decision tables, verifiable procedures, tool-version anchoring. Applied when creating, editing, or reviewing a workflow-type skill. Key terms — workflow skill, process skill, decision table, runbook, project facts, tool versions.
---

# Workflow Skill Authoring Conventions

House rules for **workflow skills** — skills that teach a process: code style, code organization, project conventions, environment and DevOps setup, review rules. Skills that document kernel or module code follow `bitrix-api-skill-creator`. The generic skill-creator owns the draft → test → eval loop ([anthropics/skills › skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator)); this file refines it for the workflow type. It does not explain what skills are.

| Concern | Owner |
| --- | --- |
| Draft → test → eval loop, packaging, description optimization | System skill-creator |
| API/kernel/module skills: content layers, kernel verification, Baseline/Since | `bitrix-api-skill-creator` |
| Workflow skills: content layers, project-fact verification, tool versions | This skill |
| Rubric, blind-test protocol, acceptance bar for both types | `bitrix-skill-eval` |

## 1. Type dispatch

Pick the creator before drafting:

| Skill teaches... | Creator | Skill type |
| --- | --- | --- |
| Kernel classes, service ids, tables, module APIs — code the agent writes against | `bitrix-api-skill-creator` | API skill |
| How to work: conventions, code style, processes, environment setup, review steps — process the agent follows | This skill | Workflow skill |

A workflow skill may reference kernel identifiers inside examples or config keys — every such identifier is still verified per `bitrix-api-skill-creator` §9. An API-choice-matrix-shaped draft is an API skill: reclassify and switch creators. Declare the type when requesting evaluation — `bitrix-skill-eval` dispatches rubric measures per type (its §11).

## 2. Morphology

Same decision rule and budgets as `bitrix-api-skill-creator` §1: monolith (100–310 lines) when the process fits one reading pass; router + `rules/*.md` (router ≤60, rules 45–135 each) when it spans 2+ independent layers (e.g. environment setup / daily workflow / release process). Deliver incrementally: router first, then rules files one by one. Size is a hard gate — cut, never pad.

## 3. Frontmatter and templates

- `name` equals the folder name; description per `bitrix-api-skill-creator` §3 templates (soft limit 400 chars, hard 500). Key terms are tool names, paths, and command names — what a user prompt matches.
- H1: `# <Topic>` — no module id.
- **Never write a `Baseline:` line.** Kernel versioning (`main X.Y`) does not apply to a process; a Baseline line in a workflow skill is a defect.
- Router variant: the skeleton of `bitrix-api-skill-creator` §2 minus the Baseline line; all router invariants (verbatim H2 bullets, meta-only checklist) hold.

## 4. Version anchoring

- Versions anchor to the sources of truth the workflow lives in: `composer.json` (`php` requirement), `package.json` (`engines`), `Dockerfile` base images, CI workflow matrices, `.editorconfig`, tool configs.
- State a version together with its source: "PHP 8.2+ (`composer.json`)", "Node 20 (CI matrix)". Never invent a version; if unverifiable, write "verify in your project".
- Bitrix kernel version claims inside examples follow `bitrix-api-skill-creator` §4.

## 5. Mandatory content layers

Order the body so the agent's first decision is answered first:

1. **Positioning paragraph** (1–3 sentences): which process or convention the skill governs, hard boundaries, related skills in backticks.
2. **Decision tables** — the workflow analog of the API-choice matrix. Table `Situation → Rule/Action` with a why note per row or a bold summary under it. Recurring forks (`CI vs local`, `module config vs global config`) get the same treatment.
3. **Project facts**: exact file paths, config keys, command lines, tool versions — each verifiable in the project repo or tool docs. One wrong path or config key poisons the whole skill.
4. **Procedures** — numbered steps where order is semantic (setup runbooks, release flows). Every step names its verifiable outcome: file created, command exits 0, CI green.
5. **Environment matrix** when tooling varies: tool → required version → source of truth.
6. **Negative knowledge**: what the toolchain does not do, absent configs, commonly confused settings, misconceptions about the process. 2–4 statements; repeat severe traps in the checklist.
7. **Prohibitions bold, at the error site**, echoed in the checklist.
8. **Code/command examples**: fenced blocks with language tags (`bash`, `php`, `yaml`, `ini`); commands copy-pasteable, idempotent where possible; config snippets complete for their scope.

## 6. Checklist

Final `## Checklist` with `- [ ]` items that are verifiable completion criteria, including negatives ("no hardcoded secrets", "no step skipped"). 6–11 items for a monolith. For procedure skills, checklist items map to procedure outcomes. Every bold prohibition appears here.

## 7. Cross-linking and style

`bitrix-api-skill-creator` §7–§8 apply unchanged: exact sibling names in backticks, canons referenced never duplicated, English imperative, tables for choices, fenced code with language tags. The optional mixed XML + Markdown body style of §8 applies to workflow skills on the same terms — procedures sit naturally in `<workflow>`/`<stage>` blocks, prohibitions in `<critical_rules>`; decision tables stay Markdown tables.

## 8. Project verification (workflow-specific step)

0. **Discover the process surface first.** Enumerate from the project the skill targets: manifests (`composer.json`, `package.json`), config files (`.editorconfig`, `phpstan*`, `phpcs*`, `docker-compose*`), CI workflows, env files, existing convention docs (`AGENTS.md`, `CONTRIBUTING`). The enumeration decides scope and section list. Time-box verification: targeted reads/greps of the named files, never full-tree sweeps.
1. Resolve each fact in this order: (a) the project itself — path, key, or command confirmed by a targeted read/grep, recorded as `file:line`; (b) convention docs the user provides — ask when the project has none; (c) official tool documentation as a last resort. Never hardcode a machine-specific path. Every command example is syntactically complete and runnable as written.
2. Cross-check conventions against sibling workflow skills and the project's `AGENTS.md` — contradictions between skills are release blockers.
3. For each "the project has no X" statement, search once for X before asserting absence.
4. Anything unverifiable: drop it or mark "verify in your project".

## 9. Quality bar

Accept when all hold. Measures align with the workflow dispatch in `bitrix-skill-eval` §11:

| # | Criterion | Measure |
| --- | --- | --- |
| Q1 | Structure compliance | Morphology per §2; templates of §3–§6 followed |
| Q2 | Triggerability | Description per §3; concrete tool/path/command key terms |
| Q3 | Coverage | Every stage, decision fork, environment fact, and procedure of the declared scenario scope appears |
| Q4 | Precision | Zero invented paths, config keys, commands, versions; 2+ negative statements |
| Q5 | Completeness | Commands copy-runnable; config snippets complete for scope; step order explained where semantic |
| Q6 | Safety | Bold prohibitions at the error site; all echoed in the checklist |
| Q7 | Checklist | Verifiable items incl. negatives; 6–11 for a monolith |
| Q8 | Density | ≤ reference density; the collection band 3–5 lines per knowledge point applies |
| Q9 | Consistency | Cross-links exact; canons referenced, never duplicated; English imperative |
| Q10 | Generation time | Wall-clock; targeted verification per §8 keeps it within minutes |

## Validation after authoring

Run the format check and the security gate packaged in `skill-validator` — same commands, same gates, same exit-code discipline as every skill in this collection (see `bitrix-api-skill-creator` → Validation after authoring). Fix every reported error at the source; never bypass or weaken a check.

## Pre-submit checklist for the skill author

- [ ] Type dispatch correct: process/convention content → this skill; kernel-heavy content → `bitrix-api-skill-creator`.
- [ ] `name` = folder name; description per §3 template; length soft ≤400, hard ≤500 chars.
- [ ] Line count within budget (monolith 100–310; router ≤60; rules 45–135). Cut, never pad.
- [ ] No `Baseline:` line; tool versions anchored to project manifests or CI configs.
- [ ] Decision table present where recurring forks exist.
- [ ] All paths, config keys, and commands verified against the project (`file:line` recorded).
- [ ] 2+ negative-knowledge statements recorded.
- [ ] Procedure steps carry verifiable outcomes; commands copy-runnable.
- [ ] Prohibitions bold at the error site and echoed in the checklist.
- [ ] Cross-links use exact names of existing collection skills.
- [ ] Format check exits 0; prism scan passes the repo gate.