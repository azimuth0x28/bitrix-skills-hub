# Errors, responses, scope

## Errors

- `$this->addError(new \Bitrix\Main\Error('msg', 'CODE', ['key' => 'value']));`
- `$this->addErrors($result->getErrors());`
- Never throw exceptions outward for ordinary user errors — use `Result` + `Error` (see `bitrix-result-and-errors`).
- Response with errors automatically receives `status: 'error'` and `errors` array.
- When returning success data from a service `Result`, prefer a narrow `getData()` contract — do not leak internal structures.

## Response Types

- `array` → JSON: `{ "status": "success", "data": [...] }`.
- `null` → `{ "status": "success" }` without data.
- `Bitrix\Main\HttpResponse` — custom response (headers, status, body).
- `Bitrix\Main\Engine\Response\Html` / `Json` / `Redirect` / `AjaxJson`.
- `Bitrix\Main\Engine\Response\Component` — component render.
- `Bitrix\Main\Engine\Response\Component\Ajax` — JSON + component render.
- `Bitrix\Main\Engine\Response\BFile` / `File` / `HttpResponseFile` — file delivery.

Controller helpers:

```php
return $this->renderView('list', ['items' => $items]);
// => /local/modules/vendor.module/views/list.php

return $this->renderComponent('vendor:post.list', '.default', ['IBLOCK_ID' => 12]);

return $this->renderExtension('vendor.post.list', ['items' => $items]);

return $this->redirectTo('/posts/');
```

Prefer these helpers / typed responses over manual `header()` / `json_encode()` (see `bitrix-request-response`).

## Scope (AJAX / REST / CLI)

- **AJAX**: `/bitrix/services/main/ajax.php?action=...` or `BX.ajax.runAction('...', {})`. Available when controller is declared and `controllers` exists in `.settings.php`.
- **REST**: requires `restIntegration.enabled = true` + `rest` module.
- **CLI**: possible with `ActionFilter\Scope` when calling controllers from commands.

Different scopes need different filter sets. CSRF does not apply to REST by default — add an explicit strategy.

## Checklist

- [ ] Controller is thin: orchestration only; business logic in a service.
- [ ] Filters use attributes by default; `configureActions` only when needed.
- [ ] `getDefaultPreFilters()` extends parent when overridden.
- [ ] Current user via `CurrentUser` / `getCurrentUser()`, not global `$USER`.
- [ ] Dependencies via **action parameters**, not controller constructor.
- [ ] Input via Request DTO + `#[ValidationParameter]` when the contract is non-trivial.
- [ ] Errors via `$this->addError` / `addErrors`, not exceptions for normal failures.
- [ ] Return type explicit: `array`, `HttpResponse`, or `renderXxx` / `redirectTo`.
