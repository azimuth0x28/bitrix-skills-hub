---
name: bitrix-components
description: "Use when creating a new component or editing an existing one (adding/changing templates, cache, SEF flow, AJAX handlers). Covers Bitrix components — anatomy (complex/simple, class.php-only), placement, folder structure, $arParams/$arResult, templates, result_modifier, cache, SEF, Controllerable AJAX. Key terms — class.php, $arParams, $arResult, result_modifier, component_epilog, Controllerable."
metadata:
  type: knowledge
  version: "1.0.0"
---

# Bitrix Components

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

Progressive disclosure: open **only** the rule files that match the task. Do not read every `rules/*.md`.

## How to use

1. Identify the layer the task touches.
2. Open the matching `rules/*.md` below.
3. Prefer framework-native Bitrix patterns over custom abstractions.

## Choose a rule file

| Rule | Covers | Read when |
| --- | --- | --- |
| `rules/anatomy.md` | complex vs simple anatomy, class.php-only, SEF flow, class namespace | scaffolding a new component, deciding complex/simple |
| `rules/structure.md` | placement, folder structure, class.php minimum, usage, `$arParams`/`$arResult`, `.description.php`, `.parameters.php` | placing files, writing parameters |
| `rules/template.md` | template, `result_modifier.php`, `component_epilog.php` | templates and epilog |
| `rules/cache-sef-ajax.md` | cache, SEF, Controllerable and AJAX | caching, SEF, AJAX |

## Checklist

- [ ] Decided the anatomy first — complex vs simple (see `rules/anatomy.md`).
- [ ] Opened only the rule file(s) needed for this task.
- [ ] Followed DI / `/local/` / security canons from `AGENTS.md`.