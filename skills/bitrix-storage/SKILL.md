---
name: bitrix-storage
description: Covers choosing between Option, Persistent Storage, Cache and sessions — PersistentStorageInterface (main 25.1100+), DeferredStorageDecorator, Bitrix\Main\Config\Option for permanent module settings. Applied when deciding where to put config vs TTL state vs derived cache. Key terms — Option, PersistentStorage, DeferredStorageDecorator, Cache, TTL, default_option.php.
---

# Storage Boundaries: Option / Persistent / Cache

## Decision guide

| Need | Use |
| --- | --- |
| Deploy-time / secrets / env | `.settings.php` / `.settings_extra.php` / env (`bitrix-settings`) |
| Permanent module/portal setting (admin-editable, no TTL) | `Bitrix\Main\Config\Option` + `default_option.php` |
| Guaranteed TTL server-side state between hits | `PersistentStorageInterface` (**Since main 25.1100**) |
| Many writes per hit; loss OK on crash | `DeferredStorageDecorator` over persistent storage |
| Derived data that may be evicted anytime | `Cache` / `ManagedCache` / `TaggedCache` (`bitrix-caching`) |
| Per-user interactive session | `Application::getSession()` (`bitrix-sessions`) |
| Large blobs | Files in `/upload/` |

Do **not** use `Option` as chatty operational storage (progress, checkpoints, one-time tokens). Do **not** use cache when the value must survive eviction. Do **not** put secrets in Persistent Storage — use crypto / env.

---

# Option (permanent configuration)

Use `Bitrix\Main\Config\Option` for stable module/portal policy: feature flags, intervals, site overrides. Prefer it over legacy `COption` in new code.

```php
use Bitrix\Main\Config\Option;

// default_option.php
// $vendor_module_default_option = ['sync_interval' => '60'];

$seconds = (int)Option::get('vendor.module', 'sync_interval');
Option::set('vendor.module', 'sync_interval', (string)$seconds);

// Stored value only (null if missing) — not fallback/default:
$real = Option::getRealValue('vendor.module', 'title', $siteId);

// Bulk read (migrations/export) — not for single-key hot path:
$all = Option::getForModule('vendor.module');
```

Rules:

- Values are **strings** — cast at the boundary.
- Empty `siteId` = global; explicit `siteId` = site override. Do not rely on implicit current site when you need a global setting.
- Keep defaults in `default_option.php`, not scattered magic strings.
- `Option::set()` flushes module option cache, may load `option_triggers.php`, fires `OnAfterSetOption` — avoid high-frequency writes.
- `Option::delete()` for intentional reset with a clear name/site filter — not “delete then set” as a normal update.
- UI options page: module `options.php` (see `bitrix-modules`).

---

# Persistent Storage (main 25.1100+)

For data that must survive for a guaranteed period — unlike cache (may evict anytime) or sessions (cleared on logout).

## Interfaces

- `StorageInterface` — extends PSR-16 `CacheInterface`.
- `PersistentStorageInterface` — adds guaranteed TTL retention.
- `ConnectionBasedPersistentStorage` — DB-backed implementation.
- `DeferredStorageDecorator` — batches writes until end of hit (faster, but data lost on crash).

## Usage

```php
$storage = \Bitrix\Main\DI\ServiceLocator::getInstance()
    ->get(\Bitrix\Main\Data\Storage\PersistentStorageInterface::class);

$storage->set('vendor.module.processing.item123', ['status' => 'pending'], 3600);
$data = $storage->get('vendor.module.processing.item123');
$storage->delete('vendor.module.processing.item123');
```

Key format: `module.feature.unique_key` (max 255 chars). Value must be JSON-serializable.

TTL: **required**, must be `> 0` — seconds (`int`) or `\DateInterval`. `null` and non-positive values throw `InvalidTtlException` (**Since main 25.1100**). Max recommended TTL: 604800 (7 days).

## Deferred Storage

```php
$deferred = new \Bitrix\Main\Data\Storage\DeferredStorageDecorator(
    $persistentStorage,
);
$deferred->set('key', $value, 3600);
// Writes flushed at end of hit
```

## Checklist

- [ ] Chosen layer matches decision guide (Option vs Persistent vs Cache vs session).
- [ ] Module defaults live in `default_option.php`; Option values cast at read/write.
- [ ] Persistent keys follow `module.feature.id`; TTL always positive; ≤ 7 days unless business requires otherwise.
- [ ] Values are JSON-serializable; secrets not stored in Persistent Storage.
- [ ] Option is not used for high-churn runtime state.
