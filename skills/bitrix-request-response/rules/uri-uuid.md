# Uri and UuidGenerator

## Uri

Prefer `Bitrix\Main\Web\Uri` over `parse_url()` + string concat when reading or rebuilding URLs.

```php
use Bitrix\Main\Web\Uri;

$uri = new Uri('/company/personal/user/15/?tab=tasks');
$uri->addParams(['from' => 'invite', 'success' => 'Y']);
$url = (string)$uri;

// Keep query names with dots/spaces:
$uri->addParams(['a.b' => '1'], preserveDots: true);
$uri->deleteParams(['utm_source']);

$absolute = (new Uri('/path/'))->toAbsolute();
```

Also: `resolveRelativeUri()`, IDN via `convertToPunycode()` / `convertToUnicode()`, `isPathTraversal()` for user-supplied paths. There is no public `getQueryParams()` — take `getQuery()` and `parse_str` only when you need an array. Raw `foo=1&bar=2` payloads (no URL parts) may skip `Uri`.

## UuidGenerator

For new random opaque identifiers (correlation id, upload token, public proxy id) use `Bitrix\Main\UuidGenerator::generateV4()` — not `uniqid()`, manual `random_bytes` assembly, or a local helper.

```php
use Bitrix\Main\UuidGenerator;

$id = UuidGenerator::generateV4(); // lowercase, 36 chars, with hyphens
```

- Not for deterministic IDs derived from domain input.
- Legacy `{uuid}` wrappers: generate with `generateV4()`, wrap only at the boundary.
- External UUIDs used for lookup/access must be validated separately — generation ≠ trust.
- `uniqid()` only for local page/request-level DOM-ish ids without crypto/uniqueness requirements.

Storage of TTL keys that *use* a UUID: see `bitrix-storage`.
