# Tablet map

## Naming: `DataManager` vs `*Table`

- `\Bitrix\Main\ORM\Data\DataManager` — **base class** for all tablets (do not put business entities directly on it).
- Concrete tablets are named `SomethingTable` and extend `DataManager` (`PostTable`).
- The name **without** `Table` is reserved for the entity object class (`Post` / generated `EO_Post`).

All project tablets live in `/local/modules/<m>/lib/Model/`.

Generation:

```bash
php bitrix/bitrix.php make:tablet my_post vendor.module
php bitrix/bitrix.php orm:annotate -m vendor.module  # IDE annotations
```

## Tablet Skeleton

```php
<?php declare(strict_types=1);

namespace Vendor\Module\Model;

use Bitrix\Main\ORM\Data\DataManager;
use Bitrix\Main\ORM\Fields;
use Bitrix\Main\ORM\Fields\Validators;
use Bitrix\Main\Localization\Loc;

final class PostTable extends DataManager
{
    public static function getTableName(): string
    {
        return 'vendor_module_post';
    }

    public static function getUfId(): string
    {
        return 'VENDOR_MODULE_POST'; // if user fields are present
    }

    public static function isCacheable(): bool
    {
        return true;
    }

    public static function getMap(): array
    {
        return [
            (new Fields\IntegerField('ID'))
                ->configurePrimary()
                ->configureAutocomplete(),

            (new Fields\StringField('TITLE'))
                ->configureRequired()
                ->configureSize(255)
                ->addValidator(new Validators\LengthValidator(null, 255)),

            (new Fields\TextField('BODY'))
                ->configureNullable(),

            (new Fields\BooleanField('ACTIVE'))
                ->configureValues('N', 'Y')
                ->configureDefaultValue('Y'),

            (new Fields\DatetimeField('CREATED_AT'))
                ->configureRequired()
                ->configureDefaultValue(fn () => new \Bitrix\Main\Type\DateTime()),

            (new Fields\IntegerField('AUTHOR_ID'))
                ->configureRequired(),

            (new Fields\Relations\Reference(
                'AUTHOR',
                \Bitrix\Main\UserTable::class,
                ['=this.AUTHOR_ID' => 'ref.ID'],
            ))->configureJoinType('LEFT'),
        ];
    }
}
```

**Configuration methods instead of arrays**: `configureRequired`, `configurePrimary`, `configureAutocomplete`, `configureNullable`, `configureSize`, `configureDefaultValue`, `configureColumnName`, `configureTitle`. The old format with array `['primary' => true, 'required' => true]` still works, but prefer fluent API in new code.

## Field Types

- `IntegerField`, `FloatField`, `DecimalField` — numeric.
- `StringField`, `TextField` — strings/texts.
- `BooleanField` — `configureValues('N', 'Y')` stores Y/N.
- `DateField`, `DatetimeField` — return `Bitrix\Main\Type\Date`/`DateTime`.
- `EnumField` — `configureValues(['draft', 'published'])`.
- `ArrayField` — array, with its own serializer.
- `CryptoField`, `SecretField` — built-in encryption (see `bitrix-security`).
- `ExpressionField('FULL_NAME', 'CONCAT(%s, " ", %s)', ['NAME', 'LAST_NAME'])` — computed field.

## Relations

```php
(new Fields\Relations\Reference('AUTHOR', UserTable::class, ['=this.AUTHOR_ID' => 'ref.ID']))
    ->configureJoinType('LEFT'),

(new Fields\Relations\OneToMany('COMMENTS', CommentTable::class, 'POST'))
    ->configureJoinType('LEFT'),

(new Fields\Relations\ManyToMany('TAGS', TagTable::class))
    ->configureTableName('vendor_module_post_tag')
    ->configureLocalPrimary('ID', 'POST_ID')
    ->configureRemotePrimary('ID', 'TAG_ID'),
```

## User Fields (UF)

Prefer `getUfId(): string` on the tablet. When non-null, UF fields are attached automatically and usable in `select` / `filter`; on objects use `get('UF_FIELD')` / `set('UF_FIELD', $v)`.

`Bitrix\Main\Entity\UField` exists but is **deprecated** (`main/include/deprecated/ufield.php`) — do not use it in new code; rely on `getUfId()` + the user field manager.
