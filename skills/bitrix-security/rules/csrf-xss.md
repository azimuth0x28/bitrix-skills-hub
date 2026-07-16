# CSRF and XSS

## CSRF

### Form/AJAX Protection

- `Bitrix\Main\Engine\ActionFilter\Csrf` is in the default prefilters for controllers, but `listAllowedScopes()` limits it to **`Controller::SCOPE_AJAX` only**. It does **not** run for REST/`SCOPE_REST` (or other scopes) unless you add an equivalent check yourself.
- In HTML forms:

    ```php
    <?= bitrix_sessid_post() ?> <!-- <input type="hidden" name="sessid" value="..."> -->
    ```

- In `fetch` / AJAX (`runAction`) requests: `X-Bitrix-Csrf-Token: <bitrix_sessid()>` header (or `sessid` in the body).
- Manual check (if writing a handler directly): `if (!check_bitrix_sessid()) { die('Invalid sessid'); }`.

### When Sessions are Read-only

If `CloseSession` is enabled (via filter), the CSRF token behaves as usual — the kernel reads it from the request rather than the session.

### Antipatterns

- A `GET` endpoint that changes state without a CSRF token and checks.
- Custom `sessid` field in a form without `bitrix_sessid_post()`.

## XSS and HTML Sanitization

- Output everything via `htmlspecialcharsbx($value)`.
- In templates — `<?= htmlspecialcharsbx($item['TITLE']) ?>`.
- For HTML content from users, use `\Bitrix\Main\Text\HtmlFilter` or `CBXSanitizer`:

```php
$sanitizer = new \CBXSanitizer();
$sanitizer->SetLevel(\CBXSanitizer::SECURE_LEVEL_HIGH); // or MEDIUM, LOW
$safeHtml = $sanitizer->SanitizeHtml($userHtml);
```

- Pass JS data via `\Bitrix\Main\Web\Json::encode($data)` instead of direct concatenation.
- `arResult` in a component template is not escaped by default — escape it yourself.

## CSRF Details

- `bitrix_sessid_get()` / `bitrix_sessid()` — get token for JS/AJAX headers.
- ActionFilter `Csrf` → only `SCOPE_AJAX`; REST and custom scopes need their own CSRF/auth strategy.
- Cookie `SameSite` settings affect CSRF protection — configure in `crypto` / cookie settings.
