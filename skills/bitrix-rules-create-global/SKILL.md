---
name: bitrix-rules-create-global
description: "Use when initializing a Bitrix project, onboarding, or replacing a generic init. Creates a lean root AGENTS.md plus .agents/rules/core/ files: Greenfield copies templates from references/, Brownfield turns a bitrix-prime-codebase analysis into evidence-backed rules and resolves canon deviations with the user. Key terms — AGENTS.md, Greenfield, Brownfield, canon deviations, DEV."
metadata:
  type: workflow
---

# Bitrix Rules Create: Global Rules for a 1C-Bitrix (On-Premise) Project

<role_definition>
  Purpose: set up the global rules layer of a 1C-Bitrix (on-premise) project — a lean,
  always-on root `AGENTS.md` plus detailed rule files in `.agents/rules/core/` — the
  canonical source of truth that AI agents and new developers follow in this repository.

  Goal: a root file that works as a **project reference** (acquaintance + navigation +
  constraints), comparable in shape and density to this skill's quality anchor —
  `references/AGENTS.md.template` (≈2 400 tokens): every rule needed by an agent of any
  specialization, dense normative lines, ≤ 2 navigation hops, zero meta-text.

  Doctrine — **AGENTS ≠ system prompt**: the connecting agent already carries its own
  system instructions; the root file acquaints it with the project and routes it to deeper
  layers. Working procedures and behavior principles live in the agent's own instructions
  and in rule/skill files (Routing) — they stay out of the root file.
</role_definition>

<context>
  <system_context>
    Even a "new" 1C-Bitrix project inherits the entire installed core (`/bitrix/`); development
    always means **extending** or **customizing** an existing system — there is no "pure" Greenfield.
  </system_context>

  <domain_context>
    1C-Bitrix on-premise · PHP · D7 ORM · legacy `CIBlockElement` · `CAgent` · event handlers ·
    component templates · `/local/` user code · vendor conventions (confirmed in stage 2).
  </domain_context>

  <task_context>
    Two modes produce the same output shape; only the source of truth differs:

    - **Greenfield** (no analysis passed): copy pre-defined best-practice templates
      from this skill's embedded `references/` — **prescribed** standards, verbatim.
    - **Brownfield** (analysis passed): document the **actual** patterns of an existing
      codebase, backing every rule with path/class/symbol evidence — **observed** facts.
      Canon deviations from the analysis (`DEV-<n>`) are resolved with the user before
      rules are composed (rule `deviation-resolution`).
      The template is the backbone; significant insights extend it per rule
      `brownfield-adaptive`.
  </task_context>
</context>

<critical_rules enforcement="strict">
  <rule id="protect-existing-rules" scope="all-modes">
    If a rules file already exists, back it up first (e.g. `AGENTS.md.bak` `CLAUDE.md.bak`)
    so existing content is never overwritten without a trace.
  </rule>

  <rule id="agents-not-system-prompt" scope="all-modes">
    The root `AGENTS.md` is a **project reference**: facts, conventions, navigation.
    **NEVER write directive working procedures or agent-behavior principles into it**
    ("always X before Y", "triage every task as...", step-by-step dev procedures) — they
    pull a coordinator or researcher agent out of its role. State conventions descriptively
    ("Error-handling convention: explicit messages; silent swallowing is a defect");
    procedures live in the agent's own instructions and in rule/skill files (Routing).
    The file also carries **no meta-text about its own purpose** ("this file informs…",
    "loaded in every session…", "How to fill") — harnesses load it; it explains itself to no one.
  </rule>

  <rule id="greenfield-verbatim" scope="greenfield">
    Copy templates verbatim from `references/`. Replace ONLY the placeholders
    confirmed in stage 2 — the canonical placeholder list lives there.
    Drop the leading draft meta comment (`<!-- AGENTS.draft ... -->`) — version bookkeeping
    of the template, meaningless in a project file. Everything else stays byte-for-byte.
    Do NOT invent new rules during Greenfield; the team can review and adjust them
    in the first sprint.
  </rule>

  <rule id="brownfield-evidence" scope="brownfield">
    Every rule must be backed by a citation from the analysis document — a file PATH
    (`/local/lib/Model/Order/OrderExternalTable.php`), a class name (`OrderExternalTable`),
    or a code symbol (`EventManager::addEventHandler`, `runImageConvertAgent()`).
    NEVER cite line numbers (`:125`) — they go stale after the first edit.
    If a pattern is inconsistent, document the variance — do not smooth it over.
  </rule>

  <rule id="brownfield-no-inventory" scope="brownfield">
    Rules express CONVENTIONS and DECISIONS, not statistics. Never include file counts
    ("997 matches in 200 files"), match counts or percentages ("128 vs 71", "90% of
    components"), line numbers, or inventory tables. State the PATTERN instead:
    "Legacy CIBlockElement dominates; D7 in /local/lib/ for new code — see
    `OrderExternalTable`, `BasketService::getList()`." Exact counts live in
    `.tmp/codebase-analysis.md`, not in `core/` rules. Tree and placement comments follow
    the same ban — state purpose, never counts ("53 component overrides" in a tree comment
    is a defect: it goes stale and it is statistics).
  </rule>

  <rule id="brownfield-adaptive" scope="brownfield">
    The template is the BASELINE, not a cage. When the analysis yields significant insights,
    adapt the root `AGENTS.md` through two mechanisms:
    1. **Broaden a template section** — extra bullets, rows, or a subsection of observed
       facts (e.g. a deployment-layout block under Environment & tech stack, an integration
       map for an API-heavy project).
    2. **Add a section** — for a significant project-specific concern the template has no
       home for (e.g. an integration map section).
    A significant insight = an observed convention, constraint, or seam that changes agent
    behavior for any specialization ("remove it — would behavior change? no → cut it").
    Template sections stay recognizable; default heading order holds unless a project
    concern justifies a different arrangement — note every deviation in the chat report.
    Extras link to Tier-1 files instead of duplicating them; `brownfield-evidence` and
    `brownfield-no-inventory` apply to every addition.
  </rule>

  <rule id="deviation-resolution" scope="brownfield">
    Canon deviations registered in the analysis (`DEV-<n>`, section 11 "Canon Deviations")
    are resolved BEFORE any rule is composed — never silently:
    - **Tier-1 and Tier-2 deviations → STOP and ask the user.** Present each deviation with its
      canon rule, the observed practice, and resolution options; a silent pick is a defect.
    - **Tier-3 deviations → agent discretion, guided by OVER-ASKING:** insignificant → decide
      yourself (default: canon for new code, existing practice noted as legacy) and log the
      decision in the chat report; plausibly significant (wide impact, security, breaks tooling)
      → elevate into the user question batch.
    - **Empty register** (the analysis states the fallback note "register not produced — canon
      skills unavailable/applicable") → no questions about deviations: compose rules from facts
      alone, exactly as before the register existed.
    Encode every confirmed decision into the rules themselves: a convention rule in the matching
    core file (canon reference + legacy carve-out + anchors), and — for global source-priority
    decisions — the "Standards & conflicts" section in `architecture.md` plus an `AGENTS.md`
    pointer. A canon consciously overridden by the user ("practice is the standard") is recorded
    WITH the canon skill name, so future agents see a deliberate decision, not an accident.
  </rule>

  <rule id="english-only" scope="all-modes">
    **Write `AGENTS.md` and every `.agents/rules/core/*.md` ground rule in English** — Greenfield
    and Brownfield alike. Code identifiers and text quoted from the codebase stay verbatim.
  </rule>

  <rule id="no-provenance-banners" scope="all-modes">
    **NEVER attribute generated artifacts with provenance banners** ("Generated: ... · Mode: ... ·
    Vendor: ... · DB prefix: ..."). Files carry rules only; that context goes in the chat report.
  </rule>

  <rule id="placeholder-discipline" scope="all-modes">
    Two placeholder kinds (hub template convention):
    - `{{var}}` — a project onboarding entity filled once (canonical list in stage 2):
      replaced everywhere at generation; **zero `{{` may remain in a finished file**.
    - `<...>` — universal patterns that live in the file always, after filling too
      (kernel paths `bitrix/modules/<module>/lib/...`, command args `<file>`, `<path>`,
      name templates `<extension>`, `<table_name>`, `<skill-name>`).
    No fill-instructions, example hints, or "fill at setup" notes accompany either kind —
    the finished file reads as a normal AGENTS.md.
  </rule>

  <rule id="template-conformance" scope="all-modes">
    **Greenfield: root `AGENTS.md` is `references/AGENTS.md.template` verbatim** (minus the
    draft meta comment) with confirmed placeholders replaced.
    **Brownfield: the template is the quality baseline** — its section set and density are
    the target; observed content fills it and significant insights extend it per rule
    `brownfield-adaptive`.
    Either way the finished file reads as a normal AGENTS.md — no scaffolding, no meta-text
    about its own purpose.
  </rule>

  <rule id="line-length" scope="all-modes">
    **Wrap generated artifact text at 120 characters per line (soft limit).** Prose paragraphs
    stay wrapped; dense single-line rule bullets and table rows may exceed the soft limit when
    mirroring the `references/AGENTS.md.template` density style (one rule per line) — hard cap
    400 characters. Unbreakable URLs and code identifiers may cross the soft limit.
  </rule>

  <rule id="no-filler" scope="all-modes">
    No generic filler or slogans. Each rule should cause a different outcome if removed —
    keep the rules lean enough to fit in context without being ignored.
  </rule>
</critical_rules>

<quality_criteria name="acceptance bar for the generated root AGENTS.md">
  Both routes are accepted only when ALL criteria pass (adapted from the hub AGENTS-template
  specification; the quality anchor is `references/AGENTS.md.template`):

  **Content**

  | # | Criterion | Check |
  |---|---|---|
  | QC1 | Universality — every rule is needed by an agent of any specialization; specialist content lives only behind Routing links | Each rule passes "would a coordinator / researcher / coder alike need it?" |
  | QC2 | Density — normative lines (rules, facts, routing links) dominate prose | Line test: "remove the line — does agent behavior change? no → cut" |
  | QC3 | Verifiability — descriptive, checkable conventions; navigation rows carry Use When / Load When triggers; rules never contradict each other | Read rules pairwise; confirm triggers present |
  | QC4 | Single source of truth — the root file references Tier-1 files and skills, never duplicates them | Every link target exists; grep for duplicated rule bodies |
  | QC5 | Fact discipline — every path/identifier/version/count confirmed against project source; absence claims follow a positive search | Trace each factual claim to project evidence; unverified versions and counts are dropped |

  **Form**

  | # | Criterion | Check |
  |---|---|---|
  | QC6 | Size — root file stays lean: target ≈ ≤ 3 000 tokens, hard cap 10 000 (`tokens ≈ chars / 4`) | `wc -m AGENTS.md`; every section passes "does every agent need this every session?" |
  | QC7 | Navigation — task → document in ≤ 2 hops (AGENTS → Tier 1/2 → section); structure predictable across projects | Template section set recognizable; anchor links resolve |
  | QC8 | Cleanliness — all `{{var}}` replaced, `<...>` patterns preserved; free of meta-text, provenance banners, fill instructions, draft bookkeeping | Grep audits per verification method |

  **Effect**

  | # | Criterion | Check |
  |---|---|---|
  | QC9 | Agent-neutrality — no directive working procedures or behavior principles in the root file | Directive-pattern scan per verification method |
  | QC10 | Maintainability — module-registry and tree upkeep rules present; LastDrift line set | Confirm upkeep bullets + `> LastDrift:` value |
  | QC11 | Evidence spot-check (Brownfield) — 3 sampled conventions each trace to an analysis-backed anchor | Pick 3 claims; find their anchor in the analysis doc |

  A full blind-test grading (protocol per `bitrix-skill-eval`) is out of the skill's runtime
  scope; it applies when the OUTPUT itself is being graded as a hub artifact.
</quality_criteria>

<verification_method name="how to check the result meets quality_criteria">
  Run on the finished root `AGENTS.md` (and core files where noted); report results in chat:

  1. **Size** — `wc -m <AGENTS.md>`; `tokens ≈ chars / 4`. Compare against QC6 budget;
     report the actual number. Brownfield additions that push size must each pass
     "needed by every agent, every session?".
  2. **Placeholder audit** — `grep -n '{{' AGENTS.md .agents/rules/core/*.md` → expect
     zero matches (`{{last_drift}}` included: it is set to the install date at generation).
     `<...>` patterns must remain.
  3. **Meta-text audit** — scan for self-description and fill instructions:
     `grep -niE 'how to fill|fill at setup|generated:|this file (informs|describes|explains|contains the rules)'`
     → expect zero. Functional file mentions (priority chain, Language conventions) are
     legitimate; purpose-descriptions are defects.
  4. **Link integrity** — every `@.agents/rules/core/*.md` target exists on disk; every
     Tier-2 skill name exists in `.agents/skills/` or the hub catalog; in-file anchor
     links resolve.
  5. **Agent-neutrality scan** — grep the root file for imperative procedure patterns
     ("always do", "never do", "before coding", "triage", "step 1") → expect zero directive
     procedures; descriptive convention bullets are fine.
  6. **Evidence check** (Brownfield) — every observed claim in the root file and core rules
     is anchored to a path, class, or symbol; **no line numbers, no counts**.
  7. **Contradiction check** — read conventions pairwise; a conflict is resolved so the
     most specific file refines the general one.
  8. **Numbers & versions audit** — every numeric count ("53 component overrides") and every
     version string ("SM_VERSION 26.250.100") in generated files traces to a verifiable source
     (counted live in the repo, or cited to a file); anything unverifiable or drift-prone is
     dropped — purpose replaces the number. Grep trigger: `[0-9]+ (component|file|match|override|auth)`.
  9. **Density spot-check** — sample two sections; cut every line failing the line test.
  10. **Deviation resolution** (Brownfield) — every Tier-1/Tier-2 `DEV-<n>` has a recorded user
      decision; each decision surfaces in the rules as canon reference + legacy carve-out (or a
      named override with the canon skill); Tier-3 decisions are listed in the chat report.
      Empty register → no deviation questions were asked.
</verification_method>

<workflow>
  <stage id="1" name="Determine Mode" required="true">
    Read the single optional input — the path to a `codebase-analysis.md` document:

    <decision>
      Select the route whose condition matches the input:
      <route to="Greenfield" when="path is empty — copy templates from references/" />
      <route to="Brownfield" when="path provided — extract patterns from the analysis document" />
    </decision>

    <checkpoint>Mode determined</checkpoint>

    Determine which rules file the project uses: **`AGENTS.md`** (RECOMMENDED, open standard —
    https://agents.md) or **`CLAUDE.md`** (Claude Code native). If both exist, shared content
    lives in `AGENTS.md` and `CLAUDE.md` becomes a single line — `@AGENTS.md`. Back up an
    existing rules file before overwriting (rule `protect-existing-rules`).
  </stage>

  <stage id="2" name="Confirm Vendor and Project Facts" required="true">
    Before composing any rule, check the project's `AGENTS.md` and other rule files for a
    vendor name; if none is defined there, ask the user:
    **"What vendor name should be used for this project?"**

    <decision>
      Select one route based on the answer:
      <route to="Use the vendor named in AGENTS.md or other project rules" when="the rules define one" />
      <route to="Use the user's answer" when="the user names a vendor (e.g. Acme, MyCompany)" />
      <route to="Ask again" when="neither the rules nor the user names a vendor — propose options and let the user pick" />
    </decision>

    The confirmed answer drives every vendor token: `{{VENDOR_NAME}}` — StudlyCaps
    namespace form (e.g. `VendorName\`); `{{vendor_name}}` — lowercase form for module
    and CSS prefixes (e.g. `vendorname.`, `vendorname-`).

    Also confirm the DB table prefix — check `AGENTS.md` and other rule files first; if none
    defines one, ask: **"What prefix should be used for DB tables? (max 5 characters,
    derived from the vendor name — e.g. `acme` for `Acme`)"**

    <decision>
      <route to="Use the prefix from AGENTS.md or other project rules" when="the rules define one" />
      <route to="Use the user's answer" when="the user names a prefix (e.g. `acme_`, `myco_`)" />
      <route to="Recommend a prefix derived from the vendor name and confirm it with the user" when="neither the rules nor the user names one — derive it (e.g. `Acme` → `acme`), max 5 characters" />
    </decision>

    - `{{db_prefix}}` — the DB table prefix, lowercase, no more than 5 characters (e.g. `acme_`)

    Then confirm the remaining project facts — first from `composer.json` / `local/composer.json`
    / `.settings.php` / `local/modules/`, asking the user only for what the project does not reveal.
    This stage is the canonical placeholder list for every generated artifact:
    - `{{PROJECT_NAME}}` — project title; `{{PROJECT_TYPE}}` — corporate portal / CRM / shop
    - `{{PHP_VERSION}}` — baseline from `composer.json` or runtime; `{{DB_ENGINE}}` — MySQL / PostgreSQL
    - `{{TEST_TOOLING}}` — from `composer.json` `require-dev` (e.g. PHPUnit); state absence explicitly
    - `{{COMPOSER_MERGE}}` — module manifest merge mechanism (e.g. `wikimedia/composer-merge-plugin`)
    - `{{MODULE_DESCRIPTION}}` — one line per module in the registry, from `local/modules/`
    - `{{REPLY_LANGUAGE}}` — default agent reply language; `{{ENVIRONMENT_NOTES}}` —
      staging/prod layout, deployment flow, access notes
    - `{{OTHER_TOOLING}}` — optional pinned tooling worth naming; drop the line if none
    - `{{tier1_rule_file}}` — the core rule file that holds the skill-install block
      (default `core-interaction.md`; one of the five files created in this run — the
      Tier-2 reference must never dangle); `{{last_drift}}` — drift-check timestamp,
      set to the install date at generation, maintained later by `rules-check-drift`
    - `{{TEAM_NAME}}` and `{{CURRENT_YEAR}}` — template credits, replaced where present

    <checkpoint>Vendor, DB prefix, and project facts confirmed before any file is written</checkpoint>
  </stage>

  <stage id="3" name="Greenfield: Copy Templates" required="false">
    <skip_if>an analysis path is provided → skip (Brownfield mode)</skip_if>

    <step id="3.1" name="Copy" required="true">
      The templates are real files in this skill's `references/`. Copy them — do not recreate:

      ```
      references/AGENTS.md.template        → $project-path/AGENTS.md
      references/core/core-interaction.md  → .agents/rules/core/core-interaction.md
      references/core/database.md          → .agents/rules/core/database.md
      references/core/architecture.md      → .agents/rules/core/architecture.md
      references/core/code-style.md        → .agents/rules/core/code-style.md
      references/core/gitflow.md           → .agents/rules/core/gitflow.md
      ```

      Drop the leading draft meta comment (`<!-- AGENTS.draft ... -->`) from the copied
      `AGENTS.md` — it is template version bookkeeping, per rule `greenfield-verbatim`.
    </step>

    <step id="3.2" name="Customize" required="true">
      Do only this, keep the rest verbatim:
      1. Replace every placeholder confirmed in stage 2 (the canonical list and its sources
         live there) — nothing else changes. `{{PROJECT_NAME}}` comes from `composer.json`,
         the site name, or the working directory. Set `{{last_drift}}` to the install date.
      2. There is no default vendor: always replace `{{VENDOR_NAME}}` / `{{vendor_name}}`
         tokens with the confirmed values — the templates leave them unexpanded.
      3. Append the skill-install block to `{{tier1_rule_file}}` (default
         `core-interaction.md`): the hub command `npx skills add azimuth0x28/bitrix-skills-hub --skill <skill-name>`
         plus the no-`npx` fallback (`mkdir -p /tmp/bitrix-skills-<rand>` → `git clone` the
         hub into it → `cp -r` the skill folder → `rm -rf` the clone), so the Tier-2
         reference in `AGENTS.md` resolves.
    </step>

    <output>
      ✅ Greenfield mode: installed Bitrix best-practice rules from references/.

      Created: $project-path/AGENTS.md + .agents/rules/core/
      {core-interaction,database,architecture,code-style,gitflow}.md
    </output>
  </stage>

  <stage id="4" name="Brownfield: Compose Rules from Analysis" required="false">
    <skip_if>no analysis path → skip (Greenfield mode)</skip_if>

    <step id="4.1" name="Read Analysis" required="true">
      Read the analysis document (produced by `bitrix-prime-codebase`). Probe all eight
      areas: directory structure, ORM usage, migrations, event handlers, agents, coding
      style, component templates, git history. Note absences explicitly. Read the section-11
      `DEV-<n>` canon-deviation register — it drives step 4.2.
    </step>

    <step id="4.2" name="Resolve Canon Deviations" required="true">
      Build a resolution table from the `DEV-<n>` register, grouped by domain / target core
      file — one question batch, not one question per DEV:

      | DEV | Canon | Observed | Options | Default |
      | :-- | :---- | :------- | :------ | :------ |
      | DEV-<n> | <skill> → rule | observed practice | (a) canon for new code, existing practice marked as legacy deviation · (b) practice becomes the project standard (canon consciously overridden — recorded with the canon skill name) · (c) migrate to canon | (a) |

      - Tier-1/Tier-2: ask the user and get explicit confirmation per row (bulk confirmation
        of defaults is acceptable). Record every decision — steps 4.3/4.4 consume it.
      - Tier-3: decide per rule `deviation-resolution`; log decisions in the chat report;
        suspiciously significant ones join the user batch.
      - Empty register (canon skills were unavailable/applicable in the analysis) → skip this
        step and compose rules from facts alone, as before.
      - Global source-priority decisions (e.g. "canon skills outrank existing repo code") are
        encoded as the "Standards & conflicts" section in `architecture.md` + an `AGENTS.md`
        pointer — not only as a per-domain rule.

      <checkpoint>Every Tier-1/Tier-2 DEV has a recorded user decision; Tier-3 decisions logged</checkpoint>
    </step>

    <step id="4.3" name="Fill the Template Sections" required="true">
      Convert findings into CONVENTION rules (not statistics), each anchored on 1-2
      representative file PATHS, class names, or code symbols — never line numbers:

      | Template section | Fill with observed facts |
      |---|---|
      | Project rules & constraints | Conventions as descriptive constraints: kernel vs `/local/` practice, identifier trust, secrets, error handling |
      | Project tree skeleton | The ACTUAL tree with placement comments (template skeleton is the fallback shape) |
      | Project modules | Real registry rows — `{{vendor_name}}.<module>` + a one-line description each |
      | Vendor convention | Observed namespace/module/JS prefixes and DB prefix, anchored to `composer.json`, `local/modules/` |
      | Routing — Tier 1 | The five core files created in this run; Use-When triggers reflecting project reality |
      | Routing — Tier 2 | Hub-skills list from the template as-is (universal) |
      | Tooling | Real commands verified against `composer.json` scripts / tool configs; state absence explicitly |
      | Environment & tech stack | Observed PHP (`composer.json`), DB (`.settings.php`), environment notes |

      Insights with no home in the table → extend per rule `brownfield-adaptive` (broaden a
      section or add one; keep the density test).
    </step>

    <step id="4.4" name="Generate Core Rule Files" required="true">
      Write the five `.agents/rules/core/*.md` files from the same findings — observed
      content per the output_format table, same evidence and no-inventory rules. Embed the
      confirmed DEV decisions (step 4.2) as canon reference + legacy carve-out in the
      matching file. Append the skill-install block to `{{tier1_rule_file}}` (default
      `core-interaction.md`) so the Tier-2 reference resolves — same block as Greenfield
      step 3.2.
    </step>

    <step id="4.5" name="Report Seams and Resolutions" required="true">
      List seams — gaps where conventions are missing or inconsistent (e.g. "No migration
      system found", "legacy `CIBlockElement` in `/local/components/old.list/` while new code
      uses D7"). These are the highest-value findings for the team. Also note every
      `brownfield-adaptive` deviation from the template here, and report every resolved
      `DEV-<n>` decision (user-confirmed and agent-decided Tier-3 alike).
    </step>

    <output>
      ✅ Brownfield mode: generated rules from analysis of the existing codebase.

      Created:
        - <project-root>/AGENTS.md (template baseline, observed content, adaptive
          sections where the analysis yielded significant insights)
        - .agents/rules/core/{core-interaction,database,architecture,code-style,gitflow}.md

      ⚠️ Seams identified:
        - No migration system found. Consider implementing one.
        - Inconsistent ORM usage: D7 in /local/modules/, CIBlockElement in /local/components/.

      Deviations resolved (DEV):
        - DEV-1 [Tier-1] bitrix-modules namespace: canon `FirstBit\` for new code;
          existing `Firstbit\` marked legacy (user confirmed, option (a))
        - DEV-2 [Tier-3] logging via `addMessage2Log`: agent decision — PSR-3 logger for
          new code (insignificant, logged)

      Summary: rules reflect the current state of the codebase. Update them as the project evolves.
    </output>
  </stage>

  <stage id="5" name="Verify" required="true">
    Run `<verification_method>` end-to-end on the finished files, then the checklist at the
    end of this file. All `quality_criteria` must pass; fix failures at the source before
    reporting.

    <checkpoint>All checks pass → report to the user with size figures and seam notes</checkpoint>
  </stage>
</workflow>

<output_format>
  ## Root `AGENTS.md` — the always-on, lean entry point
  Both routes keep the `references/AGENTS.md.template` shape (quality anchor):
  1. **Project rules & constraints** — bold-lead descriptive conventions: `/local/` placement,
     identifier trust, module-registry upkeep, secrets, error handling.
  2. **Project facts** — `/local/` tree with placement comments, module registry table, vendor
     convention (Greenfield: template text; Brownfield: observed values with anchors).
  3. **Routing** — priority hierarchy; Tier 1 always-load bullets (`@`-links to core files +
     Use When); Tier 2 hub-skills bullets; Tooling commands; Environment & tech stack.
  4. **Language** — file and reply-language conventions.
  Greenfield copies the template verbatim (minus the draft meta comment); Brownfield fills it
  with observed facts and may broaden sections or add new ones per rule `brownfield-adaptive`.

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
  - **Evolve the rules:** revisit after major milestones; run a drift check (`rules-check-drift` or manual comparison) so code hasn't diverged.
  - **Large repositories:** for massive projects, run `bitrix-prime-codebase` with fan-out to produce a comprehensive `.tmp/codebase-analysis.md`.
  - **Team onboarding:** these rules are not just for AI agents — they are the canonical source of truth for new developers. Commit them to the repository.
  - **Quality anchor drift:** if `references/AGENTS.md.template` is updated in the hub, this skill's quality_criteria and stage tables must be re-checked against the new template version.
</notes>

## Checklist

- [ ] Existing rules file backed up (e.g. `AGENTS.md.bak`) before any overwrite.
- [ ] Vendor, DB prefix, and project facts confirmed before any file was written.
- [ ] All six files created: root `AGENTS.md` + five `.agents/rules/core/*.md`; `{{tier1_rule_file}}` holds the skill-install block.
- [ ] Greenfield: templates verbatim, draft meta comment dropped — only confirmed placeholders replaced.
- [ ] Brownfield: every rule anchored to a file path, class, or code symbol — **no line numbers, no inventory counts, no unverifiable version strings**.
- [ ] Zero `{{` placeholders remain in finished files; no meta-text, no provenance banners, no fill instructions.
- [ ] Root `AGENTS.md` passes `quality_criteria`: template shape recognizable, density line test, ≤ 2 navigation hops, agent-neutral (zero directive procedures), size measured and reported (`tokens ≈ chars / 4`, target ≤ 3 000, cap 10 000).
- [ ] All generated files written in English; prose wrapped (soft 120; dense bullets/table rows follow template style, hard cap 400).
- [ ] Links resolve: every `@`-rule target exists; every Tier-2 skill exists in `.agents/skills/` or the hub.
- [ ] Seams reported when conventions are missing or inconsistent, plus every `brownfield-adaptive` deviation from the template.
- [ ] Brownfield: every Tier-1/Tier-2 `DEV-<n>` canon deviation resolved with an explicit user decision; Tier-3 decisions logged; decisions embedded in the rules (canon reference + carve-out, or a named override). Empty register → deviation step skipped.
- [ ] No filler — every rule changes the outcome if removed.
