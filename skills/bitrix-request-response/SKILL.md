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

## Converter (not covered by rule files)

`Bitrix\Main\Engine\Response\Converter` converts strings/arrays via bitmask flags: `TO_SNAKE`, `TO_SNAKE_DIGIT`, `TO_CAMEL`, `TO_UPPER`, `TO_LOWER`, `LC_FIRST`, `UC_FIRST`, `KEYS`, `VALUES`, `RECURSIVE`. Methods: `process($data)`, `getFormat()` / `setFormat($format)`, static `toJson()`.

`Converter::OUTPUT_JSON_FORMAT` = `KEYS | RECURSIVE | TO_CAMEL | LC_FIRST` — it camelCases array **keys only** (no `VALUES` flag); values keep their original case:

```php
use Bitrix\Main\Engine\Response\Converter;

(new Converter(Converter::LC_FIRST | Converter::TO_CAMEL))->process('la_la_land'); // laLaLand

(new Converter(Converter::OUTPUT_JSON_FORMAT))->process([
    'CATEGORIES' => [['ID' => 1, 'NAME' => 'Foods']],
]);
// ['categories' => [['id' => 1, 'name' => 'Foods']]] — 'Foods' stays untouched (no VALUES flag)
```

## Checklist

- [ ] Opened only the rule file(s) needed for this task.
- [ ] Followed DI / `/local/` / security canons from `AGENTS.md`.
