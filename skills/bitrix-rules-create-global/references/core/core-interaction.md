# Bitrix Core Interaction Standards

<context>
  <system_context>
    Rules for working with the 1C-Bitrix (on-premise) core: module loading, global objects,
    initialization, events, agents, components, form security, and logging.
    Custom code lives in `/local/`; the core `/bitrix/` is read-only.
  </system_context>

  <domain_context>
    PHP · D7 (`\Bitrix\Main\*`) · legacy API (`$APPLICATION`, `$USER`, `$DB`, `CAgent`) ·
    `local/php_interface/init.php` · modules `{{vendor_name}}.<module>`.
  </domain_context>
</context>

<critical_rules enforcement="strict">
  <rule id="core-read-only" scope="all">
    MUST NOT modify core files in `/bitrix/{modules,components}/` — use events and API only
  </rule>

  <rule id="csrf-protection" scope="forms">
    MUST always use `bitrix_sessid()` / `check_bitrix_sessid()` for CSRF protection of forms
  </rule>

  <rule id="no-extract-eval" scope="all">
    MUST NOT use `extract()` or `eval()`
  </rule>

  <rule id="json-via-web-json" scope="api">
    MUST use JSON only through `\Bitrix\Main\Web\Json`
  </rule>

  <rule id="idempotent-agents" scope="agents">
    MUST make agents idempotent (safe to run repeatedly)
  </rule>

  <rule id="complex-components" scope="components">
    MUST use complex components with `class.php` for new development
  </rule>
</critical_rules>

## API and Global Objects

- Load modules via `\Bitrix\Main\Loader` (`Loader::includeModule()`)
- Access global objects via `$GLOBALS` (`$APPLICATION`, `$USER`, `$DB`) or the `\Bitrix\Main\Application` facade

## /local/php_interface/init.php

- Keep `/local/php_interface/init.php` as empty as possible: it only wires loading — composer autoload
  (or the namespace registration), plus the single `lib/include.php` connection when project-local handlers exist
- If the project uses composer — `init.php` contains `require $_SERVER['DOCUMENT_ROOT'] . '/vendor/autoload.php'`
  (plus `require ... '/local/php_interface/lib/include.php'` when project-local handlers exist)
- If composer is not used and it is unclear where to place code:
  - `init.php` contains the namespace registration and the `include.php` connection:

    ```php
    Loader::registerNamespace(
        '{{VENDOR_NAME}}\Local\',
        $_SERVER['DOCUMENT_ROOT'] . '/local/php_interface/lib/'
    );

    require $_SERVER['DOCUMENT_ROOT'] . '/local/php_interface/lib/include.php';
    ```

  - Place code in `/local/php_interface/lib/<Domain>/<Class.php>` — e.g. `local/php_interface/lib/Integration/Main/UserHandler.php`, where `<Domain>` is a semantic group (Event, User, Order, etc.)
  - General class and namespace placement rules — see @.agents/rules/core/architecture.md → «Class and Namespace Placement»

## Event Handlers

- A module owns its handlers: register them in the module installer (`EventManager::registerEventHandler`)
- No module — handler classes live in `local/php_interface/lib/Integration/` (e.g. `Integration/Main/UserHandler.php`)
- The single entry point `local/php_interface/lib/include.php` attaches the project handlers — `init.php` requires
  `include.php` right after the autoload / namespace registration
- Move handler logic into a class, not into closures
- Check module availability (`Loader::includeModule`) before registering a handler for another module's events
- Give handlers meaningful names: `module:OnEventName` → `onEventNameHandler`

## Agents

- Register via `CAgent::AddAgent` in the module installer, not in `init.php`
- Set reasonable intervals and protection against infinite loops
- Log agent execution results for debugging
- Module and installer structure — see @.agents/rules/core/architecture.md → «Typical {{vendor_name}}.<module> module structure»

## Components

- Keep `template.php` "dumb" — view logic only
- Put all business logic in `class.php` (method `executeComponent()`)
- Validate all input in `class.php` / `component.php`
- Handle errors via D7 exceptions (`\Bitrix\Main\SystemException`); the `$APPLICATION->ResetException()` pattern — only in legacy code
- Component and template structure — see @.agents/rules/core/architecture.md → «Components: Complex and Simple»

## Forms and Security

- Validate and sanitize all user input
- Do not rely on client-side validation alone

## Loggers

- Log via D7 loggers: `\Bitrix\Main\Diag\Logger` (file-based — `\Bitrix\Main\Diag\FileLogger`); for debugging — `\Bitrix\Main\Diag\Debug`
- Create a file logger via `Logger::createLogger()` with a level, e.g. `Logger::createLogger('debug.log', Logger::DEBUG)`
- Use leveled methods per PSR-3: `Logger::info()`, `Logger::warning()`, `Logger::error()`, `Logger::critical()`, etc.
- Write meaningful messages with context (entity, ID, method) to the log, not bare values
- For quick debugging use `Debug::writeToFile($var, $name, $path)` / `Debug::dump()`
