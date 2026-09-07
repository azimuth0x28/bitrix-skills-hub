---
name: bitrix-knowledge-skill-creator
description: Use when creating, editing, or reviewing a knowledge skill. Covers authoring conventions — correct and incorrect usage of a development aspect, best practices for kernel and module APIs (patterns, prohibitions, negative knowledge, morphology, density). Key terms — SKILL.md, rules/, router, baseline, Since, API matrix, kernel verification.
---

# Knowledge Skill Authoring Conventions

House rules for **knowledge skills** in this repository — skills that teach how to work correctly and incorrectly with a development aspect and convey best practices: kernel and module code, the API an agent writes against, patterns, prohibitions, negative knowledge. Workflow skills (processes, conventions, environment setup) follow `bitrix-workflow-skill-creator`. The generic skill-creator owns the process (draft, test prompts, eval loop, description optimization) — its canonical source is [anthropics/skills › skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator); this file refines it with the product spec a finished Bitrix knowledge skill must satisfy. The base agent-skills spec (what a SKILL is) is resolved per **Base skill dependency** below.

Goal: an agent following only this spec must produce a skill at the quality of the existing collection — structure, precision, and density included.

| Concern | Owner |
| --- | --- |
| Draft → test → eval loop, packaging, description optimization | System skill-creator |
| Structure, content layers, style, quality bar of a knowledge skill | This skill (workflow skills: `bitrix-workflow-skill-creator`) |
| Agent canons: DI boundaries, `/local/`, security, version policy | Project rulebooks — skills reference them, never repeat them |

A skill lives at `skills/<name>/SKILL.md` (+ optional `rules/*.md`); `name` equals the folder name.

## Base skill dependency (read before drafting)

This skill refines the generic `skill-creator` and depends on it for the base agent-skills spec. Check availability before drafting:

- `skill-creator` available → read it first; it owns what a skill is and the draft → test → eval loop.
- `skill-creator` unavailable → read [`references/skill-anatomy.md`](references/skill-anatomy.md) in this folder — a verbatim copy of the agent-skills anatomy (skill structure, required frontmatter, section layout, naming, context-efficiency rules). If the file is missing, fetch the canonical source: <https://github.com/addyosmani/agent-skills/blob/main/docs/skill-anatomy.md>.

Do not start a draft until one of the two has been read.

## 1. Choose the morphology first

| Morphology | When | Shape | Size budget |
| --- | --- | --- | --- |
| **Monolith** | Topic fits one reading pass: one module, one API surface, compact domain | Single `SKILL.md`, no `rules/` | 100–310 lines |
| **Router + rules** | Topic spans 2+ independent layers that rarely co-occur in one task (e.g. iblocks: basics / properties-elements / queries-SEO-perf; security: csrf-xss / sql-ssrf / jwt-access) | `SKILL.md` router + `rules/*.md` | Router ≤ 60 lines; rules 45–135 lines each |

Decision rule: if you cannot name two independent task layers, write a monolith. Split only when layers are genuinely independent.

Router delivery is incremental: write the router `SKILL.md` first, then each `rules/*.md` one by one — a partial delivery stays useful at any interruption point.

**Size is a hard gate.** Before submitting, count lines. If over budget, cut in this order: merge similar code examples (keep ≤5 total), shorten option-table purpose columns to ≤4 words, convert When-forks to compact tables, delete boilerplate lines. Cut, never pad — a draft over budget is a failed draft.

Subdirectories (`scripts/`, `references/`, `assets/`, `rules/`) follow the system skill-creator anatomy and are all allowed: bundle a script or asset whenever the skill requires a tool or it materially speeds up the task. Default to the thinnest structure that does the job — `rules/` splitting only for genuinely independent layers — and add weight (extra directories, bundled files) only with justified necessity.

## 2. Router template

Thin skills follow this skeleton verbatim — the wording is stable across the collection:

```markdown
---
name: <skill-name>
description: Use for/when <situations>. <topics, comma-separated>.
---

# <Topic> (`<module id>`)

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

Progressive disclosure: open **only** the rule files that match the task. Do not read every `rules/*.md`.

## How to use

1. Identify the layer the task touches.
2. Open the matching `rules/*.md` below.
3. Prefer framework-native Bitrix patterns over custom abstractions.

## Choose a rule file

### When to read `rules/<file>.md`

Read `rules/<file>.md` (`<Short Title>`) when the task involves:

- <H2 title inside the rules file — verbatim>
- ...

## Checklist

- [ ] Opened only the rule file(s) needed for this task.
- [ ] Followed DI / `/local/` / security canons.
```

Router invariants:

- Bullets under "When to read" are the H2 titles of that rules file, word for word — the agent routes by matching wording.
- The parenthetical after the path repeats the rules file's H1.
- The checklist is meta-only (discipline + canons), never domain content.
- Rules files carry no frontmatter; H1 = the short title quoted in the router.

## 3. Frontmatter

- `name` equals the folder name exactly.
- The description is the trigger surface. The trigger clause leads — `Use when`/`Applied when` first; topic coverage and key terms follow. Two templates:

Monolith:

```
Use when/for <task situations>. Covers <topic> — <enumerated subtopics>. Key terms — <8–12 searchable tokens: class names, API ids, domain words>.
```

Router:

```
Use for/when <situations>. <topics, comma-separated>.
```

Rules: English only; concrete identifiers as key terms (they are what a user prompt matches); if the description contains `#` or `[` (attribute names like `#[NotEmpty]`), quote the whole value.

Length: **hard limit 350 characters** — a draft over it fails review; trim before hand-off (drop redundant key terms, merge subtopics). The agent-skills spec allows 1024; this collection stays deliberately tighter.

## 4. Baseline and versioning

- First line under the H1: `Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.`
- Newer features inline: `**Since main 25.900.**` followed by the fallback for older installs ("On older versions, scaffold files manually").
- Module-specific versions go inline too (`ui module 22.100+`).
- Never invent version numbers. If unverifiable, omit the marker and write "verify in your kernel".
- **Project-local module** (`local/modules/<vendor>.<module>/`): the version anchor is the module's own `install/version.php` (`$arModuleVersion['VERSION']`) plus its changelog; kernel markers (`main 23.0+`, `Since main X.Y`) do not apply — state the module version the skill was verified against instead.

Semantics — every `main X.Y` marker is a dependency claim: it names the `main` module version from which the described functionality becomes available (`Baseline: **main 23.0+**` = minimum; `**Since main 25.900.**` = newer than baseline). Pre-check when applying a skill to a project: compare the project's `main` module version (its `install/version.php`) against the markers — below a marker the API may be missing or different, so use the fallback advice the skill carries.

## 5. Mandatory content layers (monolith)

Order the body so the agent's first decision is answered first:

1. **Positioning paragraph** (1–3 sentences): what the area owns, hard boundaries, related skills in backticks. If the class is the entry point to an adjacent service (e.g. `HttpClient` → GeoIP manager), add a 2–3 line pointer with a cross-link to the sibling skill — deep coverage of that service belongs in the sibling skill, here it would blow the size budget.
2. **API-choice matrix** — the first content section whenever several API layers exist. Table `Task → API` across object model / ORM (read-only?) / Manager / legacy `C*`, with a "why" note per row or a bold summary under it. This answers the agent's most frequent question.
3. **Kernel facts with exact identifiers**: FQCN, service ids (`main.validation.service`), table names (`b_iblock`), file paths (`/local/routes/web.php`), settings sections. When the domain has a global configuration surface, document it: the `.settings.php` section (`http_client_options`), the `Configuration::getValue` accessor, constructor-override precedence, and named loggers (`loggers.main.HttpClient`). One wrong identifier poisons the whole skill.
4. **Negative knowledge** — state what does not exist in the kernel: missing settings sections, fictional cache tags, what a generator does not scaffold, commonly confused name pairs (`RegExp` vs `Regex`, `message` vs `errorMessage`). This is anti-hallucination fencing: 2–4 statements per skill; repeat the severe traps in the checklist.
5. **Complete code examples**: `<?php declare(strict_types=1);` for standalone snippets, real imports, realistic names (`vendor.module`, `Vendor\Module`), Result/error handling shown, comments inside code explaining why/order/timing ("// BEFORE getPropertyCollection(); not validated vs site"). Multi-step flows get a numbered pipeline where the order itself is semantic. When examples catch exceptions, enumerate the kernel's full exception family for that API and give the catch order (e.g. `NetworkException` → `RequestException` → `ClientException`); a partial catch list misses failure modes.
6. **Prohibitions bold, at the error site**: "Never change an order via `OrderTable::update()`" lives in the section where the temptation arises, then echoes in the checklist. A separate `## Antipatterns` section is optional; inline bold bans are the default.
7. **"When X vs Y" sections** for recurring forks (`init.php` vs module, `\DateTime` vs Bitrix `DateTime`), including legacy migration notes when relevant.
8. **Tree diagrams** (`├──` with `#` comments) only for "where do files live" topics.

## 6. Checklist

Final `## Checklist` with `- [ ]` items that are verifiable completion criteria, including negative items ("no Vue 2", "no direct ORM writes to order tables"). 6–11 items for a monolith. Every bold prohibition appears here.

## 7. Cross-linking

- Inline references at topic boundaries: "see skill `bitrix-performance`".
- Optional `## Related skills` section at the end (deep domains like sale).
- Exact skill names in backticks; never invent names — cross-link only existing skills.

## 8. Style

- English. Imperative, telegraphic bullets; tables for choices and mappings; code for everything else.
- H1: `# <Topic> in Bitrix` or `# <Topic> (`<module>`)`. H2 = self-sufficient topics; the agent may read one section alone.
- Zero marketing, zero "what is Bitrix", zero restating official docs ("official docs answer what exists; skills answer how to write in `/local/` correctly").
- Fenced code blocks always carry the language (`php`, `javascript`, `bash`).
- Facts verified against the kernel; formulations copied from verified sibling skills where topics overlap.
- Router morphology: add a `## Cross-cutting invariants` section between the rule-file index and the checklist when rules that apply across ALL rule files exist (mixed-API bans, naming contracts, silent defaults) — the agent should meet them before opening any rule file.
- **Mixed XML + Markdown style (optional)**: the body may wrap semantic sections in XML blocks — role/mission, context, hard rule sets, workflow stages, checkpoints, quality checks — while Markdown stays the outer layer (headings, tables, lists, code fences). Default stays pure Markdown; pick one style per file and stay consistent throughout.
  - Mixed-style discipline: XML lives in the body only — frontmatter stays plain YAML (allowed keys, angle-bracket-free description); 2-space indent per nesting level, ≤2–3 levels, one semantic role per tag, `lowercase_with_underscores` tag names, double-quoted attributes, Markdown inside tags.
  - Mixed-style content: every §5 layer stays present and findable — `<workflow>`/`<stage>` blocks satisfy the procedures layer, `<critical_rules>` with bold rule text satisfies prohibitions at the error site, a checks block satisfies the checklist; a single XML block must be self-sufficient like an H2 section.
  - Structure lines count toward the §1 budget and the Q8 density band — XML earns its lines with boundaries the task actually needs, or it goes.

## 9. Kernel verification (Bitrix-specific step)

0. **Discover the full surface first.** Before writing, enumerate the domain from the API docs or kernel source — classes in the namespace, constructor options, settings sections, the exception family, parameter binding/autowire surfaces, and the client-side call patterns that reach the API (AJAX entry points, REST methods). Memory alone under-covers; the enumeration decides the skill's scope and section list. Budget verification tightly: targeted greps (identifier, option name, class list), never full-file reads — the whole authoring pass should fit a few minutes. Time-box the verification to ~60 seconds: at most 3 targeted greps (options array, exception/class list, config sections) plus one read of the class constructor; skip internals (event payloads, transport implementation) unless one grep resolves them instantly.
1. Resolve the verification source in this order: (a) the running project's source — kernel `bitrix/modules/<module>/lib/...`, or for a skill about a project-local module that module's own code `local/modules/<vendor>.<module>/` — at the project root the agent works in (`/local/` overrides win); (b) a kernel or API-docs location the user provides — ask when the project has no `bitrix/` directory; (c) official online docs (docs.1c-bitrix.ru) as a last resort. Never hardcode a machine-specific path in a skill. Verify the constructor signature of every class shown in an example — argument types matter under `strict_types` (e.g. PSR-7 `Request` requires a `UriInterface`, a bare URL string is a fatal error).
2. Cross-check identifiers against sibling skills that mention the same API — contradictions between skills are release blockers.
3. Anything unverifiable from docs or siblings: either drop it or mark it explicitly ("verify against your kernel").
4. For each "There is no X" statement, search the docs/kernel once for X before asserting absence. Never assert absence of a class or option from memory alone.

## 10. Quality bar (acceptance criteria)

A draft is accepted when all of the following hold. These are the criteria for comparing a draft against a reference skill:

| # | Criterion | Measure |
| --- | --- | --- |
| Q1 | Structure compliance | Morphology per §1; sizes within budget; templates of §2–§4 followed |
| Q2 | Triggerability | Description matches §3 template and carries concrete key terms |
| Q3 | Coverage | Every major API layer, operation class, and integration point of the domain appears; API-choice matrix present where layers exist |
| Q4 | Precision | Zero invented identifiers; verified facts only; 2+ negative-knowledge statements |
| Q5 | Code quality | Examples complete: strict_types, imports, Result handling, why-comments; pipeline order explained where semantic |
| Q6 | Safety | Bold prohibitions at the error site; all echoed in the checklist |
| Q7 | Checklist | Verifiable items incl. negative ones; 6–11 for a monolith |
| Q8 | Density (efficiency) | Lines of skill per knowledge point. A **knowledge point** = one discrete actionable item: an API pattern/recipe, a table row, an option default, a prohibition, a negative fact. The shipped collection measures ~4.5–5 lines per point; a draft must match or beat the reference density (fewer lines per point = better). A draft may not exceed 1.2× the reference line count unless it covers measurably more points |
| Q9 | Consistency | Cross-links use exact sibling names; canons referenced, never duplicated; English imperative style throughout |
| Q10 | Generation time | Wall-clock for the authoring pass; faster is better at equal quality; targeted verification per §9 keeps it within minutes |

Counting rule for Q8: count knowledge points as you write; if a section spends more lines than the points it delivers, compress it into a table or a bullet list. Blank lines and code examples count toward lines; code inside examples delivers points only when it teaches a pattern beyond boilerplate. The budget applies per file: every `rules/*.md` stays within its 45–135 line budget — when a file overruns, merge adjacent examples, trim table columns, or split the file before widening it.

## Validation after authoring

A finished draft must pass the format check before hand-off — run it even if the `skill-validator` skill is unavailable. The instruction below is self-contained: the script is fetched straight from the canonical repo of the base skill this file refines, so a missing system skill-creator blocks nothing.

```bash
uv run --with pyyaml https://raw.githubusercontent.com/anthropics/skills/main/skills/skill-creator/scripts/quick_validate.py skills/<name>/
```

Exit code 0 = pass. The script enforces the agent-skills spec: `SKILL.md` present, valid YAML frontmatter, allowed frontmatter keys only, `name` kebab-case ≤64 chars, `description` ≤1024 chars without angle brackets. Fix every reported error at the source and re-run until clean — never bypass or weaken a check. The full mechanical gate (format + security scan) is packaged as the `skill-validator` skill.

## Pre-submit checklist for the skill author

- [ ] `name` = folder name; description matches the template and carries key terms.
- [ ] Description length: ≤350 chars.
- [ ] Line count within budget after the reconciliation pass (cut, never pad).
- [ ] Format check passes on the final draft ("Validation after authoring"): exit code 0, errors fixed at the source.
- [ ] Morphology matches the decision rule; sizes within budget.
- [ ] Baseline line present; `Since` markers only where verified, with fallback advice.
- [ ] API-choice matrix present where multiple API layers exist.
- [ ] All identifiers verified against kernel source or sibling skills.
- [ ] Negative knowledge recorded for known hallucination traps.
- [ ] Code examples complete (strict_types, imports, Result handling, why-comments).
- [ ] Prohibitions bold at the error site and echoed in the checklist.
- [ ] Final checklist has verifiable items incl. negatives; router checklists stay meta-only.
- [ ] Router bullets = rules-file H2 titles verbatim (router morphology).
- [ ] Cross-links use exact names of existing collection skills.
- [ ] Canons referenced, never duplicated.
- [ ] Density checked: ≤ reference density (~4.5–5 lines per knowledge point); line count within budget.
- [ ] English, imperative, tables, no marketing or product definitions.
- [ ] Mixed XML + Markdown body (when used): §8 mixed-style constraints hold.
