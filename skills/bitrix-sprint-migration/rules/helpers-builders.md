# Helpers and builders

Access helpers from any `Version`:

```php
$helper = $this->getHelperManager();
$helper->Iblock()->saveIblock([...]);
```

A helper throws `HelperException` if its Bitrix module is not installed/enabled.

## Helper map

| Call | Covers | Typical methods |
| --- | --- | --- |
| `Iblock()` | Iblock types, iblocks, fields, properties, sections, elements, permissions | `saveIblockType`, `saveIblock`, `saveProperty`, `saveSection`, `saveElement`, `deleteIblockIfExists` |
| `Hlblock()` | Highload blocks, UF fields, elements, permissions | `saveHlblock`, `saveField`, `saveElementByXmlId`, `deleteHlblock` |
| `UserTypeEntity()` | User fields (HL / user / other `ENTITY_ID`) | `saveUserTypeEntity`, `addUserTypeEntitiesIfNotExists`, `deleteUserTypeEntitiesIfExists` |
| `UserGroup()` | Groups | `saveGroup`, `deleteGroup` |
| `User()` | Users (rare in migrations) | helper methods on user entity |
| `Agent()` | Agents | `saveAgent`, `deleteAgent` |
| `Option()` | `COption` / module options | `saveOption`, `deleteOption` |
| `Event()` | Mail events / templates | `saveEvent`, `saveEventType` |
| `Form()` | Web forms | form export/save helpers |
| `Forum()` / `Blog()` / `Vote()` / `Subscribe()` | Corresponding modules | module-specific `save*` |
| `Site()` / `Lang()` / `Culture()` | Sites, languages, cultures | `saveSite`, language helpers |
| `UserOptions()` | User / grid options | export/save UI options |
| `Sql()` | Controlled SQL helpers | use sparingly; prefer ORM |
| `Medialib()` / `MedialibExchange()` | Media library | collections/items |
| `IblockExchange()` / `HlblockExchange()` | Exchange-backed element sync | used with exchange dirs |
| `OrderProperties()` / `SaleDiscount()` / `DeliveryService()` | Sale-related | when `sale` is present |
| `Task()` / `Text()` | Tasks / text utilities | niche |

For iblock/HL **domain semantics** beyond migration helpers, also open
`bitrix-iblocks` / `bitrix-highloadblock`.

## Method naming cheatsheet

- **`save*`** — upsert to match exported/desired state (best default for schema).
- **`add*IfNotExists`** — create once; will not update drifted fields.
- **`*IfExists`** — safe get/delete when absence is OK.
- Identify entities by **CODE / XML_ID / NAME**, not by numeric ID from another
  environment.

## Builders (`run`)

Builders generate a migration (and often exchange files) from the current DB
state. Prefer them for large iblock/HL/option exports instead of hand-writing
arrays.

```bash
# {migrate} = local/... or bitrix/.../tools/migrate.php — see rules/cli-config.md
php "$MIGRATE" run IblockBuilder
```

Default builder keys (config `version_builders`):

| Builder key | Use for |
| --- | --- |
| `BlankBuilder` | Empty `Version` stub |
| `IblockBuilder` | Iblock structure |
| `IblockPropertyBuilder` / `IblockPropertyDeleteBuilder` | Properties |
| `IblockCategoryBuilder` | Sections |
| `IblockElementsBuilder` | Elements (+ exchange) |
| `IblockDeleteBuilder` | Delete iblock migration |
| `HlblockBuilder` / `HlblockElementsBuilder` | HL structure / elements |
| `UserTypeEntitiesBuilder` | UF entities |
| `UserGroupBuilder` | Groups |
| `AgentBuilder` | Agents |
| `OptionBuilder` | Options |
| `EventBuilder` | Mail events |
| `FormBuilder` / `ForumBuilder` / `VoteBuilder` / `SubscribeBuilder` | Module entities |
| `UserOptionsBuilder` | Admin UI options |
| `LanguageBuilder` | Languages |
| `OrderPropertiesBuilder` / `SaleDiscountBuilder` | Sale |
| `MedialibElementsBuilder` | Media library |
| `CacheCleanerBuilder` | Cache clean step |
| `MarkerBuilder` / `TransferBuilder` | Tagging / transfer between configs |

After a builder run: review the generated PHP, commit migration (+ exchange dir
if present), then `up` on other environments.

## Examples in the module

Read-only references under `{module}` (do not copy into product blindly):

- `{module}/examples/*.php`
- `{module}/templates/*.php`

## Extending helpers

`HelperManager::registerHelper($name, $class)` registers a custom helper class
extending `Sprint\Migration\Helper`. Use only when a project maintains a shared
base migration layer; otherwise keep domain logic in services called from `up()`.
