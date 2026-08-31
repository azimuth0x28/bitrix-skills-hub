---
name: bitrix-skill-creator
description: Covers house conventions for authoring Bitrix Framework skills in this repository — morphology choice (router vs monolith), router template, frontmatter description templates, baseline/Since versioning, mandatory content layers (API-choice matrix, kernel-fact precision, negative knowledge, code standards, prohibition placement), final checklists, cross-linking, kernel verification, and the quality bar with the line-density metric. Applied when creating or editing a skill under skills/, reviewing a skill draft for house-style compliance, or adapting Bitrix documentation into a skill. Key terms — SKILL.md, rules/, progressive disclosure, router, baseline, Since, API matrix, negative knowledge, checklist, antipatterns, house style, density.
---

# Bitrix Skill Authoring Conventions

House rules for skills in this repository. The generic skill-creator owns the process (draft, test prompts, eval loop, description optimization); this file defines the product spec a finished Bitrix skill must satisfy. It does not explain what skills are.

Goal: an agent following only this spec plus `AGENTS.md` must produce a skill at the quality of the existing collection — structure, precision, and density included.

| Concern | Owner |
| --- | --- |
| Draft → test → eval loop, packaging, description optimization | System skill-creator |
| Structure, content layers, style, quality bar of a Bitrix skill | This skill |
| Agent canons: DI boundaries, `/local/`, security, version policy | `AGENTS.md` — skills reference them, never repeat them |

A skill lives at `skills/<name>/SKILL.md` (+ optional `rules/*.md`); `name` equals the folder name.

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
description: <topics, comma-separated>. Use for/when <situations>.
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
- [ ] Followed DI / `/local/` / security canons from `AGENTS.md`.
```

Router invariants:

- Bullets under "When to read" are the H2 titles of that rules file, word for word — the agent routes by matching wording.
- The parenthetical after the path repeats the rules file's H1.
- The checklist is meta-only (discipline + AGENTS.md canons), never domain content.
- Rules files carry no frontmatter; H1 = the short title quoted in the router.

## 3. Frontmatter

- `name` equals the folder name exactly.
- The description is the trigger surface. Two templates:

Monolith:

```
Covers <topic> — <enumerated subtopics>. Applied when/for <task situations>. Key terms — <8–12 searchable tokens: class names, API ids, domain words>.
```

Router:

```
<topics, comma-separated>. Use for/when <situations>.
```

Rules: English only; concrete identifiers as key terms (they are what a user prompt matches); if the description contains `#` or `[` (attribute names like `#[NotEmpty]`), quote the whole value.

## 4. Baseline and versioning

- First line under the H1: `Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.`
- Newer features inline: `**Since main 25.900.**` followed by the fallback for older installs ("On older versions, scaffold files manually").
- Module-specific versions go inline too (`ui module 22.100+`).
- Never invent version numbers. If unverifiable, omit the marker and write "verify in your kernel".

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
- Exact skill names in backticks; never invent names outside the AGENTS.md index.

## 8. Style

- English. Imperative, telegraphic bullets; tables for choices and mappings; code for everything else.
- H1: `# <Topic> in Bitrix` or `# <Topic> (`<module>`)`. H2 = self-sufficient topics; the agent may read one section alone.
- Zero marketing, zero "what is Bitrix", zero restating official docs ("official docs answer what exists; skills answer how to write in `/local/` correctly").
- Fenced code blocks always carry the language (`php`, `javascript`, `bash`).
- Facts verified against the kernel; formulations copied from verified sibling skills where topics overlap.
- Router morphology: add a `## Cross-cutting invariants` section between the rule-file index and the checklist when rules that apply across ALL rule files exist (mixed-API bans, naming contracts, silent defaults) — the agent should meet them before opening any rule file.

## 9. Kernel verification (Bitrix-specific step)

0. **Discover the full surface first.** Before writing, enumerate the domain from the API docs or kernel source — classes in the namespace, constructor options, settings sections, the exception family, parameter binding/autowire surfaces, and the client-side call patterns that reach the API (AJAX entry points, REST methods). Memory alone under-covers; the enumeration decides the skill's scope and section list. Budget verification tightly: targeted greps (identifier, option name, class list), never full-file reads — the whole authoring pass should fit a few minutes. Time-box the verification to ~60 seconds: at most 3 targeted greps (options array, exception/class list, config sections) plus one read of the class constructor; skip internals (event payloads, transport implementation) unless one grep resolves them instantly.
1. Resolve the verification source in this order: (a) the running project's kernel — `bitrix/modules/<module>/lib/...` at the project root the agent works in (`/local/` overrides win); (b) a kernel or API-docs location the user provides — ask when the project has no `bitrix/` directory; (c) official online docs (docs.1c-bitrix.ru) as a last resort. Never hardcode a machine-specific path in a skill. Verify the constructor signature of every class shown in an example — argument types matter under `strict_types` (e.g. PSR-7 `Request` requires a `UriInterface`, a bare URL string is a fatal error).
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
| Q9 | Consistency | Cross-links use exact sibling names; AGENTS.md canons referenced, never duplicated; English imperative style throughout |
| Q10 | Generation time | Wall-clock for the authoring pass; faster is better at equal quality; targeted verification per §9 keeps it within minutes |

Counting rule for Q8: count knowledge points as you write; if a section spends more lines than the points it delivers, compress it into a table or a bullet list. Blank lines and code examples count toward lines; code inside examples delivers points only when it teaches a pattern beyond boilerplate. The budget applies per file: every `rules/*.md` stays within its 45–135 line budget — when a file overruns, merge adjacent examples, trim table columns, or split the file before widening it.

## Pre-submit checklist for the skill author

- [ ] `name` = folder name; description matches the template and carries key terms.
- [ ] Line count within budget after the reconciliation pass (cut, never pad).
- [ ] Morphology matches the decision rule; sizes within budget.
- [ ] Baseline line present; `Since` markers only where verified, with fallback advice.
- [ ] API-choice matrix present where multiple API layers exist.
- [ ] All identifiers verified against kernel source or sibling skills.
- [ ] Negative knowledge recorded for known hallucination traps.
- [ ] Code examples complete (strict_types, imports, Result handling, why-comments).
- [ ] Prohibitions bold at the error site and echoed in the checklist.
- [ ] Final checklist has verifiable items incl. negatives; router checklists stay meta-only.
- [ ] Router bullets = rules-file H2 titles verbatim (router morphology).
- [ ] Cross-links use exact skill names from the AGENTS.md index.
- [ ] AGENTS.md canons referenced, never duplicated.
- [ ] Density checked: ≤ reference density (~4.5–5 lines per knowledge point); line count within budget.
- [ ] English, imperative, tables, no marketing or product definitions.
