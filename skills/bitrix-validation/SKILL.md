---
name: bitrix-validation
description: "Covers input data validation in Bitrix — ValidationService (main.validation.service), attributes #[NotEmpty], #[Email], #[Length], #[Range], #[RegExp], #[InArray], Request DTO via ValidationParameter autowire, rule attributes on controller action parameters, custom validators via AbstractPropertyValidationAttribute + ValidatorInterface, aggregation of errors in ErrorCollection. Applied when checking input of controllers, services and CLI commands, validation of forms, DTO and action method parameters. Key terms — ValidationService, NotEmpty, Email, Length, ValidationParameter, Request DTO, validator, constraint."
---

# Validation in Bitrix

The `Bitrix\Main\Validation\ValidationService` service validates objects using PHP 8 attributes. Any object with typed properties can be checked to obtain a `ValidationResult` with a list of errors.

Service id in `ServiceLocator`: **`main.validation.service`** (kernel registration). There is **no** `validation` section in `.settings.php` for registering rules.

## First-level Attributes

| Attribute | What it checks |
| --- | --- |
| `#[NotEmpty]` | Not empty (`!empty`); options `allowZero`, `allowSpaces` |
| `#[Length(min, max)]` | String length |
| `#[Min(n)]` / `#[Max(n)]` / `#[Range(min, max)]` | Numeric constraints |
| `#[PositiveNumber]` | Numeric value >= 1 (internally `MinValidator(1)`, so `0.5` fails) |
| `#[Email]` / `#[Phone]` / `#[PhoneOrEmail]` | Format; `Email` options: `strict`, `domainCheck` (passed to `check_email()`) |
| `#[Url]` | URL (no options besides `errorMessage`) |
| `#[RegExp('/pattern/')]` | Regular expression (attribute name is **`RegExp`**, not `Regex`); options `flags`, `offset` are passed to `preg_match()` |
| `#[InArray($validValues)]` | Value is one of the allowed list items; options `strict` (strict `in_array`), `showValues` (list allowed values in the error) |
| `#[Json]` | String is valid JSON |
| `#[Validatable]` | Recursively validate nested object; `iterable: true` validates each element of an array of objects |
| `#[ElementsType(...)]` | Type of array elements: `className: Dto::class` or a `Type` enum case (`Bitrix\Main\Validation\Rule\Enum\Type::Integer` / `String` / `Float` / `Numeric`; `Numeric` = anything `is_numeric()`, incl. numeric strings) |
| `#[AtLeastOnePropertyNotEmpty(['name', 'email'])]` | At least one of the fields is filled (on class) |
| `#[OnlyOneOfPropertyRequired(['name', 'email'])]` | Exactly one of the listed fields is filled (on class) |

Each attribute accepts an optional **`errorMessage`** for a custom error text (not `message`). For localized texts pass a `Bitrix\Main\Localization\LocalizableMessage('PHRASE_CODE', phraseSrcFile: __FILE__)` instead of a string — the phrase is defined in the matching `lang/<code>/` file (`phraseSrcFile` is optional: when omitted it is guessed from the backtrace). Every rule also accepts `groups: [...]`; `ValidationService::validate($object, $group)` then runs rules of that group plus all ungrouped rules; without a group everything runs.

Nullable handling: an **uninitialized** nullable property is skipped by validation; an uninitialized **non-nullable** property produces an error (`MAIN_VALIDATION_EMPTY_PROPERTY`); a property explicitly assigned `null` counts as initialized and `null` is passed to its validators.

## DTO with Attributes

```php
<?php declare(strict_types=1);

namespace Vendor\Module\Application\Dto;

use Bitrix\Main\Validation\Rule\NotEmpty;
use Bitrix\Main\Validation\Rule\Length;
use Bitrix\Main\Validation\Rule\Email;
use Bitrix\Main\Validation\Rule\Range;
use Bitrix\Main\Validation\Rule\InArray;

final class CreateUserDto
{
    public function __construct(
        #[NotEmpty, Length(min: 2, max: 64)]
        public readonly string $name,

        #[NotEmpty, Email]
        public readonly string $email,

        #[Range(min: 18, max: 120)]
        public readonly int $age,

        #[InArray(['user', 'admin'])]
        public readonly string $role,
    ) {}
}
```

## Direct Validation in Service

```php
use Bitrix\Main\DI\ServiceLocator;
use Bitrix\Main\Validation\ValidationService;

final class UserService
{
    private readonly ValidationService $validator;

    public function __construct()
    {
        $this->validator = ServiceLocator::getInstance()->get('main.validation.service');
    }

    public function register(CreateUserDto $dto): \Bitrix\Main\Result
    {
        $result = new \Bitrix\Main\Result();
        $validation = $this->validator->validate($dto);

        if (!$validation->isSuccess())
        {
            foreach ($validation->getErrors() as $error)
            {
                // getCode() holds the property path: 'email', 'items.0.name'
                $result->addError(new \Bitrix\Main\Error(
                    $error->getMessage(),
                    $error->getCode(),
                ));
            }
            return $result;
        }

        // ...
        return $result;
    }
}
```

Or inject via `constructorParams` / factory when registering the service, still resolving `'main.validation.service'`.

## Scalar Action Parameters

Rule attributes can be placed directly on controller action parameters — argument binding validates the value **before** the action is called:

```php
use Bitrix\Main\Engine\Controller;
use Bitrix\Main\Validation\Rule\PositiveNumber;

final class User extends Controller
{
    public function getAction(#[PositiveNumber] int $id): array
    {
        return ['id' => $id];
    }
}
```

## Request DTO in Controller (`ValidationParameter` autowire)

For a set of related values create a DTO and register it via `getAutoWiredParameters()` with `Bitrix\Main\Validation\Engine\AutoWire\ValidationParameter` (an AutoWire rule, **not** a parameter attribute). It builds the DTO through the given factory and validates it before it reaches the action; on validation errors the action is not called and the controller returns the errors.

```php
use Bitrix\Main\Engine\Controller;
use Bitrix\Main\Validation\Engine\AutoWire\ValidationParameter;
use Vendor\Module\Application\Service\PostService;

final class Post extends Controller
{
    public function getAutoWiredParameters(): array
    {
        return [
            new ValidationParameter(
                CreatePostRequest::class,
                fn () => CreatePostRequest::createFromRequest($this->getRequest()),
            ),
        ];
    }

    public function createAction(CreatePostRequest $request, PostService $postService): array
    {
        // We only get here if validation was successful.
        // Otherwise, the controller will return errors automatically.
        $result = $postService->create($request);

        if (!$result->isSuccess())
        {
            $this->addErrors($result->getErrors());
            return [];
        }

        return ['id' => $result->getId()];
    }
}
```

```php
namespace Vendor\Blog\Application\Request;

use Bitrix\Main\Validation\Rule\NotEmpty;
use Bitrix\Main\Validation\Rule\Length;

final class CreatePostRequest
{
    public function __construct(
        #[NotEmpty, Length(min: 1, max: 255)]
        public readonly ?string $title = null,

        public readonly ?string $body = null,
    ) {}

    public static function createFromRequest(\Bitrix\Main\Request $request): self
    {
        return new self(
            $request->get('title'),
            $request->get('body'),
        );
    }
}
```

Keep DTO properties nullable with `null` defaults so construction from a raw request never fails — the rules (`NotEmpty`, etc.) report missing values instead.

Generation: `php bitrix/bitrix.php make:request CreatePost -m vendor.blog --fields=title,body` (**Since main 25.900**).

## Class-Level Attributes

```php
use Bitrix\Main\Validation\Rule\AtLeastOnePropertyNotEmpty;

#[AtLeastOnePropertyNotEmpty(['email', 'phone'])]
final readonly class ContactRequest
{
    public function __construct(
        public ?string $email = null,
        public ?string $phone = null,
    ) {}
}
```

## Collections

```php
use Bitrix\Main\Validation\Rule\Recursive\Validatable;
use Bitrix\Main\Validation\Rule\ElementsType;

final class OrderDto
{
    /**
     * @var OrderItemDto[]
     */
    #[ElementsType(className: OrderItemDto::class)]
    #[Validatable(iterable: true)]
    public array $items = [];
}
```

## Custom Validator

There is **no** `.settings.php` `validation` section. Custom rules are PHP attributes that extend `AbstractPropertyValidationAttribute` and return validators from `getValidators()`.

1. Attribute + `getValidators()`:

    ```php
    <?php declare(strict_types=1);

    namespace Vendor\Module\Validation\Rule;

    use Attribute;
    use Bitrix\Main\Localization\LocalizableMessageInterface;
    use Bitrix\Main\Validation\Rule\AbstractPropertyValidationAttribute;
    use Bitrix\Main\Validation\Validator\ValidatorInterface;
    use Bitrix\Main\Validation\ValidationResult;
    use Bitrix\Main\Validation\ValidationError;

    #[Attribute(Attribute::TARGET_PROPERTY | Attribute::TARGET_PARAMETER)]
    final class EvenNumber extends AbstractPropertyValidationAttribute
    {
        public function __construct(
            // type must match the inherited trait property exactly
            protected string|LocalizableMessageInterface|null $errorMessage = null,
        ) {}

        protected function getValidators(): array
        {
            // $this->errorMessage is applied automatically by the base class
            // (replaceWithCustomError from ValidationErrorTrait)
            return [
                new EvenNumberValidator(),
            ];
        }
    }

    final class EvenNumberValidator implements ValidatorInterface
    {
        public function validate(mixed $value): ValidationResult
        {
            $result = new ValidationResult();
            if (!is_int($value) || $value % 2 !== 0)
            {
                $result->addError(new ValidationError(
                    'Number must be even',
                    'EVEN_NUMBER', // the property path is prepended later: 'age.EVEN_NUMBER'
                    failedValidator: $this,
                ));
            }

            return $result;
        }
    }
    ```

2. Use the attribute on DTO properties — no kernel registration step:

    ```php
    #[EvenNumber(errorMessage: 'Age must be even')]
    public readonly int $age;
    ```

`ValidatorInterface::validate(mixed $value): ValidationResult` — **no** `Rule` parameter.

In attributes extending the abstract classes, `$errorMessage` **must** be typed `string|LocalizableMessageInterface|null` — the base `ValidationErrorTrait` declares the property with exactly this type, and PHP property types are invariant (a narrower `?string` is a fatal error). Class attributes (checks across several properties) extend `AbstractClassValidationAttribute` / implement `ClassValidationAttributeInterface::validateObject(object $object)`.

## Retrieving Validation Result

`ValidationResult` extends `Bitrix\Main\Result` and contains `ValidationError` objects (extend `Bitrix\Main\Error`). Each error has:
- `getMessage()`: localized message.
- `getCode()`: **property path** that failed — the service prefixes the property name (and array index for iterables), e.g. `email`, `items.0.name`; a code set inside a validator is appended after a dot (`age.EVEN_NUMBER`).
- `getFailedValidator()`: the `ValidatorInterface` instance that produced the error (or `null`).

There is **no** `getField()` method — the field name lives in the code.

## Checklist

- [ ] Validation is handled via PHP 8 attributes.
- [ ] DTOs are used for complex input structures.
- [ ] Request DTOs are wired via `ValidationParameter` in `getAutoWiredParameters()`; scalar action params carry rule attributes directly.
- [ ] DTO properties are nullable with `null` defaults; remember: uninitialized nullable props are skipped, explicit `null` is validated.
- [ ] Custom rules extend `AbstractPropertyValidationAttribute` and implement `getValidators()` — no `.settings.php` `validation` section.
- [ ] Attribute names use `RegExp` / `errorMessage` (not `Regex` / `message`).
- [ ] `ValidationService` is retrieved as `main.validation.service`.
- [ ] Error messages are localized or descriptive.
- [ ] Collections of DTOs are validated with `#[ElementsType(className: ...)]` + `#[Validatable(iterable: true)]`.
