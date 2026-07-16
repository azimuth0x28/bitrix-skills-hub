# JWT, crypto, access, cookies

## JWT / JWK

Prefer framework-native `Bitrix\Main\Web\JWT` and `Bitrix\Main\Web\JWK` over hand-rolled `header.payload.signature` or local `base64UrlEncode` helpers.

Rules:

- Issue with `JWT::encode()`; verify with `JWT::decode($token, $key, $allowedAlgs)` — **always** pass an algorithm allowlist; never trust `alg` from the token header alone.
- Always set `exp` and `iat` (and other claims your contract needs). Payload must be JSON-safe scalars/arrays — not complex objects.
- Secrets / private keys: `.settings_extra.php` or env — not git-tracked `.settings.php`.
- JOSE unpadded Base64 URL-safe: `JWT::urlsafeB64Encode()` / `urlsafeB64Decode()` — not generic `base64_*` and not for arbitrary MIME blobs.
- RSA public keys from JWKS: `JWK::parseKeySet()` / `JWK::parseKey()`, then `JWT::decode()`. `JWK` is a public-key helper, not a full key-management API (no private-key constructor for every `kty`).
- When verifying with a key set that uses `kid`, pass the keyed set from `parseKeySet` into `decode` — do not reimplement key selection.

```php
use Bitrix\Main\Web\JWT;
use Bitrix\Main\Web\JWK;

$token = JWT::encode([
    'sub' => $userId,
    'iat' => time(),
    'exp' => time() + 3600,
], $secret, 'HS256');

$decoded = JWT::decode($token, $secret, ['HS256']);

// OpenID / JWKS:
$keys = JWK::parseKeySet($jwks);
$decoded = JWT::decode($jwt, $keys, ['RS256']);
```

## Access Rights

### Basic Checks

```php
global $USER;

if (!$USER->IsAuthorized()) { return; }
if (!$USER->IsAdmin()) { /* ... */ }

if (!$USER->CanDoOperation('edit_own_profile')) { /* ... */ }
```

### Module Permissions

```php
$module = 'vendor.blog';
$rights = \CMain::GetUserRight($module, $USER->GetUserGroupArray());
if ($rights < 'W') { /* ... */ }
```

### Controller Checks

Use `ActionFilter\Authentication` and your own filter based on `Bitrix\Main\Engine\ActionFilter\Base`. Example:

```php
final class RequireRole extends \Bitrix\Main\Engine\ActionFilter\Base
{
    public function __construct(private readonly string $role) { parent::__construct(); }

    public function onBeforeAction(\Bitrix\Main\Event $event)
    {
        global $USER;
        if (!$USER->IsAuthorized() || !in_array($this->role, $USER->GetUserGroupArray(), true))
        {
            $this->errorCollection->add([new \Bitrix\Main\Error('Forbidden', 'ACCESS_DENIED')]);
            return new \Bitrix\Main\EventResult(\Bitrix\Main\EventResult::ERROR, null, null, $this);
        }
        return null;
    }
}
```

### `access` Module

For complex ACL — use `access` module, roles, and permission providers (`Access\Role`, `Access\AccessibleItem`).

## Secure Cookies

```php
$response = \Bitrix\Main\Context::getCurrent()->getResponse();
$cookie = new \Bitrix\Main\Web\Cookie('VENDOR_TOKEN', $token, time() + 86400);
$cookie->setHttpOnly(true);
$cookie->setSecure(true);
$cookie->setSpread(\Bitrix\Main\Web\Cookie::SPREAD_DOMAIN); // if needed for all subdomains
$response->addCookie($cookie);
```

Use `HttpOnly` + `Secure` + `SameSite=Lax/Strict`. Do not put access tokens in `localStorage`.

## Value Encryption

- `CryptoField('SECRET')` — tablet field, encrypted transparently.
- `SecretField('TOKEN')` — not returned on `select = '*'`.
- Custom encryption: `Bitrix\Main\Security\Cipher`.

## Miscellaneous

- **Proactive protection** (`proactive` firewall) — scans suspicious request parameters; do not disable without reason.
- **Two-factor authentication** — enabled for admins by default; keep it.
- **Captcha** — `\Bitrix\Main\Captcha` / `CCaptcha` for public forms.
- **Frame protection** — `X-Frame-Options` / CSP headers via kernel settings.
- **Access control module** (`access`) — roles, `Access\Role`, `Access\AccessibleItem` for complex ACL.
- **`crypto` section** in `.settings.php` — encryption keys for cookies and `CryptoField`.
- Store secrets in `.settings_extra.php` and environment variables, **not** in `.settings.php` under git.

## Checklist

- [ ] AJAX controller actions rely on `Csrf` (`SCOPE_AJAX`); REST/other scopes have an explicit CSRF/auth check.
- [ ] External URLs from user input use `HttpClient` with timeouts and `privateIp => false` (plus host whitelist where possible).
- [ ] In ORM queries, field names and operators are taken from a whitelist, not from the request.
- [ ] There is no concatenation with user input in `SqlExpression`/`ExpressionField`/`runtime`.
- [ ] In templates, everything coming from the user is via `htmlspecialcharsbx`.
- [ ] Administrative actions check `$USER->IsAdmin()` or specific `CanDoOperation`.
- [ ] Cookies with tokens are `HttpOnly`, `Secure`, `SameSite`.
- [ ] JWT uses `JWT::encode`/`decode` with an explicit algorithm allowlist; JWKS via `JWK::parseKeySet`.
- [ ] Secrets are not committed; access to `.settings_extra.php` is restricted.
