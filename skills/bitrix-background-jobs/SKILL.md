---
name: bitrix-background-jobs
description: CAgent, addBackgroundJob, Messenger brokers/queues. Use for deferred and async processing.
---

# Background Tasks in Bitrix

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

Progressive disclosure: open **only** the rule files that match the task. Do not read every `rules/*.md`.

## How to use

1. Identify the layer the task touches.
2. Open the matching `rules/*.md` below.
3. Prefer framework-native Bitrix patterns over custom abstractions.


## Choose a rule file

### When to read `rules/agents.md`

Read `rules/agents.md` (`CAgent agents`) when the task involves:

- Agents (`CAgent`)

### When to read `rules/background-job.md`

Read `rules/background-job.md` (`Application::addBackgroundJob`) when the task involves:

- `Application::addBackgroundJob()`

### When to read `rules/messenger.md`

Read `rules/messenger.md` (`Messenger queues`) when the task involves:

- Messenger (Message Queues)
- When to Choose What
- Checklist

## Checklist

- [ ] Opened only the rule file(s) needed for this task.
- [ ] Followed DI / `/local/` / security canons from `AGENTS.md`.
