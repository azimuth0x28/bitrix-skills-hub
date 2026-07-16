---
name: bitrix-validation
description: "Covers input data validation in Bitrix — ValidationService (main.validation.service), attributes #[NotEmpty], #[Email], #[Length], #[Range], #[RegExp], #[InArray], Request DTO with #[ValidationParameter], custom validators via AbstractPropertyValidationAttribute + ValidatorInterface, aggregation of errors in ErrorCollection. Applied when checking input of controllers, services and CLI commands, validation of forms, DTO and action method parameters. Key terms — ValidationService, NotEmpty, Email, Length, ValidationParameter, Request DTO, validator, constraint."
---

# Validation in Bitrix

The `Bitrix\Main\Validation\ValidationService` service validates objects using PHP 8 attributes. Any object with typed properties can be checked to obtain a `ValidationResult` with a list of errors.

Service id in `ServiceLocator`: **`main.validation.service`** (kernel registration). There is **no** `validation` section in `.settings.php` for registering rules.

## First-level Attributes

| Attribute | What it checks |
| --- | --- |
| `#[NotEmpty]` | Not empty (`!empty`) |
| `#[Length(min, max)]` | String length |
| `#[Min(n)]` / `#[Max(n)]` / `#[Range(min, max)]` | Numeric constraints |
| `#[PositiveNumber]` | Number > 0 |
| `#[Email]` / `#[Phone]` / `#[PhoneOrEmail]` | Format |
| `#[Url]` | URL (with optional schemes) |
| `#[RegExp('/pattern/')]` | Regular expression (attribute name is **`RegExp`**, not `Regex`) |
| `#[InArray($validValues)]` | Value is one of the allowed list items |
| `#[Json]` | String is valid JSON |
| `#[Validatable]` | Recursively validate nested object |
| `#[ElementsType(Type::class)]` | Type of collection/array elements |
| `#[AtLeastOnePropertyNotEmpty(['name', 'email'])]` | At least one of the fields is filled (on class) |

Each attribute accepts an optional **`errorMessage`** for a custom error text (not `message`).

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
                $result->addError(new \Bitrix\Main\Error(
                    $error->getMessage(),
                    $error->getCode(),
                    ['field' => $error->getField()],
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

## Request DTO in Controller (`#[ValidationParameter]`)

The controller engine can automatically create a DTO from `GET`/`POST` and validate it.

```php
use Bitrix\Main\Engine\Controller;
use Bitrix\Main\Validation\Engine\ValidationParameter;
use Vendor\Module\Application\Service\PostService;

final class Post extends Controller
{
    public function createAction(
        #[ValidationParameter] CreatePostRequest $request,
        PostService $postService,
    ): array {
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
        public readonly string $title,

        public readonly ?string $body = null,
    ) {}
}
```

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
use Bitrix\Main\Validation\Rule\Validatable;
use Bitrix\Main\Validation\Rule\ElementsType;

final class OrderDto
{
    /**
     * @var OrderItemDto[]
     */
    #[Validatable]
    #[ElementsType(OrderItemDto::class)]
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
    use Bitrix\Main\Validation\Rule\AbstractPropertyValidationAttribute;
    use Bitrix\Main\Validation\Validator\ValidatorInterface;
    use Bitrix\Main\Validation\ValidationResult;
    use Bitrix\Main\Validation\ValidationError;

    #[Attribute(Attribute::TARGET_PROPERTY | Attribute::TARGET_PARAMETER | Attribute::IS_REPEATABLE)]
    final class EvenNumber extends AbstractPropertyValidationAttribute
    {
        public function __construct(
            protected ?string $errorMessage = null,
        ) {}

        protected function getValidators(): array
        {
            return [
                new EvenNumberValidator($this->errorMessage),
            ];
        }
    }

    final class EvenNumberValidator implements ValidatorInterface
    {
        public function __construct(
            private readonly ?string $errorMessage = null,
        ) {}

        public function validate(mixed $value): ValidationResult
        {
            $result = new ValidationResult();
            if (!is_int($value) || $value % 2 !== 0)
            {
                $result->addError(new ValidationError(
                    $this->errorMessage ?? 'Number must be even',
                    'EVEN_NUMBER',
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

## Retrieving Validation Result

The `ValidationResult` object contains a list of `ValidationError`. Each error has:
- `getMessage()`: localized message.
- `getCode()`: error code (e.g., `NOT_EMPTY`).
- `getField()`: property name that failed validation.

## Checklist

- [ ] Validation is handled via PHP 8 attributes.
- [ ] DTOs are used for complex input structures.
- [ ] `#[ValidationParameter]` is used in controllers to automate DTO creation and validation.
- [ ] Custom rules extend `AbstractPropertyValidationAttribute` and implement `getValidators()` — no `.settings.php` `validation` section.
- [ ] Attribute names use `RegExp` / `errorMessage` (not `Regex` / `message`).
- [ ] `ValidationService` is retrieved as `main.validation.service`.
- [ ] Error messages are localized or descriptive.
- [ ] Collections are validated recursively using `#[Validatable]` and `#[ElementsType]`.
