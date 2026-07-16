---
name: bitrix-request-response
description: HttpRequest/HttpResponse, Json/AjaxJson/Redirect, Uri, UuidGenerator. Use instead of $_GET/$_POST and raw headers.
---

# Application, Context, Request, Response

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

Progressive disclosure: open **only** the rule files that match the task. Do not read every `rules/*.md`.

## How to use

1. Identify the layer the task touches.
2. Open the matching `rules/*.md` below.
3. Prefer framework-native Bitrix patterns over custom abstractions.


## Choose a rule file

### When to read `rules/application-context.md`

Read `rules/application-context.md` (`Application and Context`) when the task involves:

- Application
- Context

### When to read `rules/request.md`

Read `rules/request.md` (`HttpRequest and JSON body`) when the task involves:

- HttpRequest
- ParameterDictionary

### When to read `rules/response.md`

Read `rules/response.md` (`HttpResponse and typed responses`) when the task involves:

- HttpResponse
- Built-in Response Classes
- Checklist
- Encrypted Cookies

### When to read `rules/uri-uuid.md`

Read `rules/uri-uuid.md` (`Uri and UuidGenerator`) when the task involves:

- Uri
- UuidGenerator

## Checklist

- [ ] Opened only the rule file(s) needed for this task.
- [ ] Followed DI / `/local/` / security canons from `AGENTS.md`.
