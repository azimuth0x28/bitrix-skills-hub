---
name: bitrix-security
description: CSRF, XSS, SQLi, SSRF, JWT/JWK, access rights, encryption. Use when handling input or auditing security.
---

# Security in Bitrix

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

Progressive disclosure: open **only** the rule files that match the task. Do not read every `rules/*.md`.

## How to use

1. Identify the layer the task touches.
2. Open the matching `rules/*.md` below.
3. Prefer framework-native Bitrix patterns over custom abstractions.


## Choose a rule file

### When to read `rules/csrf-xss.md`

Read `rules/csrf-xss.md` (`CSRF and XSS`) when the task involves:

- CSRF
- XSS and HTML Sanitization
- CSRF Details

### When to read `rules/sql-ssrf.md`

Read `rules/sql-ssrf.md` (`SQL injection and SSRF`) when the task involves:

- SSRF
- SQL Injections

### When to read `rules/jwt-crypto-access.md`

Read `rules/jwt-crypto-access.md` (`JWT, crypto, access, cookies`) when the task involves:

- JWT / JWK
- Access Rights
- `#[ActionAccess]` / `AccessCheckControllerInterface`
- Secure Cookies
- Value Encryption
- Miscellaneous
- Checklist

## Checklist

- [ ] Opened only the rule file(s) needed for this task.
- [ ] Followed DI / `/local/` / security canons from `AGENTS.md`.
