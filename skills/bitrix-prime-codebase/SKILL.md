---
name: bitrix-prime-codebase
description: Use when onboarding a codebase or before generating project rules. Primes the codebase for Brownfield rules generation — analyzes layout, ORM usage, migrations, event handlers, coding style, git history; produces `codebase-analysis.md` with file:line evidence and a tiered canon-deviation register (DEV-N) against hub canon skills, feeding `bitrix-rules-create-global`. Key terms — prime, codebase analysis, Brownfield, seams, canon deviations, DEV.
---

# Bitrix Prime Codebase: Analyze a 1C-Bitrix Project's Real Conventions

<role_definition>
  Produce a **reality map** of a 1C-Bitrix (on-premise) codebase:
  a single `$project-path/.tmp/codebase-analysis.md` at the project root that captures **what actually exists**
  with `file:line` evidence, **plus a norm delta** — a tiered register of deviations from the hub canon skills
  (section 11), so `bitrix-rules-create-global` can generate honest rules in Brownfield mode and resolve
  canon conflicts with the user instead of silently canonizing legacy practice.
</role_definition>

<context>
  <system_context>
    This is a **read-only analysis**, not a code review and not an improvement plan.
    The document answers one question for every future agent and developer:
    *"how does this project actually work, and what should I follow?"*
  </system_context>

  <domain_context>
    1C-Bitrix on-premise · PHP · D7 ORM (`\Bitrix\Main\ORM`) · legacy `CIBlockElement` API ·
    `CAgent` background tasks · event handlers (`AddEventHandler`) · component templates ·
    `/local/` vs `/bitrix/` layout · vendor conventions (default: `{{VENDOR_NAME}}`).
  </domain_context>

  <task_context>
    Output one file: `$project-path/.tmp/codebase-analysis.md` (12 fixed sections).
    The output feeds `bitrix-rules-create-global`, which converts findings into `.agents/rules/core/*.md`
    and resolves the section-11 canon deviations with the user.
  </task_context>
</context>

<critical_rules enforcement="strict">
  <rule id="read-only" scope="all">
    Analyze the project and write only `$project-path/.tmp/codebase-analysis.md`. Do NOT modify any project source file.
  </rule>

  <rule id="evidence" scope="sections-3-9">
    Back every claim in sections 3-9 with a citation: `file:line`
    (e.g. `/local/modules/{{vendor_name}}.billing/lib/Model/BalanceSyncTable.php:12`).
    Cite the **actual path** as it exists in the repo — do NOT use a normalized one.
  </rule>

  <rule id="variance" scope="all">
    If a pattern is inconsistent (D7 here, `CIBlockElement` there), document the variance
    explicitly — do NOT smooth it over.
  </rule>

  <rule id="canon-comparison" scope="all">
    Record a **norm delta**: compare observed practice against the hub canon skills (stage 3, Canon Scan)
    and register every divergence as a numbered `DEV-<n>` entry with a tier (1/2/3) in section 11
    "Canon Deviations" — never smoothed into the "actual conventions" narrative.
    Canon sources: sibling hub skills (`../<skill-name>/SKILL.md`) or project-installed copies
    (`.agents/skills/<skill-name>/SKILL.md`) — use whichever is found first.
    If canon skills are unavailable, do NOT block and do NOT invent a register: fall back to the
    legacy facts-only behavior — collect facts (stage 2), build the document from the collected
    data, and let `bitrix-rules-create-global` do the same; mark section 11 accordingly.
    Budget discipline: never sweep the whole installed skill set. Check only canon skills explicitly
    named in the project's instructions (root file, Tier-1 rules) plus the most relevant ones for
    areas where a deviation from a known norm is suspected — a small bounded set, not the catalog.
    An area with no applicable canon skill yields a Seam (section 10), never a speculative DEV entry.
    Deviation entries stay neutral: canon rule reference, observed fact, evidence, scope.
    Resolution belongs to `bitrix-rules-create-global` and the user — never write it here.
  </rule>

  <rule id="not-found-is-valid" scope="all">
    Treat "Not found" as a valid finding. Write it explicitly
    (e.g. "Migrations not found").
  </rule>

  <rule id="no-recommendations" scope="sections-3-9">
    Do NOT write recommendations in sections 3-9 — only observations.
    Call out gaps in Seams (section 10).
  </rule>
</critical_rules>

<workflow>
  Run these five stages in order. Work directly in the project (`$project-path` or cwd).
  Be thorough but bounded: stop when the pattern is clear — do not inventory every file
  in a 10k-file monolith.

  <stage id="1" name="Inventory" required="true">
    Map the top-level structure. Read (do not guess):
    - `composer.json` — project name, vendor, PHP version, dev packages (php-cs-fixer, php_codesniffer, kit.migrator?)
    - `/local/` — existence, subdirectories (`php_interface/`, `components/`, `templates/`, `modules/`, `js/`, `vendor/`, `activities/`)
    - `/bitrix/` — note third-party (non-core) modules in `/bitrix/modules/` the project depends on
    - `migrations/` or migration config — exists or not
    - config files: `.phpcs.xml`, `.php-cs-fixer.dist.php`, `.gitignore`, `.env*`

    <output>Provide the actual directory tree (2-3 levels deep, one-line descriptions)</output>
  </stage>

  <stage id="2" name="Pattern Scan" required="true">
    Use grep; for fan-out on large repos, `explore` subagents are an option.
    For each area, collect **3-5 concrete examples** with `file:line` citations:

    <routing_table>
      | Area | What to search for | What to record |
      | :--- | :----------------- | :------------- |
      | ORM usage | `extends DataManager`, `CIBlockElement::`, `CIBlockSection::`, `CCatalogProduct`, `CSaleOrder` | Which API dominates? Where is D7 used vs legacy? |
      | Migrations | `migrator`, `up()`/`down()` in a migrations dir, `CSqlFormatter` | Tool used? Naming convention? Where do migrations live? |
      | Event handlers | `AddEventHandler`, `RegisterModuleDependences`, `.events.php` | Registration points: `/local/php_interface/init.php`, module installers, `.events.php`? |
      | Agents | `CAgent::AddAgent`, `\Bitrix\Main\Agent` | Where registered? Interval pattern? Idempotency guards? |
      | Components | `/local/components/*/class.php` vs `component.php`, `executeComponent()` | Complex vs simple? Does `template.php` contain business logic? |
      | Code style | `declare(strict_types=1)`, `namespace `, function naming, tabs vs spaces, `<?php` closing tags | Actual style: strict types? naming (camelCase/snake_case)? indentation? PHPDoc coverage? |
      | Form/security | `bitrix_sessid()`, `check_bitrix_sessid()`, `$APPLICATION->ResetException()`, `addMessage2Log` | CSRF usage? Exception vs legacy error pattern? |
    </routing_table>

    <output>Provide findings per area with citations</output>
  </stage>

  <stage id="3" name="Canon Scan" required="true">
    Compare observed practice (stage 2) against the hub canon skills. Load each canon skill and check
    only its key invariants — do not restate the whole skill. Register every divergence as `DEV-<n>`
    (tier + canon rule + observed fact + evidence + scope) for section 11 "Canon Deviations".

    Canon selection is budgeted (rule `canon-comparison`): Tier-1 always (when available), Tier-2 only
    for areas the project actually has, Tier-3 only where the pattern scan surfaced a deviation and a
    relevant canon skill exists. Skills neither named in project instructions nor matching a scanned
    area stay unchecked — never sweep the whole installed skill set.

    <tier_table>
      | Tier | When | Canon skills | Key invariants to check |
      | :--- | :--- | :----------- | :---------------------- |
      | 1 — blockers (structure, modules, .settings, database) | always (when canon available) | `bitrix-project-structure`, `bitrix-modules`, `bitrix-settings`, `bitrix-database` (+ `bitrix-orm`) | `/local/` vs `/bitrix/` placement and autoload wiring; module anatomy per module in `/local/modules/`: `composer.json` (`bitrix-d7-module`, PSR-4 `lib/`), namespace vendor case (StudlyCaps, e.g. `FirstBit\`), two-layer event model (runtime rows + `main:OnPageStart` entry point vs installer-persistent events), `lib/Module/{Constants,Configuration,EventManager,OptionManager,Bootstrapper}` + `lib/Internal/`, component sources in `install/files/`; `.settings.php` sections (connections, cache, session, exception_handling, loggers); raw-SQL call sites vs D7 ORM, migrations, table naming |
      | 2 — area canons (controllers, routing, components) | only for areas that exist in the project | `bitrix-controllers`, `bitrix-routing`, `bitrix-components` | Controller/JsonController patterns and action filters; `/local/routes/` registration vs urlrewrite; component anatomy (complex vs simple, `class.php`-only), vendor placement of custom components |
      | 3 — other canons (non-critical) | opportunistic — only for areas the stage-2 scan surfaced AND a relevant canon skill exists | the most relevant remaining skills per area (`bitrix-events`, `bitrix-background-jobs`, `bitrix-logger`, `bitrix-caching`, …) — picked by relevance, never by catalog sweep | 2–4 key invariants per area, matched to what the scan found (events found → event model; agents found → registration/idempotency; logging found → PSR-3 usage) |
    </tier_table>

    - Modules are checked individually: a per-module verdict (conformant / `DEV-<n>`), never one
      aggregate judgment.
    - Bounded: one canon skill per area, key invariants only. Large projects: fan out Tier-1 areas
      to `explore` subagents (one per area) and merge the results.
    - Fallback (no canon skills installed, or none applicable): skip the comparison, keep the
      facts-only analysis, and write in section 11: "Canon deviation register not produced —
      canon skills unavailable/applicable." `bitrix-rules-create-global` then proceeds from facts
      alone, as before this stage existed.

    <output>DEV-<n> deviation register draft (tier + canon rule + observed fact + evidence + scope) — or the explicit "not produced" note</output>
  </stage>

  <stage id="4" name="Git History" required="true">
    Read the repository's git log in read-only mode:
    - Branches: which exist (`main`/`master`/`develop`/`dev`)? Are feature branches used?
    - Commit style: conventional commits or freeform? Sample 10 recent messages.
    - Release process: tags? release branches? `CHANGELOG.md`?
    - PR/code-review process: infer from merge commits / `--no-ff` merges; note if absent.

    <output>Provide Git process findings</output>
  </stage>

  <stage id="5" name="Write codebase-analysis.md" required="true">
    Write the document to `$project-path/.tmp/codebase-analysis.md`,
    with this exact structure:

    ```markdown
    # Codebase Analysis: <Project Name>

    > Date: YYYY-MM-DD · Analysis: <skill bitrix-prime-codebase> · Path: <project-path>

    ## 1. Overview & Stack
    Briefly: project version/type, PHP, key modules, vendor.

    ## 2. Project Structure
    2-3 level tree with one-line descriptions. Note what's in /bitrix/ and what's in /local/.

    ## 3. ORM & Database Operations
    What is actually used (D7 / CIBlockElement / raw SQL), where, with examples (file:line).

    ## 4. Migrations
    Present/absent, tool, naming convention, location.

    ## 5. Event Handlers
    Where they are registered, examples (file:line), naming convention.

    ## 6. Agents
    Where registered, scheduling approach, protection against re-execution.

    ## 7. Code Style (facts)
    Actual style: strict_types, naming, indentation, PHPDoc, PSR compliance.
    ⚠️ No recommendations — only observed facts with examples.

    ## 8. Component Templates
    "Dumb" or containing business logic? Complex or simple? Examples.

    ## 9. Git Workflow
    Branches, commits, tags, PRs (or lack thereof).

    ## 10. Seams
    List of inconsistencies and gaps: where conventions are missing, conflict, or diverge.
    (This is the most valuable part for the team — each line is a potential task.)

    ## 11. Canon Deviations
    Numbered `DEV-<n>` register from the Canon Scan (stage 3): every divergence of observed
    practice from hub canon skills. Each entry: tier (1 = structure/modules/.settings/database,
    2 = controllers/routing/components, 3 = other canons), canon rule reference (skill → rule),
    observed practice, `file:line` evidence, affected scope. Neutral facts only — no resolutions,
    no recommendations. If canon skills were unavailable or none applicable, write the explicit
    fallback note instead of the register.

    ## 12. Summary for AGENTS.md Rules
    5-10 rules that MUST be included in AGENTS.md (the most critical facts from sections 3-9).
    ```

    <checkpoint>The document contains all 12 sections with the exact headers above</checkpoint>
  </stage>
</workflow>

<delegation>
  <route to="explore subagents" when="the project is large — fan-out, one subagent per area (ORM, events/agents, components, style, git)" />
  Large projects can be routed to the `explore` subagents as specified above.
  Merge their findings into the single `codebase-analysis.md`.
</delegation>

<output_format>
  Produce one file: `$project-path/.tmp/codebase-analysis.md`,  with sections 1-12 exactly as specified
  in stage 5. Do NOT create or modify any other project files.
</output_format>

<notes>
  - **Read-only:** Write only `codebase-analysis.md`; do not touch any source file.
  - **Large repos:** Fan-out with `explore` subagents is allowed to keep the analysis bounded and fast.
</notes>

## Checklist

- [ ] All 12 sections present with the exact headers from stage 5.
- [ ] Sections 3–9 carry `file:line` citations of real repo paths — no fabricated examples.
- [ ] At least 3 citations in the ORM section; at least 1 in every other evidence section.
- [ ] Sections 3–9 contain observations only — recommendations live in Seams (section 10).
- [ ] Inconsistencies documented as variance, nothing smoothed over; "Not found" stated explicitly.
- [ ] Section 10 (Seams) non-empty; section 12 lists 5–10 prioritized rules.
- [ ] Canon Scan executed with budget discipline: Tier-1 canon per module and per top-level area; Tier-2 for existing areas; Tier-3 by relevance only — no catalog sweep; fallback noted when canon unavailable.
- [ ] Section 11 (Canon Deviations): every `DEV-<n>` carries tier, canon reference, observed fact, `file:line` evidence, and scope; no resolutions or recommendations; fallback note present when the register was not produced.
- [ ] Only `codebase-analysis.md` was written — no source file created or modified.
