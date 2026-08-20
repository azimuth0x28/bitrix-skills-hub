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
- `Bitrix\Main\Engine\Response\HtmlContent` — AJAX JSON with `html` + `assets` (extends `AjaxJson`).
- `Bitrix\Main\Engine\Response\Json` / `Redirect` / `AjaxJson`.
- `Bitrix\Main\Engine\Response\Render\View` / `Render\Component` / `Render\Extension` — HTML for HTTP routes (`renderView` / `renderComponent` / `renderExtension`).
- `Bitrix\Main\Engine\Response\Component` — JSON component payload from `renderComponentAjax()` (not the same class as `Render\Component`).
- `Bitrix\Main\Engine\Response\BFile` / `File` — file delivery (`BFile::createByFileId()` for `b_file`).
- `Bitrix\Main\Engine\Response\ResizedImage` — resized image (`createByImageId($id, $w, $h)`); never take width/height raw from the request.
- `Bitrix\Main\Engine\Response\Zip\Archive` — ZIP stream.
- `Bitrix\Main\Engine\Response\OpenDesktopApp` / `OpenMobileApp` — deep-link into native Bitrix apps.

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
- [ ] Input via Request DTO + `ValidationParameter` in `getAutoWiredParameters()` when the contract is non-trivial.
- [ ] Errors via `$this->addError` / `addErrors`, not exceptions for normal failures.
- [ ] Return type explicit: `array`, `HttpResponse`, or `renderXxx` / `redirectTo`.
