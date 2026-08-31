---
name: bitrix-skill-eval
description: Covers quality evaluation of Bitrix Framework skills — blind test protocol (frozen spec, verbatim prompt, per-run isolation, time cap), Q1–Q10 grading rubric, hard gates, knowledge-point density, kernel verification. Applied when grading skill drafts, running blind tests, deciding acceptance. Key terms — Q1–Q10, knowledge point, density, hard gates, blind test, kernel verification.
---

# Bitrix Skill Quality Evaluation

Measures skill drafts against the house quality bar. The authoring spec lives in `bitrix-skill-creator`; this skill measures its output. It does not explain what skills are and does not own generic eval tooling.

| Concern | Owner |
| --- | --- |
| Skill product spec (structure, content, style) | `bitrix-skill-creator` |
| Generic eval tooling (test prompts, benchmarks, viewers) | System skill-creator |
| Bitrix-specific rubric, blind-test protocol, kernel verification of drafts | This skill |

Baseline: **main 23.0+**. Version markers inside graded drafts follow the rules in `bitrix-skill-creator` §4 and are verified during grading.

## 1. Evaluation model (indirect measurement)

A skill draft is the effect; the authoring spec is the treatment. Grading a draft measures how well the spec transmits house conventions to an arbitrary agent.

- Classify every gap as **spec-caused** (the rule is missing or weak in `bitrix-skill-creator`) or **agent-caused** (the rule existed and was ignored).
- Patch the spec only for spec-caused gaps. Agent-caused misses count against the draft; a miss repeated across drafts is evidence of a spec gap, however.
- Never widen a rubric criterion mid-series to fit a draft — recalibrate only between series, and record the change.

## 2. Blind test protocol

1. **Freeze the spec snapshot**: copy `skills/bitrix-skill-creator/` to an isolated location (e.g. `.tmp/spec/bitrix-skill-creator/`) before launch. The authoring agent reads only that snapshot. The snapshot must not change during a test.
2. **Canonical verbatim prompt**: byte-identical across iterations of one task, except the run-unique output-folder token. No coaching, no quality hints, no time-limit mentions inside the prompt — enforcement is external.
3. **Run isolation**: every run writes to its own unique output folder (`tier-<N>/`, incremented per run). A new agent launched while a previous one has yet to finish can never affect its results.
4. **Reference isolation**: the authoring agent is forbidden from reading the whole `skills/` directory — no sibling skills, no reference draft, no `bitrix-skill-creator` inside it. It reads the spec snapshot and kernel source only. Violations invalidate the run.
5. **External time cap**: run the authoring agent in the background; poll status every ~45–60 s; cancel at the cap. Check the output directory after cancelling — writes often flush past the cancel point.
6. **Archive everything**: copy every artifact (complete or partial) to the eval archive immediately after the run. Drafts never overwrite reference skills.

A single deliverable file fits tighter caps; multi-file (router + rules) deliveries need headroom and benefit from the spec's incremental-delivery rule (router first, then rules files one by one — partial artifacts stay useful).

## 3. Grading rubric (Q1–Q10, each 0–10)

| # | Criterion | 10 = | Automatic fail |
| --- | --- | --- | --- |
| Q1 | Structure | morphology per spec §1; sizes within budgets; templates followed | — |
| Q2 | Triggerability | description matches the spec template, carries concrete key terms | — |
| Q3 | Coverage | ≥85% of reference knowledge points + spec-mandated extras | <60% |
| Q4 | Precision | 0 invented identifiers (kernel-verified), 2+ negative facts | any invented id |
| Q5 | Code quality | strict_types, imports, error handling, why-comments; full exception family + catch order; constructor signatures verified | invented API in code |
| Q6 | Safety | bold prohibitions at the error site, all echoed in the checklist | — |
| Q7 | Checklist | 6–11 verifiable items incl. negatives | — |
| Q8 | Density | lines/knowledge-point ≤ reference; total lines ≤ 1.2× reference unless covering measurably more | >1.8× reference L/pt |
| Q9 | Consistency | cross-links real, canons referenced without duplication, English imperative | — |
| Q10 | Generation time | wall-clock start → last file delivered; faster is better at equal quality | over cap, or no file delivered |

**Overall** = mean of Q1–Q10. Hard gates independent of the mean: any invented identifier (Q4), coverage <60% (Q3), cap exceeded or nothing delivered (Q10) — any one fails the iteration regardless of the mean.

Q10 scale, as fractions of the cap: 10 = ≤70%; 8 = ≤80%; 6 = ≤100%; 0 = over cap or no file delivered. For multi-file deliveries grade the router by its own mtime (incremental delivery) and the whole set by the last mtime; a delivery that straddles the cap grades 6, and the pattern goes into the report.

## 4. Quality bar

- **Below average**: mean <7.5, or any invented identifier, or coverage <60%.
- **Average (reference parity)**: mean 7.5–8.4.
- **Above average (acceptance target)**: mean ≥8.5 AND 0 invented identifiers AND coverage ≥85% AND within the time cap.

## 5. Knowledge points and density

- A **knowledge point** = one discrete actionable item: an API pattern/recipe, a table row, an option default, a prohibition, a negative fact.
- Count points in the reference first, then in the draft. Density = lines ÷ points.
- The draft must match or beat the reference density. Blank lines and code count toward lines; code delivers points only when it teaches a pattern beyond boilerplate.
- Per-file budget for `rules/*.md`: 45–135 lines. An overrunning file gets merged examples, trimmed table columns, or a split — before any widening.

## 6. Kernel verification of drafts

Never trust a draft's identifiers on their face — verify against source, strongest first: the running project's `bitrix/modules/<module>/lib/...` — or, for a project-local module skill, the module's own code `local/modules/<vendor>.<module>/` — then a user-provided local docs mirror, then official online docs (`/local/` overrides win).

1. Targeted greps over full-file reads; ~15–20 checks per draft is typical. Record every check as `file:line`.
2. Verify: class names and parents, constructor signatures (argument types matter under `strict_types`), constants and bitmask values, service ids, settings sections, generator behavior, event names, thrown exception classes.
3. Kernel claims like "Since main X.Y" are usually unverifiable from source alone — flag them, never treat them as verified. Project-local module skills anchor versions to the module's `install/version.php`; verify version claims there instead.
4. Absence claims ("there is no X") need a positive search for X before acceptance.
5. Any identifier the mirror cannot confirm goes into the report as unverifiable — it still blocks the 0-invented gate if the draft presents it as fact.

## 7. Iteration loop

1. Grade the draft per §3–§5; write the grades down before touching anything.
2. Classify each gap: spec-caused → patch `bitrix-skill-creator`; agent-caused → record and move on.
3. Re-sync the spec snapshot, increment the tier token, re-run with the same canonical prompt.
4. Stop when the above-average bar holds, or after three iterations — then report the trend with evidence.

Keep an iteration log per task:

| Iter | Output | Lines | Time | Mean | Gates | Patches after |
| --- | --- | --- | --- | --- | --- | --- |

## 8. Reference calibration

Measure the reference before grading anything: total lines, knowledge points, density. Then grade the reference itself against the rubric — real references carry defects (a missing baseline line, an off-template H1, an over-budget file). Knowing them prevents over-penalizing the draft for diverging from an imperfect reference and anchors every "10 =" column in §3.

## 9. Evaluation without a reference (absolute mode)

When no reference skill exists for the domain (a first-of-its-kind skill), grade against the domain itself. The rubric and hard gates stay; the comparators swap:

- **Coverage (Q3)**: enumerate the domain surface first — run the spec's discover-full-surface procedure over the kernel modules (or the project-local module) the skill targets: classes, services, settings sections, events, UI integration points. **Scope the list to the skill's declared scenarios** (its trigger description / task statement); points outside those scenarios are excluded before counting. Coverage means "≥85% of what the scenarios need" — the whole-module reading of "surface" is wrong, and rewriting the full module is a failure mode, held back by the density band and file budgets. That list is the expected knowledge-point set. Floors stay: ≥85% target, <60% hard gate.
- **Density (Q8)**: compare against absolute budgets: rules files 45–135 lines, router per spec §1; L/pt sanity band **3–5** (calibrated across this collection: http-client 4.8, controllers 3.3). Flag drafts outside the band — padding above it, fragmenting below it.
- **Quality bar (§4)**: "above average" becomes **accept**: mean ≥8.5 AND 0 invented identifiers AND domain-surface coverage ≥85% AND within the time cap.
- **Blind test (§2) still runs**: the spec snapshot remains the treatment and the canonical prompt works unchanged; the pass condition shifts from "matches reference quality" to "passes absolute gates".
- **Skip §8**; record in the report that the run was reference-less and which surface enumeration anchored coverage.

## 10. Evidence discipline

- Grades cite evidence: `file:line` for kernel checks, mtimes for delivery times, wc for sizes.
- The final report per iteration: grades table, gate status, gaps classified spec-caused vs agent-caused, verdict, patches applied.
- Never modify the reference skill; drafts live in the eval archive only.

**Never grade from the authoring agent's self-assessment.** It is input to the report, never evidence.

## Pre-flight checklist for the evaluator

- [ ] Spec snapshot frozen before launch; untouched during the test.
- [ ] Canonical prompt byte-identical except the tier token; zero coaching or time hints inside.
- [ ] Whole `skills/` directory banned for the authoring agent.
- [ ] Unique `tier-<N>/` output dir; archive dir prepared.
- [ ] Time cap + poll cadence set; cancel at cap; directory re-checked after cancel (flushed writes).
- [ ] Reference measured (lines, points, density) and self-graded before grading the draft.
- [ ] No reference? Domain surface enumerated before launch; density graded against the 3–5 L/pt band.
- [ ] Kernel checks recorded with `file:line`; unverifiable claims listed separately.
- [ ] Gaps classified spec-caused vs agent-caused before any spec patch.
- [ ] Iteration log updated after every run.

## Related skills

- `bitrix-skill-creator` — the authoring spec this rubric measures.
