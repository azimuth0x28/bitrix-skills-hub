# HttpResponse and typed responses

## HttpResponse

```php
use Bitrix\Main\HttpResponse;
use Bitrix\Main\Web\Cookie;

$response = new HttpResponse();
$response->setStatus('201 Created');
$response->addHeader('Content-Type', 'application/json; charset=UTF-8');
$response->addCookie(
    (new Cookie('VENDOR_TOKEN', $jwt, time() + 3600))
        ->setHttpOnly(true)
        ->setSecure(true)
);
$response->setContent(\Bitrix\Main\Web\Json::encode(['ok' => true]));
return $response;
```

Methods:

- `setStatus(string)`, `getStatus()`.
- `addHeader(name, value)`, `setHeaders(HttpHeaders)`, `getHeaders()`.
- `addCookie(Cookie $c, bool $replace = true, bool $checkExpires = true)`, `getCookies()`.
- `setContent($body)`, `getContent()`.
- `flush($text = '')` — send headers and current buffer.
- `send($body = null)` — finalization.

## Built-in Response Classes

All live in `Bitrix\Main\Engine\Response\*`. Return from controller action or route.

Prefer typed responses / controller helpers over `header()`, `setcookie()`, or manual `json_encode`.

| Need | Prefer |
| --- | --- |
| Serializable payload; Engine can wrap | plain `array` / `null` from controller |
| Explicit JSON object + HTTP control | `Engine\Response\Json` |
| Bitrix envelope `status` / `data` / `errors` | `AjaxJson` |
| Redirect | `Redirect` or `$this->redirectTo()` |
| View / component / extension | `renderView` / `renderComponent` / `renderExtension` / `Component` |
| File download | `BFile` / `File` / `ResizedImage` / `Zip\Archive` |

### JSON

```php
use Bitrix\Main\Engine\Response\Json;
use Bitrix\Main\Engine\Response\AjaxJson;

return new Json(['id' => 42]);
// Content-Type: application/json; charset=UTF-8

return AjaxJson::createSuccess(['id' => 42]);
// {"status":"success","data":{"id":42},"errors":[]}

return AjaxJson::createError(new \Bitrix\Main\Error('Forbidden', 'ACCESS_DENIED'));
// {"status":"error","errors":[...]}
```

A controller returning an array is automatically wrapped in `AjaxJson` — manual use is needed in route closures or non-standard endpoints. Do not use `AjaxJson` as a blanket wrapper when a plain `Json` response is enough.

### Redirect

```php
use Bitrix\Main\Engine\Response\Redirect;

// Constructor: __construct($url, bool $skipSecurity = false) — no status argument
return new Redirect('/auth/', skipSecurity: false);

$redirect = new Redirect('/auth/');
$redirect->setStatus('301 Moved Permanently'); // status only via setStatus()
return $redirect;
```

`Redirect` checks the URL via `CHTTP` and blocks obvious XSS redirects. Do not pass `status:` to the constructor — it is not a named parameter.

### Component

```php
use Bitrix\Main\Engine\Response\Component;

return new Component('vendor:post.list', '.default', ['SECTION_ID' => 12]);
// Response with component HTML + js/css assets — understood by BX.ajax.runAction
```

### Files

```php
use Bitrix\Main\Engine\Response\BFile;          // from b_file table
return BFile::createByFileId($fileId);

use Bitrix\Main\Engine\Response\ResizedImage;
return ResizedImage::createByImageId($fileId, 300, 300);

use Bitrix\Main\Engine\Response\Zip\Archive;
use Bitrix\Main\Engine\Response\Zip\ArchiveEntry;

$archive = new Archive('report.zip');
$archive->addEntry(ArchiveEntry::createFromFileId($fileId));
return $archive;
// For nginx with mod_zip — delivery without PHP overhead
```

### HTML Page

```php
use Bitrix\Main\Engine\Response\Html;
return new Html('<h1>Hi</h1>');
```

## Checklist

- [ ] `Context` / request API instead of `$_GET`/`$_POST`/`$_COOKIE`/`$_SERVER`.
- [ ] Specific getters (`getQuery`/`getPost`/…) when the source is known; JSON via framework APIs.
- [ ] Response uses typed classes / helpers (`Json`, `AjaxJson`, `Redirect`, `BFile`) — not raw `header()`.
- [ ] Cookies via `Cookie` with `HttpOnly` and `Secure`; headers via `addHeader`.
- [ ] `crypto[crypto_key]` is set in `.settings.php` wherever `CryptoCookie` runs (missing key = fatal `SystemException`).
- [ ] URLs via `Uri`; opaque ids via `UuidGenerator::generateV4()`.
- [ ] Input treated as untrusted (still validate); large files via `BFile` / `Archive`.

## Encrypted Cookies

`Bitrix\Main\Web\CryptoCookie` stores values encrypted on the client. Requires `crypto` key in `.settings.php`:

```php
'crypto' => [
    'value' => ['crypto_key' => '...'],  // generate a strong random key; keep outside git
    'readonly' => true,
],
```

```php
use Bitrix\Main\Web\Cookie;
use Bitrix\Main\Web\CryptoCookie;
use Bitrix\Main\Context;

$cookie = new CryptoCookie('vendor_token', $token, time() + 86400);
$cookie->setHttpOnly(true);
$cookie->setSecure(true);
$cookie->setSameSite('Lax');

Context::getCurrent()->getResponse()->addCookie($cookie);
```

Reading: `$request->getCookie('vendor_token')` — kernel decrypts automatically when `crypto_key` is configured.

**No `crypto[crypto_key]` → fatal `SystemException`** ("There is no crypto[crypto_key] in .settings.php. Generate it.") — thrown by the kernel when an encrypted cookie is processed (`bitrix/modules/main/lib/web/cookiescrypter.php`). Provision the key in every environment that serves `CryptoCookie`; if encryption is optional for a value, use plain `Cookie`.

For regular (non-encrypted) cookies use `Bitrix\Main\Web\Cookie` with the same security flags. CSRF and cookie policy details: skill `bitrix-security`. Kernel reference: `bitrix/modules/main/lib/web/cookie.php`, `cryptocookie.php` (if present in the project).
