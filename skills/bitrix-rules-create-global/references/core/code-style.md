# PHP Code Style (Bitrix)

<context>
  <system_context>
    Style is enforced by tooling (see Tooling); this file is the fallback baseline an agent writes against
    when tooling is unavailable. Bitrix deviations from the PSRs; where silent, apply the PSR.
    Scope: `local/`; placement — `architecture.md`.
  </system_context>

  <domain_context>
    PSR-12 + Bitrix deviations · vendor `{{VENDOR_NAME}}` / `{{vendor_name}}`.
  </domain_context>
</context>

<critical_rules enforcement="strict">
  <rule id="tooling-first" scope="all">
    Run the project linters/fixers after changes; trust their verdict. This file is the baseline to write
    against when they are unavailable.
  </rule>

  <rule id="files" scope="files">
    Full `<?php` only (`<?=` in templates); no short tags; no closing `?>` in symbol files; blank line after
    the open tag; `declare(strict_types=1);` in every new `lib/` file; UTF-8 no BOM, LF; one class per file,
    named after it.
  </rule>

  <rule id="names" scope="names">
    Classes `StudlyCaps`, constants `UPPER_CASE`, methods `camelCase`; modifier order
    `abstract`/`final` → visibility → `static`; visibility explicit, default `private`; no Hungarian
    notation (`$arItems`, `$sName` — legacy, do not replicate). Agent classes end with `Agent`, are
    idempotent; `execute()` returns the next-run string (`__METHOD__ . '();'` or a class constant).
    Handlers describe event + action; no `handler1`/bare `process()`. Bitrix legacy names
    (`CMyComponent`) are the naming exception.
  </rule>

  <rule id="format" scope="format">
    Tabs — one nesting level, one tab; spaces only for vertical alignment: multiline `=>` and docblock tag
    columns line up. Allman braces: class, method, and control blocks on their own lines;
    `else`/`elseif`/`catch`/`finally` start on a new line. One space after control-structure keywords and
    commas; spaces around binary operators; no space before a comma or `;`; none between function name and
    `(`. Single-quoted strings; short `[]` arrays. 120-character lines; wrap after a comma or before a
    binary operator, one extra tab per level; never split a method name or string literal — wrap chains at
    call boundaries. Blank lines between logical blocks; no trailing whitespace. `switch`: `case`/`default`
    one tab deeper, branch body one more; `break` mandatory except documented fall-through.
  </rule>

  <rule id="imports" scope="imports">
    One `use` per line, unused removed; group order `Bitrix\...` → `{{VENDOR_NAME}}\...` → third-party,
    blank line between groups; blank line after `namespace` and the use block; no redundant FQCN when an
    import covers it.
  </rule>

  <rule id="typing-phpdoc" scope="types">
    Signature types on every parameter, property, and return the Bitrix contract allows — `void` for no
    result, `?Type` for absent value, unions and `mixed` where real. PHPDoc complements the signature:
    new classes state purpose; public methods get a docblock — one-line summary, aligned `@param`/`@return`
    descriptions, `@throws` for actual throws, `@example` for non-obvious usage; generic refinements the
    signature cannot express: `array<string, mixed>`, `array{...}`, `class-string<T>`; property `@var`
    when implicit.
  </rule>

  <rule id="errors" scope="errors">
    Catch specific first, then general; silent `catch` forbidden; generic `Exception` only when no Bitrix
    type fits; `finally` releases resources; a failed `Result` operation throws with the joined error
    messages (`getErrorMessages()`).
  </rule>

  <rule id="bitrix-api" scope="bitrix">
    No implicit substitutes for global objects (`$APPLICATION`, `$USER`, `$DB`); prefer D7 —
    `\Bitrix\Main\Application`, `\Bitrix\Main\Web\Json` for JSON. Superglobals (`$_GET`, `$_POST`,
    `$_SERVER`, `$_COOKIE`) stay out of `lib/` classes — read the request via
    `\Bitrix\Main\Context::getCurrent()->getRequest()`. MUST NOT bypass access/session checks, use
    `extract()`/`eval()`, hardcode user-facing strings (in `/lang/`), or log secrets/raw user data.
    CSRF: output via `bitrix_sessid()`, verify via `check_bitrix_sessid()`.
  </rule>

  <rule id="components-exception" scope="components">
    Only files Bitrix loads under the component contract: `class.php`/`component.php`/`template.php` may
    skip PSR-4 and namespace; `CMyComponent` naming allowed; the `B_PROLOG_INCLUDED` guard is mandatory
    (`defined && === true`, else `die()`); still type internal methods, keep Allman.
  </rule>
</critical_rules>

## Tooling

- Dev deps: `squizlabs/php_codesniffer`, `friendsofphp/php-cs-fixer` — PSR-12 + Bitrix rules, run from
  `/local/`.
- Static analysis: `phpstan analyse <path> --level=5..8` or `psalm <path>` — level per project; auto-format
  only if tabs, Allman, 120, and component exceptions survive.
