---
name: rules-check-drift
description: Use before a merge or inside a code-review pass. Checks whether your rules file (CLAUDE.md or AGENTS.md) still matches the codebase after recent changes — reports stale/now-false rules, drifted architecture-map entries, and any new invariant worth adding, each with the minimal edit. Advisory and anti-bloat.
---

# Rules-File Drift Check

> **Mission**: Check whether the project's rules file still matches the codebase after recent changes, and propose the smallest edits that keep it true.

<role_definition>
Your rules file — **`CLAUDE.md`** or **`AGENTS.md`** — is a **steering document, not documentation**: your ground
rules, your conventions, and a current **map of where things live**. Its only failure mode that matters is being
**wrong**: a stale rule or a drifted map actively misleads the agent on every future run. This skill checks the
rules file against what just changed and proposes the **smallest** edit that keeps it true.

> **Wrong rules are worse than missing rules. A longer rules file is worse than a lean one.** Most changes
> need *no* edit at all — adding a wrong or verbose line makes it worse.
</role_definition>

<input>
  - Optional input — a diff range. Default: uncommitted + staged (`git diff HEAD`); fall back to `main...HEAD`.
  - **Scope: the project's rules file(s)** — `CLAUDE.md` and/or `AGENTS.md`, the root file + any package-level
    ones. (If `CLAUDE.md` is just a `@AGENTS.md` import, check `AGENTS.md`.) Ignore README, `docs/`, and `.claude/`
    agent/command/skill files. This skill exists to keep the *rules* honest, nothing else.
</input>

<critical_rules priority="highest" enforcement="mandatory">
  <rule id="advisory_only">
    **Advisory.** Report the drift; only apply edits if the caller explicitly asks.
  </rule>

  <rule id="rules_file_only">
    **Rules file only** (`CLAUDE.md` / `AGENTS.md`). Not README, not docs.
  </rule>

  <rule id="lean_by_default">
    **Lean by default.** When in doubt, suggest nothing.
  </rule>

  <rule id="flag_only_three">
    Flag ONLY three things: a stated rule or fact that is now false, a drifted architecture-map entry,
    a new durable invariant. Everything else, leave alone.
  </rule>
</critical_rules>

<workflow>
  <stage id="1" name="See what changed" required="true">
    Run `git diff <range>` + `git status`. Note: moved/renamed/removed files, new modules, changed conventions,
    and any new invariant the change establishes.
  </stage>

  <stage id="2" name="Read the rules file as it is now" required="true">
    Load the project's rules file — `CLAUDE.md` or `AGENTS.md` (and any package-scoped ones).
    Hold each claim against the change set.
  </stage>

  <stage id="3" name="Flag ONLY these three things" required="true">
    1. **A stated rule or fact is now false** — e.g. "routes live in `src/routes/`" but they moved. → fix it.
    2. **The architecture map drifted** — a path or "where things live" pointer no longer matches reality.
       → fix the wrong entry (don't catalog every new file).
    3. **A new durable invariant must hold going forward** — the change introduces a rule that must stay true
       (e.g. "never call the DB from handlers — go through `repository/`"). → add it as **one line**.

    Everything else, leave alone. Do **not** suggest an edit to *record that a feature was added* (that's a
    changelog — the codebase is the source of truth), to restate what the code already makes obvious, or to add
    background/rationale/prose that doesn't steer future work.
  </stage>

  <stage id="4" name="Write each suggestion the way CLAUDE.md should read" required="true">
    - **One bullet, not a paragraph.** A rule is a line, not an essay.
    - **Keep the map current — don't grow it.** Fix the wrong path; don't enumerate the new ones.
    - **State rules in natural language; reference the codebase, never paste code.** Copied code goes stale; the
      codebase stays true. Good: "follow the error pattern in `src/core/errors/`." Bad: pasting the class.
  </stage>
</workflow>

<output_format>
  ```
  ## Rules-file drift check — range: <range>

  ### Fix (now false)
  | Where | What's wrong | Minimal fix |
  |-------|--------------|-------------|
  | "Architecture" map | routes moved `src/routes/` → `src/api/routes/` | update the one path |

  ### Add (new invariant only)
  - <one-line rule> — established by <the change that made it durable>

  ### Checked, still true — no edit
  - <areas you verified need no change>
  ```

  If nothing drifted: **"The rules file is still accurate for these changes — no edits needed."**
</output_format>

<constraints>
  - **Run it before every merge** (or fold into your code-review pass) so your rules never drift behind the code.
  - Keep every suggestion minimal: the rules file must stay true, never longer than it needs to be.

## Checklist

- [ ] Diff range identified and reported in the output header.
- [ ] Every claim in the rules file held against the change set.
- [ ] Only three flag types reported: now-false rules, drifted map entries, new durable invariants.
- [ ] No edits suggested for feature additions, restated code, or background prose.
- [ ] Each suggestion is one line and references the codebase — no pasted code.
- [ ] Nothing applied or committed — advisory only unless the caller asked.
</constraints>
