# Messenger queues

## Messenger (Message Queues)

> **Alpha status** (**Since main 25.100.300**): API may change without backward compatibility guarantees. Use with caution in production.

Queue = logical channel from sender to handler. Message → broker → receiver processes it.

Components: **message** (DTO), **handler** (`AbstractReceiver`), **broker** (storage), **queue** (named handler binding).

### 1. Message (DTO)

```bash
php bitrix/bitrix.php make:message SendWelcomeEmail -m vendor.module
```

```php
namespace Vendor\Module\Public\Message;

use Bitrix\Main\Messenger\Entity\AbstractMessage;
use Bitrix\Main\Messenger\Entity\MessageInterface;

final class SendWelcomeEmailMessage extends AbstractMessage
{
    public function __construct(
        public readonly int $userId,
        public readonly string $email,
    ) {}

    public static function createFromData(array $data): MessageInterface
    {
        return new self(...$data);
    }
}
```

Requirements:
- JSON-serializable data only: `string`, `int`, `float`, `bool`, `array`.
- Implement `jsonSerialize()` for complex structures.
- Include all data needed at processing time (entity may be deleted before delayed handling).

### 2. Handler

```bash
php bitrix/bitrix.php make:messagehandler SendWelcomeEmail \
    --message-module=vendor.module --handler-module=vendor.module
```

(`make:messagehandler` uses **`--message-module`**, not `--event-module`. The latter belongs to `make:eventhandler`.)

```php
namespace Vendor\Module\Internals\Messenger\Receiver;

use Bitrix\Main\Messenger\Entity\MessageInterface;
use Bitrix\Main\Messenger\Receiver\AbstractReceiver;
use Bitrix\Main\Messenger\Internals\Exception\Receiver\UnprocessableMessageException;
use Vendor\Module\Public\Message\SendWelcomeEmailMessage;

final class SendWelcomeEmailHandler extends AbstractReceiver
{
    public function __construct(
        private readonly \Vendor\Module\Application\Service\Mailer $mailer,
    ) {
        parent::__construct();
    }

    protected function process(MessageInterface $message): void
    {
        if (!$message instanceof SendWelcomeEmailMessage) {
            throw new UnprocessableMessageException($message);
        }

        $this->mailer->sendWelcome($message->userId, $message->email);
    }
}
```

**Handler MUST be registered in module `services`** — `QueueConfig::createReceiver()` resolves it via `ServiceLocator::get($handler)`:

```php
// /local/modules/vendor.module/.settings.php
'services' => [
    'value' => [
        \Vendor\Module\Internals\Messenger\Receiver\SendWelcomeEmailHandler::class => [
            'className' => \Vendor\Module\Internals\Messenger\Receiver\SendWelcomeEmailHandler::class,
        ],
        // or constructor closure / autowire as usual
    ],
    'readonly' => true,
],
```

Handler rules:
- Extend `AbstractReceiver`, implement **`protected function process()`** (not `handle()`).
- Return `void` on success; throw on failure.
- Exception types (namespace `Bitrix\Main\Messenger\Internals\Exception\Receiver\`):
  - `UnprocessableMessageException` — wrong message type (`__construct(MessageInterface $messengerMessage, ...)`)
  - `UnrecoverableMessageException` — no retry
  - `RecoverableMessageException` — temporary, optional `getRetryDelay()`

### 3. Dispatching

```php
$message = new SendWelcomeEmailMessage($userId, $email);
$message->send('vendor_module_queue');

// Delayed processing (1 hour):
use Bitrix\Main\Messenger\Entity\ProcessingParam\DelayParam;
use Bitrix\Main\Messenger\Entity\ProcessingParam\ItemIdParam;

$message->send('vendor_module_queue', [
    new DelayParam(3600),
    new ItemIdParam('welcome-' . $userId),
]);
```

Do **not** use `MessageBus::dispatch()` — the current API is `$message->send('queue_name')`.

### 4. Configuration in `.settings.php`

Global config (`/bitrix/.settings.php` or `/local/.settings.php`) — brokers and cross-module queues:

```php
'messenger' => [
    'value' => [
        'run_mode' => 'web', // 'web' — background jobs on hit; 'cli' — requires messenger:consume
        'brokers' => [
            'default' => [
                'type' => 'db',
                'params' => [
                    'table' => \Bitrix\Main\Messenger\Internals\Storage\Db\Model\MessengerMessageTable::class,
                ],
            ],
        ],
        'queues' => [
            'vendor_module_queue' => [
                'handler' => \Vendor\Module\Internals\Messenger\Receiver\SendWelcomeEmailHandler::class,
            ],
        ],
    ],
    'readonly' => true,
],
```

Module config (`/local/modules/vendor.module/.settings.php`) — module-specific queues:

```php
'messenger' => [
    'value' => [
        'queues' => [
            'vendor_module_queue' => [
                'handler' => \Vendor\Module\Internals\Messenger\Receiver\SendWelcomeEmailHandler::class,
                'limit' => 10,                    // messages per batch (default 50)
                'total_processing_limit' => 50,     // max concurrent (must be >= limit)
                'retry_strategy' => [
                    'max_retries' => 3,
                    'delay' => 5,
                    'multiplier' => 2,
                    'max_delay' => 300,
                ],
            ],
        ],
    ],
    'readonly' => true,
],
```

Notes:
- Only broker type **`db`** is supported currently (not Redis/Doctrine DSN).
- The `default` broker must always exist in global config.
- Put queues in the module `.settings.php` they belong to; global config only for cross-module queues.
- Custom broker table: extend `MessengerMessageTable`, register in `brokers`, create table in module installer.
- Queue `handler` FQCN must also exist under module `services` (see above).

### 5. Consumer (CLI mode)

Set `'run_mode' => 'cli'` and run under Supervisor/systemd:

```bash
php bitrix/bitrix.php messenger:consume vendor_module_queue \
    --time-limit=300 --sleep=1
```

Flags:
- `-t, --time-limit` — process lifetime in seconds.
- `--sleep` — pause between iterations when queue is empty (default 1).

For production with heavy queues, prefer `cli` mode with a supervisor over `web` mode.

## When to Choose What

- **Periodic task by schedule** → `CAgent` + cron mode.
- **"Almost instant" tail after response** (email notification, metric) → `addBackgroundJob`.
- **Reliable processing with retries, high volumes, parallelism** → `Messenger` (**Since 25.100.300**, alpha).
- **Very long one-time data migration** → console command run manually.

## Checklist

- [ ] Background code does not rely on `$_SESSION`/`$_COOKIE` in the hit context.
- [ ] Agents registered by the module are removed in `DoUninstall`.
- [ ] For CLI queues, `time-limit`, supervisor restart, and `run_mode=cli` are configured.
- [ ] Messages contain scalars/DTOs with all data needed at processing time; no `EntityObject` with loaded relations.
- [ ] Handler is registered in `services` and is idempotent: re-processing the same message is safe.
- [ ] `total_processing_limit` >= `limit` in queue config.
- [ ] Errors inside tasks are logged via PSR-3 logger, not silently suppressed.
- [ ] `addBackgroundJob` uses `JOB_PRIORITY_NORMAL` (100) / `JOB_PRIORITY_LOW` (50), not arbitrary `0`.
