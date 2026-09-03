---
name: bitrix-rules-create-global
description: Set up a 1C-Bitrix (on-premise) project's global rules — a lean root `AGENTS.md` plus rule files in `.agents/rules/core/`. Greenfield mode copies best-practice templates from `references/`; Brownfield mode turns a `bitrix-prime-codebase` analysis into rules backed by codebase evidence. Applied when initializing a Bitrix project, onboarding a developer, or replacing a generic init output. Key terms — AGENTS.md, rules, init, onboarding, Greenfield, Brownfield.
---

# Bitrix Rules Create: Global Rules for a 1C-Bitrix (On-Premise) Project

<role_definition>
  You are setting up the global rules layer for a 1C-Bitrix (on-premise) project.
  Your output is a lean, always-on root `AGENTS.md` plus detailed rule files
  in `.agents/rules/core/` — the canonical source of truth that both AI agents
  and new developers follow when working in this repository.
</role_definition>

<context>
  <system_context>
    1C-Bitrix on-premise is a massive, opinionated ecosystem. Even a "new" project
    inherits the entire installed core (`/bitrix/`). Development always means
    **extending** or **customizing** an existing system — there is no "pure"
    Greenfield in the traditional sense.
  </system_context>

  <domain_context>
    1C-Bitrix on-premise · PHP · D7 ORM (`\Bitrix\Main\ORM`) · legacy `CIBlockElement` API ·
    `CAgent` background tasks · event handlers (`AddEventHandler`) · component templates ·
    `/local/` user-code directory · vendor conventions (default: `{{VENDOR_NAME}}`).
  </domain_context>

  <task_context>
    Two modes produce the same output shape; only the source of truth differs:

    - **Greenfield** (no analysis passed): copy pre-defined best-practice templates
      from this skill's embedded `references/` — **prescribed** standards.
    - **Brownfield** (analysis passed): document the **actual** patterns of an existing
      codebase, backing every rule with `file:line` evidence — **observed** facts.
  </task_context>
</context>

<critical_rules enforcement="strict">
  <rule id="protect-existing-rules" scope="all-modes">
    If a rules file already exists, back it up first (e.g. `AGENTS.md.bak`)
    so existing content is never overwritten without a trace.
  </rule>

  <rule id="greenfield-verbatim" scope="greenfield">
    Copy templates verbatim from `references/`. Replace ONLY `{{PROJECT_NAME}}`,
    `{{TEAM_NAME}}`, `{{CURRENT_YEAR}}`, the vendor placeholders
    (`{{VENDOR_NAME}}`, `{{vendor_name}}`) and `{{db_prefix}}` — using the values
    confirmed in stage 2.
    Do NOT invent new rules during Greenfield; the team can review and adjust them
    in the first sprint.
  </rule>

  <rule id="brownfield-evidence" scope="brownfield">
    Every rule must be backed by a citation from the analysis document — a file PATH
    (e.g. `/local/lib/Model/Order/OrderExternalTable.php`), a class name
    (`OrderExternalTable`, `BaseComponent`), or a code symbol (method, function,
    constant) such as `EventManager::addEventHandler` or `runImageConvertAgent()`.
    NEVER cite line numbers (e.g. `:125`, `:14-19`) — they go stale after the
    first edit and force maintenance. If a pattern is inconsistent, document
    the variance — do not smooth it over.
  </rule>

  <rule id="brownfield-no-inventory" scope="brownfield">
    Rules express CONVENTIONS and DECISIONS, not statistics. Never include:
    - File counts (e.g. "997 matches in 200 files")
    - Match counts or percentages (e.g. "128 vs 71 files", "90% of components")
    - Line numbers (e.g. `:125`, `:14-19`)
    - Inventory tables with per-zone counts
    These numbers go stale immediately and add no actionable value. State the
    PATTERN instead: "Legacy CIBlockElement dominates; D7 is used in /local/lib/
    for new code — see `OrderExternalTable`, `BasketService::getList()`."
    Exact counts live in `.tmp/codebase-analysis.md`, not in `core/` rules.
  </rule>

  <rule id="english-only" scope="all-modes">
    **Write `AGENTS.md` and every `.agents/rules/core/*.md` ground rule in English** — Greenfield
    and Brownfield alike. Code identifiers and text quoted from the codebase stay verbatim.
  </rule>

  <rule id="no-provenance-banners" scope="brownfield">
    **NEVER attribute generated artifacts with provenance banners** such as "Generated: 2026-08-16 ·
    Mode: Brownfield (based on `codebase-analysis.md`) · Vendor: FirstBit · DB prefix: `fbit_`".
    Files carry rules only; mode, vendor, and prefix context go in the chat report.
  </rule>

  <rule id="template-conformance" scope="all-modes">
    **Root `AGENTS.md` follows the `references/AGENTS.md.template` structure in both routes** — Project
    Map, Vendor Convention, Ground Rules, Working Principles, Commands; Brownfield fills them with observed facts.
  </rule>

  <rule id="line-length" scope="all-modes">
    **Wrap generated artifact text at 120 characters per line (soft limit); NEVER exceed 140.**
    Unbreakable URLs and code identifiers may cross the soft limit — rewrap the sentence around them.
  </rule>

  <rule id="no-filler" scope="all-modes">
    No generic filler or slogans. Each rule should cause a different outcome if removed.
    Keep the rules lean enough to fit in context without being ignored.
  </rule>
</critical_rules>

<workflow>
  <stage id="1" name="Determine Mode" required="true">
    Read the single optional input — the path to a `codebase-analysis.md` document:

    <decision>
      Select the route whose condition matches the input:
      <route to="Greenfield" when="path is empty — copy templates from references/" />
      <route to="Brownfield" when="path provided — extract patterns from the analysis document" />
    </decision>

    <checkpoint>Mode determined</checkpoint>

    Determine which rules file the project uses:
    - **`AGENTS.md`** (RECOMMENDED, open standard): https://agents.md
    - **`CLAUDE.md`** (Claude Code native): https://code.claude.com/docs/en/memory

    If both exist, shared content lives in `AGENTS.md` and `CLAUDE.md` becomes a single
    line — `@AGENTS.md`. If neither exists, prefer `AGENTS.md` for multi-tool setups.
    Back up an existing rules file before overwriting (rule `protect-existing-rules`).
  </stage>

  <stage id="2" name="Confirm Vendor" required="true">
    Before composing any rule, check the project's `AGENTS.md` and other rule files for a
    vendor name; if none is defined there, ask the user:
    **"What vendor name should be used for this project?"**

    <decision>
      Select one route based on the answer:
      <route to="Use the vendor named in AGENTS.md or other project rules" when="the rules define one" />
      <route to="Use the user's answer" when="the user names a vendor (e.g. Acme, MyCompany)" />
      <route to="Ask again" when="neither the rules nor the user names a vendor — propose options and let the user pick" />
    </decision>

    The confirmed answer drives every vendor token in the generated rules:
    - `{{VENDOR_NAME}}` — the vendor as written in namespaces, StudlyCaps (e.g. `VendorName\`)
    - `{{vendor_name}}` — the vendor in lowercase, for module and CSS prefixes
      (e.g. `vendorname.`, `vendorname-`)

    Also confirm the DB table prefix — check `AGENTS.md` and other rule files first; if none
    defines one, ask the user:
    **"What prefix should be used for DB tables? (no more than 5 characters, derived from the
    vendor name — e.g. `acme` for `Acme`)"**

    <decision>
      <route to="Use the prefix from AGENTS.md or other project rules" when="the rules define one" />
      <route to="Use the user's answer" when="the user names a prefix (e.g. `acme_`, `myco_`)" />
      <route to="Recommend a prefix derived from the vendor name and confirm it with the user" when="neither the rules nor the user names one — derive it (e.g. `Acme` → `acme`), max 5 characters" />
    </decision>

    - `{{db_prefix}}` — the DB table prefix, lowercase, no more than 5 characters (e.g. `acme_`)

    <checkpoint>Vendor confirmed — {{VENDOR_NAME}} and {{vendor_name}} are known, {{db_prefix}} confirmed before any file is written</checkpoint>
  </stage>

  <stage id="3" name="Greenfield: Copy Templates" required="false">
    <skip_if>an analysis path is provided → skip (Brownfield mode)</skip_if>

    <step id="3.1" name="Copy" required="true">
      The templates are real files in this skill's `references/`. Copy them — do not recreate:

      ```
      references/
      ├── AGENTS.md.template  → $project-path/AGENTS.md
      └── core/
          ├── core-interaction.md → .agents/rules/core/core-interaction.md
          ├── database.md      → .agents/rules/core/database.md
          ├── architecture.md  → .agents/rules/core/architecture.md
          ├── code-style.md    → .agents/rules/core/code-style.md
          └── gitflow.md       → .agents/rules/core/gitflow.md
      ```
    </step>

    <step id="3.2" name="Customize" required="true">
      Do only this, keep the rest verbatim:
      1. Replace `{{PROJECT_NAME}}` in `AGENTS.md` (from `composer.json`, the site name, or the working directory).
      2. Replace `{{TEAM_NAME}}` and `{{CURRENT_YEAR}}` where present.
      3. Replace the vendor placeholders with the vendor confirmed in stage 2:
         - `{{VENDOR_NAME}}` — StudlyCaps form for namespaces (e.g. `VendorName\`)
         - `{{vendor_name}}` — lowercase form for module prefix and CSS prefix
            (e.g. `vendorname.`, `vendorname-`)
      4. Replace `{{db_prefix}}` in `AGENTS.md` and `core/database.md` with the DB table prefix
         confirmed in stage 2 (e.g. `acme_`). If the user had no preference, use the derived
         recommendation (max 5 characters) after the user confirms it.
      There is no default vendor: always replace the `{{VENDOR_NAME}}` / `{{vendor_name}}`
      tokens with the confirmed values — the templates leave them unexpanded.
    </step>

    <output>
      ✅ Greenfield mode: installed Bitrix best-practice rules from references/.

      Created:
        -  $project-path/AGENTS.md
        - .agents/rules/core/core-interaction.md
        - .agents/rules/core/database.md
        - .agents/rules/core/architecture.md
        - .agents/rules/core/code-style.md
        - .agents/rules/core/gitflow.md
    </output>
  </stage>

  <stage id="4" name="Brownfield: Extract Patterns" required="false">
    <skip_if>no analysis path → skip (Greenfield mode)</skip_if>

    <step id="4.1" name="Read Analysis" required="true">
      Read the analysis document (produced by `bitrix-prime-codebase`).
      It contains findings with `file:line` citations.
    </step>

    <step id="4.2" name="Extract 8 Areas" required="true">
      Convert each finding into a CONVENTION rule (not a statistic). Each rule
      may anchor on 1-2 representative file PATHS, class names, or code symbols
      (method/function/constant) — never line numbers and never inventory counts.
      1. **Directory structure** — where do components, templates, and modules
         actually live? `/bitrix/` or `/local/`? Reference the top-level directory.
      2. **ORM usage** — D7 ORM, `CIBlockElement`, or a mix? Which zones use
         which? Name 1-2 representative classes or file paths as anchors
         (e.g. `OrderExternalTable`, `/local/lib/Service/HlBlock/`).
      3. **Migrations** — does a `migrations` folder / `kit.migrator` /
         `sprint.migrator` exist? Note absence explicitly.
      4. **Event handlers** — registered in `init.php`, a module `.events.php`,
         or a D7 registry? Name the registration file or class
         (e.g. `EventManager::addEventHandler`), not individual handler lines.
      5. **Agents** — where is `CAgent::AddAgent` registered? Is there a guard
         pattern (e.g. `CAgent::GetList` check)? Name the agent function(s).
      6. **Coding style** — is `declare(strict_types=1)` used? What naming
         conventions? State the convention; do not count files.
      7. **Component templates** — is `template.php` "dumb" or does it contain
         business logic? Name a representative component as the anti-example.
      8. **Git history** — branches, PRs, release process. Note absence
         explicitly.
    </step>

    <step id="4.3" name="Report Seams" required="true">
      List seams — gaps where conventions are missing or inconsistent
      (e.g. "No migration system found", "legacy `CIBlockElement` in `/local/components/old.list/`
      while new code uses D7"). These are the highest-value findings for the team.
    </step>

    <output>
      ✅ Brownfield mode: generated rules from analysis of the existing codebase.

      Created:
        - <project-root>/AGENTS.md (template structure, observed content)
        - .agents/rules/core/core-interaction.md
        - .agents/rules/core/database.md
        - .agents/rules/core/architecture.md
        - .agents/rules/core/code-style.md
        - .agents/rules/core/gitflow.md

      ⚠️ Seams identified:
        - No migration system found. Consider implementing one.
        - Inconsistent ORM usage: D7 in /local/modules/, CIBlockElement in /local/components/.

      Summary: rules reflect the current state of the codebase. Update them as the project evolves.
    </output>
  </stage>

  <stage id="5" name="Verify" required="true">
  Run the checklist at the end of this file before finishing.

    <checkpoint>All checks pass → report to the user</checkpoint>
  </stage>
</workflow>

<output_format>
  ## Root `AGENTS.md` — the always-on, lean entry point
  Both routes follow the `references/AGENTS.md.template` structure:
  1. **Project Map** — a paragraph about the project + a directory tree with one-line descriptions.
  2. **Vendor Convention** — namespace/module/CSS prefixes and the DB prefix (template text in Greenfield; observed values with citations in Brownfield).
  3. **Ground Rules** — one `@.agents/rules/core/<file>.md` link per rule file, with its scope.
  4. **Working Principles** — plan before non-trivial changes, clarify ambiguity, test in staging,
     fail fast, keep scope tight.
  5. **Commands** — the actual CLI commands the agent should run
     (e.g. the migration CLI — see `bitrix-sprint-migration` — and the linter;
     verify both against the project).

  ## `.agents/rules/core/*.md` — the detailed, project-specific source of truth
  | File              | Content | Greenfield (from template) | Brownfield (from analysis) |
  | :---------------- | :------ | :------------------------- | :------------------------- |
  | `core-interaction.md` | Core framework interaction: Loader, globals, events, agents, components, forms/security | "Always use `\Bitrix\Main\Loader`; register handlers in `init.php`; agents idempotent" | "`Loader::includeModule` used consistently; handlers registered via `EventManager::addEventHandler` in `/local/lib/Event/`" |
  | `database.md`     | D7 ORM, direct-SQL exceptions, migrations, table naming | "Use D7 ORM exclusively; direct SQL only via `Application::getConnection()`" | "D7 for new modules (`OrderExternalTable`, `BasketService::getList()`); legacy `CIBlockElement` in `/local/components/`" |
  | `architecture.md` | Project structure and modularity | "All custom code in `/local/`; new functionality as a module" | "Components split between `/bitrix/` and `/local/`; new ones go to `/local/components/{{vendor_name}}/`" |
  | `code-style.md`   | PHP/JS/CSS standards (PSR-12 + Bitrix specifics) | "Strict typing required; PHPDoc on all methods" | "`declare(strict_types=1)` absent; mixed `snake_case`/`camelCase` naming" |
  | `gitflow.md`      | Branch strategy, commits, review, releases | "Git Flow; `develop` integration branch; feature branches" | "Only `master` and `dev` exist; no formal PR process" |

  Optional files MAY be added as needed: `components.md`, `agents.md`, `events.md`, `security.md`.
</output_format>

<notes>
  - **Evolve the rules:** revisit after major milestones and run a drift check (`rules-check-drift` or manual comparison)
    to ensure code hasn't diverged.
  - **Large repositories:** for massive projects, run `bitrix-prime-codebase` with fan-out to produce a comprehensive `.tmp/codebase-analysis.md`.
  - **Team onboarding:** these rules are not just for AI agents — they are the canonical source of truth for new developers. Commit them to the repository.
</notes>

## Checklist

- [ ] Existing rules file backed up (e.g. `AGENTS.md.bak`) before any overwrite.
- [ ] Vendor and DB prefix confirmed with the user before any file was written.
- [ ] All six files created: root `AGENTS.md` + five `.agents/rules/core/*.md`.
- [ ] Greenfield: templates copied verbatim — only the confirmed placeholders replaced.
- [ ] Brownfield: every rule anchored to a file path, class, or code symbol — no line numbers, no inventory counts.
- [ ] All generated files written in English (both modes).
- [ ] No provenance banners ("Generated: ... · Mode: ...") inside generated files.
- [ ] Root `AGENTS.md` matches the `references/AGENTS.md.template` section structure.
- [ ] Generated lines wrapped: soft 120, hard 140 characters.
- [ ] Seams reported when conventions are missing or inconsistent.
- [ ] No filler — every rule changes the outcome if removed.
