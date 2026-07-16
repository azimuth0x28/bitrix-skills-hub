# Application::addBackgroundJob

## `Application::addBackgroundJob()`

Deferred call **after** sending the response (before `fastcgi_finish_request` / in `onAfterEpilog`). Ideal for metrics, welcome emails, or other short tail work.

Signature: `addBackgroundJob(callable $job, array $args = [], $priority = Application::JOB_PRIORITY_NORMAL)`.

Priorities:

| Constant | Value |
| --- | --- |
| `Application::JOB_PRIORITY_NORMAL` | `100` |
| `Application::JOB_PRIORITY_LOW` | `50` |

```php
use Bitrix\Main\Application;

Application::getInstance()->addBackgroundJob(
    static function () use ($userId): void {
        \Vendor\Module\Application\Service\Notifier::fromContainer()->sendWelcome($userId);
    },
    [],
    Application::JOB_PRIORITY_NORMAL,
);
```

### Constraints

- Still a single PHP process. Long tasks degrade worker release time.
- No delivery guarantee: if the process crashes — the task won't execute.
- Not suitable if retries and parallelism are needed — use `Messenger`.
