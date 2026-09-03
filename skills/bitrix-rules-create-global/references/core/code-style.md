# PHP Code Standards for Bitrix Projects

<context>
  <system_context>
    This document only pins down Bitrix deviations from and clarifications of PSR-1, PSR-4, PSR-5
    and PSR-12; where no clarification is given, apply the corresponding PSR. The rules apply to
    custom code in `local/`.
  </system_context>

  <domain_context>
    PHP · Bitrix on-premise · PSR-1/PSR-4/PSR-5/PSR-12 · PHP_CodeSniffer + PHP-CS-Fixer ·
    vendor `{{VENDOR_NAME}}` (set in `AGENTS.md`) · placeholders `{{VENDOR_NAME}}` and `{{vendor_name}}`.
  </domain_context>

  <reference>
    Class placement — see `architecture.md`, section «Class and Namespace Placement»
    (not duplicated here).
  </reference>
</context>

<critical_rules enforcement="strict">
  <rule id="core-read-only" scope="all">
    MUST NOT modify the core `/bitrix/`; extend behavior in `local/`.
  </rule>

  <rule id="full-php-tag" scope="files">
    Use only the full `<?php` tag and the short echo tag `<?=` allowed in templates
  </rule>

  <rule id="no-short-tags" scope="files">
    MUST NOT use short tags `<? ... ?>`
  </rule>

  <rule id="no-closing-tag" scope="files">
    MUST NOT add a closing `?>` in files that declare classes or functions
  </rule>

  <rule id="meaningful-handler-names" scope="names">
    MUST NOT use `handler1` or a meaningless `process()`
  </rule>

  <rule id="no-case-brevity" scope="names">
    MUST NOT change case for brevity; names dictated by Bitrix follow the exception
    `CMyComponent`
  </rule>

  <rule id="tabs-not-spaces" scope="format">
    Use tabs, not spaces; one nesting level — one tab
  </rule>

  <rule id="no-mixed-indent" scope="format">
    MUST NOT mix tabs and spaces within a single indentation; spaces inside expressions — per PSR-12
  </rule>

  <rule id="no-broken-chains" scope="format">
    MUST NOT split a method name or string literal; wrap chains at call boundaries
  </rule>

  <rule id="modifier-order" scope="classes">
    Keep the modifier order `abstract` or `final` → visibility → `static`, e.g.
    `final public static function execute()`
  </rule>

  <rule id="no-static-public-final" scope="classes">
    MUST NOT use the valid but inconsistent order `static public final`
  </rule>

  <rule id="typed-signatures" scope="types">
    MUST NOT replace a real type with a vague PHPDoc: first the type in the signature, then
    additional constraints in PHPDoc
  </rule>

  <rule id="no-mixed-import-groups" scope="imports">
    MUST NOT mix import groups without reason
  </rule>

  <rule id="no-redundant-fqcn" scope="imports">
    MUST NOT repeat the full path when an import makes the dependency clear
  </rule>

  <rule id="no-space-alignment" scope="format">
    MUST NOT align continuations with spaces
  </rule>

  <rule id="no-hidden-empty-body" scope="format">
    MUST NOT hide an empty body with an unidiomatic shorthand
  </rule>

  <rule id="switch-break" scope="format">
    MUST NOT omit `break`, except for intentional and documented fall-through
  </rule>

  <rule id="no-silent-catch" scope="errors">
    MUST NOT use a silent `catch` without action
  </rule>

  <rule id="no-generic-exception" scope="errors">
    MUST NOT catch a generic `Exception` when a standard Bitrix type can be handled and the
    error context preserved
  </rule>

  <rule id="no-global-shadowing" scope="api">
    MUST NOT create implicit same-named substitutes for global objects
  </rule>

  <rule id="no-extract-eval" scope="all">
    MUST NOT use `extract()` or `eval()`
  </rule>

  <rule id="no-core-modification" scope="all">
    MUST NOT modify `/bitrix/`; extend behavior in `local/`
  </rule>

  <rule id="no-bypass-security" scope="all">
    MUST NOT bypass Bitrix's standard access checks, sessions, and error handling
  </rule>

  <rule id="no-hardcoded-strings" scope="i18n">
    MUST NOT hardcode user-facing strings in PHP
  </rule>

  <rule id="no-disabled-checks" scope="security">
    MUST NOT disable permission or session checks
  </rule>

  <rule id="no-secrets-logging" scope="security">
    MUST NOT log secrets, tokens, and raw user data
  </rule>

  <rule id="no-exception-leak" scope="components">
    MUST NOT propagate a component exception to services, agents, and handlers: they
    follow PSR and this document
  </rule>

  <rule id="psr12-preserved" scope="tooling">
    MUST NOT override PSR-12 rules without a documented reason
  </rule>
</critical_rules>

## Purpose and Scope

This document only pins down Bitrix deviations from and clarifications of PSR-1,
PSR-4, PSR-5 and PSR-12; where no clarification is given, apply the corresponding PSR.
The rules apply to custom code in `local/`.

- Sources — [PSR-1][psr1-ru], [PSR-12][psr12-ru], [PSR-5][psr5-ru] and Bitrix recommendations.
- When generating templates, keep `{{VENDOR_NAME}}` and `{{vendor_name}}`.
- The vendor is project-specific — set it in `AGENTS.md` (`{{VENDOR_NAME}}`); there is no default.
- Class placement — see `architecture.md`, section «Class and Namespace Placement» (not duplicated here).

## Table of Contents

1. [PHP File Structure](#1-php-file-structure)
2. [Class, Constant, and Method Names](#2-class-constant-and-method-names)
3. [Formatting: Bitrix Deviations from PSR-12](#3-formatting-bitrix-deviations-from-psr-12)
4. [Visibility and Modifier Order](#4-visibility-and-modifier-order)
5. [Strict Typing](#5-strict-typing)
6. [PHPDoc](#6-phpdoc)
7. [Namespace and use](#7-namespace-and-use)
8. [Wrapping and Control Structures](#8-wrapping-and-control-structures)
9. [Try/catch/finally](#9-trycatchfinally)
10. [Bitrix API and Global State](#10-bitrix-api-and-global-state)
11. [User-Facing Strings and Bitrix Security](#11-user-facing-strings-and-bitrix-security)
12. [Exceptions for Bitrix Components](#12-exceptions-for-bitrix-components)
13. [Automated Verification](#13-automated-verification)
14. [Standards and Rules Packages](#14-standards-and-rules-packages)

## 1. PHP File Structure

Regular PHP files follow the rules below; component exceptions are described in section 14.

- Use only the full `<?php` tag and the short echo tag `<?=` allowed in templates.
- Do not use short tags `<? ... ?>`.
- Do not add a closing `?>` in files that declare classes or functions.
- Use UTF-8 without BOM and LF (`\n`) line endings, not CRLF.
- Declare `declare(strict_types=1);` right after the opening tag.
- Follow the "one class per file" rule; the file name matches the class name. Exception — standard Bitrix component files.
- A file either declares symbols or performs an action; mixing is allowed only when Bitrix requires it.

## 2. Class, Constant, and Method Names

- Name classes in `StudlyCaps`: `PriceUpdateAgent`, `UserController`.
- Name class constants in `UPPER_CASE` with underscores: `MAX_ITEMS_PER_RUN`.
- Name methods and functions in `camelCase`: `execute()`, `getUserData()`.
- An agent class name describes the action and ends with `Agent`: `PriceUpdateAgent`, `OrderSyncAgent`.
- When agent registration requires it, `execute()` returns the fixed string of the next run:
  `\{{VENDOR_NAME}}\...\AgentName::execute();`.
- An agent (`CAgent`) must be idempotent: a repeated run neither corrupts nor duplicates data.
- Handler names describe the event and the action.
- Do not use `handler1` or a meaningless `process()`.
- Do not change case for brevity; names dictated by Bitrix follow the exception `CMyComponent`.

## 3. Formatting: Bitrix Deviations from PSR-12

### Indentation and line length

- Use **tabs**, not spaces; one nesting level — one tab.
- The visual tab width is 2 spaces; this is a display setting, not a substitute for tabs.
- Do not mix tabs and spaces within a single indentation; keep spaces inside expressions per PSR-12.
- Respect the 120-character line limit; wrap a long line after a comma or before a binary operator.
- Shift a continued expression one tab relative to the original level.
- Do not split a method name or string literal; wrap chains at call boundaries.
- Make long conditions, parameters, arrays, and literals readable by wrapping, not by exceeding the limit.
- Blank lines separate logical blocks; trailing whitespace is not allowed.

### Braces and spaces

- Apply Allman style: the opening and closing braces of a class, method, and control block go on their own lines.
- Apply this rule to `if`, `elseif`, `else`, `for`, `foreach`, `while`, `switch`, `try`, `catch`, `finally`.
- Put one space after the control-structure keyword.
- Start `else`, `elseif`, `catch`, and `finally` on a new line.
- Put one space after a comma; no space before a comma or `;`.
- Put spaces around binary operators; no space between a function name and `(`.
- Format call, indexing, and grouping parentheses per PSR-12; Allman applies to braces.
- SHOULD: With complex logic keep an obvious evaluation order; use parentheses when needed.

## 4. Visibility and Modifier Order

- Declare `public`, `protected`, or `private` explicitly on every property and method.
- SHOULD: Choose the minimum visibility; make internal properties and methods `private` by default.
- MAY: Public properties are allowed for a Bitrix contract or an external consumer; usually use accessor methods.
- Keep the modifier order `abstract` or `final` → visibility → `static`, e.g. `final public static function execute()`.
- Do not use the valid but inconsistent order `static public final`.

## 5. Strict Typing

- In new custom code, type all parameters, properties, and results compatible with the Bitrix contract.
- Use `int`, `float`, `string`, `bool`, `array`, Bitrix types, and custom classes.
- Use `void` for a method without a result.
- Express a valid absence of a value with `?Type`: `?string`, `?int`, `?DateTime`.
- Do not replace a real type with a vague PHPDoc: first the type in the signature, then additional constraints in PHPDoc.
- SHOULD: For legacy APIs with mixed structure, use `array` only after verifying the contract and document the structure.

## 6. PHPDoc

SHOULD: PHPDoc complements, not replaces, strict typing; write it in the spirit of PSR-5.

- SHOULD: For a class, state its purpose and, when needed, the run mode or external contract.
- SHOULD: For a non-trivial method, describe the action and important side effects.
- RECOMMENDED: Use `@param` for all parameters with type, name, and meaning.
- RECOMMENDED: Use `@return` when the result format needs explanation, even if the type is visible in the signature.
- RECOMMENDED: Add `@throws` for exceptions the method can actually throw.
- SHOULD: Document array constraints, string formats, and `null` conditions not expressed by the signature.
- After changing a signature, remove stale tags.
- MAY: For a simple getter the description may be redundant; for aggregation, writes, or transactions, explicit `@param`, `@return`, `@throws` are required.

## 7. Namespace and use

- Leave one blank line after `namespace`.
- Put each `use` on its own line; remove unused imports.
- Group imports in the order `Bitrix\...` (including ORM and types) → `{{VENDOR_NAME}}\...` → third-party packages.
- Leave one blank line after the `use` block.
- Do not mix groups without reason.
- The top-level namespace is set by the template `{{VENDOR_NAME}}\`; the module prefix: `{{vendor_name}}.<modulename>`.
- The exact class, namespace, and directory matches are defined by `architecture.md`.
- Do not repeat the full path when an import makes the dependency clear.
- MAY: For explicitly required Bitrix globals and APIs, a fully qualified class is acceptable and sometimes safer for legacy environments.

## 8. Wrapping and Control Structures

- When wrapping parameters or array items, wrap after a comma.
- In a long condition, wrap before a binary operator.
- Each continued level gets one extra tab.
- Do not align continuations with spaces.
- MAY: Put a closing `)` on its own line at the matching level.
- MAY: A multiline call is allowed even under 120 characters if it simplifies review; the signature and the call must have clear levels.
- `if`, `elseif`, `else`, `for`, `foreach`, `while` use a space after the keyword and Allman blocks.
- Write an empty body so the intent is obvious.
- Do not hide an empty body with an unidiomatic shorthand.
- Nested blocks get one tab per level; wrap conditions before the operator.

For `switch` keep the nesting:

- `case` and `default` are indented one tab relative to `switch`.
- The branch body is indented one more tab; `break` sits at the body level.
- SHOULD: Leave a blank line between branches when it improves readability.
- Do not omit `break`, except for intentional and documented fall-through.

## 9. Try/catch/finally

- `try`, each `catch`, and `finally` are separate Allman blocks; `catch` starts after the previous block closes.
- Keep one space after the keyword before the exception type or the construct part.
- Catch specific exceptions first, then general ones.
- Do not use a silent `catch` without action.
- In `finally`, release a resource or perform required cleanup regardless of the result.
- SHOULD: List in PHPDoc the exceptions actually thrown.
- Do not catch a generic `Exception` when a standard Bitrix type can be handled and the error context preserved.

## 10. Bitrix API and Global State

- Access global objects explicitly when needed: `$APPLICATION`, `$USER`, `$DB`.
- Do not create implicit same-named substitutes for global objects.
- SHOULD: Prefer `\Bitrix\Main\Application` over direct `$DB` and low-level access where possible.
- Use `\Bitrix\Main\Web\Json` for JSON.
- SHOULD: A modern class imports the Bitrix API or uses the fully qualified name; a global object is allowed only under a legacy handler/component contract.

## 11. User-Facing Strings and Bitrix Security

- For CSRF forms, output the identifier via `bitrix_sessid()`.
- Before a mutating action, verify it with `check_bitrix_sessid()`.
- Store strings, headings, error messages, and field labels in `/lang/`.
- Do not hardcode user-facing strings in PHP.
- Validate input data with Bitrix facilities.
- Do not disable permission or session checks.
- The agent's next-run string is a fixed class string, not user input.

## 12. Exceptions for Bitrix Components

The exception is limited to files Bitrix loads under the component contract.

- MAY: `class.php`, `component.php`, `template.php` may not follow PSR-4 and may have no `namespace`; this is an OPTIONAL exception.
- MAY: The names `CMyComponent` and `CComponentSomeName` are allowed only for a component.
- The `B_PROLOG_INCLUDED` guard is mandatory in component and template files.
- The guard checks that the constant is defined and equals `true`, then calls `die()`.
- SHOULD: Usually the class inherits `CBitrixComponent` and implements `executeComponent()`.
- Still type internal methods and format them in Allman as far as the legacy contract allows.
### Example A: a compact Bitrix agent

```php
<?php

declare(strict_types=1);

namespace {{VENDOR_NAME}}\Catalog\Agents;

use Bitrix\Main\SystemException;
use Bitrix\Main\Web\Json;
use {{VENDOR_NAME}}\Catalog\Service\PriceService;

/** Processes published products; a repeated run is idempotent. */
final class PriceUpdateAgent
{
	private const BATCH_SIZE = 50;
	private PriceService $priceService;

	public function __construct(PriceService $priceService)
	{
		$this->priceService = $priceService;
	}

	/** @return string The agent registration string.
	 *  @throws SystemException
	 **/
	public function execute(): string
	{
		$items = $this->priceService->findForUpdate(
			self::BATCH_SIZE,
			true
		);
		if (
			$items === []
			|| $this->priceService->isLocked()
		)
		{
			return '\\{{VENDOR_NAME}}\\Catalog\\Agents\\PriceUpdateAgent::execute();';
		}
		elseif (
			count($items) > self::BATCH_SIZE
		)
		{
			$items = array_slice($items, 0, self::BATCH_SIZE);
		}
		foreach ($items as $item)
		{
			try
			{
				switch ($item['type'])
				{
					case 'retail':
						$this->priceService->updateRetail($item);
						break;
					default:
						$this->priceService->updateWholesale($item);
						break;
				}
			}
			catch (SystemException $exception)
			{
				$this->priceService->logFailure($item['id'], $exception->getMessage());
			}
		}
		return '\\{{VENDOR_NAME}}\\Catalog\\Agents\\PriceUpdateAgent::execute();';
	}

	/** @param array<int, array{type: string, id: int}> $items
	 *  @return string
	 *  @throws SystemException
	 **/
	private function encode(array $items): string
	{
		return Json::encode($items);
	}
}
```

### Example B: a permitted exception for a component's `class.php`

```php
<?php

if (!defined('B_PROLOG_INCLUDED') || B_PROLOG_INCLUDED !== true)
{
	die();
}

class CMyComponent extends CBitrixComponent
{
	public function executeComponent()
	{
		$this->arResult = $this->prepareData();
		$this->includeComponentTemplate();
	}

	private function prepareData(): array
	{
		return [];
	}
}
```

## 13. Automated Verification

- Check with project tools both the individual changed file and the whole affected module.
- Configurations must add Bitrix rules to PSR-12.
- SHOULD: Use PHPStan static analysis, typically level 5–8 depending on project maturity; Psalm is acceptable as an alternative.
- SHOULD: Check style with `PHP_CodeSniffer` using `PSR12` and PHP-CS-Fixer; plug in the project's or vendor's custom rules.
- Before auto-formatting, verify that tabs, Allman, the 120-character limit, and component exceptions are preserved.
- Use the commands `vendor/bin/phpstan analyse <path> --level=5`, `vendor/bin/phpstan analyse <path> --level=8`,
  `vendor/bin/psalm <path>`, `vendor/bin/phpcs --standard=PSR12 <path>`, `vendor/bin/php-cs-fixer fix <path>`.
- The exact path and level are set by the project configuration.

## 14. Standards and Rules Packages

- Composer dev dependencies — `friendsofphp/php-cs-fixer`, `squizlabs/php_codesniffer`.
- Install them as dev dependencies and pin versions in the lock file.
- MAY: A custom PHP_CodeSniffer ruleset and PHP-CS-Fixer config are allowed.
- SHOULD: Cross-check ready-made Bitrix configurations against [php-codesniffer-ruleset][bitrix-php-codesniffer-ruleset] and
  [php-cs-fixer-config][bitrix-php-cs-fixer-config].

[psr]: https://github.com/php-fig/fig-standards/blob/master/PSR.md
[psr1]: https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-1-basic-coding-standard.md

[psr12]: https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-12-extended-coding-style-guide.md

[psr-ru]:https://php-psr.ru/
[psr1-ru]:https://php-psr.ru/accepted/PSR-1-basic-coding-standard/
[psr4-ru]: https://php-psr.ru/accepted/PSR-4-autoloader/
[psr5-ru]: https://php-psr.ru/proposed/phpdoc/
[psr12-ru]:https://php-psr.ru/accepted/PSR-12-extended-coding-style/

[custom-bx-psr1]: accepted/basic-coding-standard.md
[custom-bx-psr2]:accepted/basic-coding-standard.md

[bitrix-php-codesniffer-ruleset]: https://gitlab.cbitrix.com/devtools/php-codesniffer-ruleset
[bitrix-php-cs-fixer-config]: https://gitlab.cbitrix.com/devtools/php-cs-fixer-config

[bitrix-course43]: https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=43&LESSON_ID=3095