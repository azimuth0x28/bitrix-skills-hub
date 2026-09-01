---
name: bitrix-prime-codebase
description: Prime (orient) a 1C-Bitrix on-premise codebase for Brownfield rules generation. Analyzes the actual project — layout, ORM usage, migrations, event handlers, agents, coding style, git history — and produces `codebase-analysis.md` with file:line evidence, consumed by `bitrix-rules-create-global`. Applied when onboarding a Bitrix codebase or before generating project rules. Key terms — prime, codebase analysis, Brownfield, conventions, seams.
---

# Bitrix Prime Codebase: Analyze a 1C-Bitrix Project's Real Conventions

<role_definition>
  Produce a **reality map** of a 1C-Bitrix (on-premise) codebase:
  a single `$project-path/.tmp/codebase-analysis.md` at the project root that captures **what actually exists**
  with `file:line` evidence, so `bitrix-rules-create-global` can generate honest rules in Brownfield mode.
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
    Output one file: `$project-path/.tmp/codebase-analysis.md` (11 fixed sections).
    The output feeds `bitrix-rules-create-global`, which converts findings into `.agents/rules/core/*.md`.
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
  Run these four phases in order. Work directly in the project (`$project-path` or cwd).
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

  <stage id="3" name="Git History" required="true">
    Read the repository's git log in read-only mode:
    - Branches: which exist (`main`/`master`/`develop`/`dev`)? Are feature branches used?
    - Commit style: conventional commits or freeform? Sample 10 recent messages.
    - Release process: tags? release branches? `CHANGELOG.md`?
    - PR/code-review process: infer from merge commits / `--no-ff` merges; note if absent.

    <output>Provide Git process findings</output>
  </stage>

  <stage id="4" name="Write codebase-analysis.md" required="true">
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

    ## 11. Summary for AGENTS.md Rules
    5-10 rules that MUST be included in AGENTS.md (the most critical facts from sections 3-9).
    ```

    <checkpoint>The document contains all 11 sections with the exact headers above</checkpoint>
  </stage>
</workflow>

<delegation>
  <route to="explore subagents" when="the project is large — fan-out, one subagent per area (ORM, events/agents, components, style, git)" />
  Large projects can be routed to the `explore` subagents as specified above.
  Merge their findings into the single `codebase-analysis.md`.
</delegation>

<output_format>
  Produce one file: `$project-path/.tmp/codebase-analysis.md`,  with sections 1-11 exactly as specified
  in stage 4. Do NOT create or modify any other project files.
</output_format>

<notes>
  - **Read-only:** Write only `codebase-analysis.md`; do not touch any source file.
  - **Large repos:** Fan-out with `explore` subagents is allowed to keep the analysis bounded and fast.
</notes>

## Checklist

- [ ] All 11 sections present with the exact headers from stage 4.
- [ ] Sections 3–9 carry `file:line` citations of real repo paths — no fabricated examples.
- [ ] At least 3 citations in the ORM section; at least 1 in every other evidence section.
- [ ] Sections 3–9 contain observations only — recommendations live in Seams (section 10).
- [ ] Inconsistencies documented as variance, nothing smoothed over; "Not found" stated explicitly.
- [ ] Section 10 (Seams) non-empty; section 11 lists 5–10 prioritized rules.
- [ ] Only `codebase-analysis.md` was written — no source file created or modified.
