# CAgent agents

## Agents (`CAgent`)

```php
\CAgent::AddAgent(
    name: \Vendor\Module\Cli\Agent\QueueAgent::class . '::run();',
    module: 'vendor.module',
    period: 'N',        // 'Y' — periodic (always by interval), 'N' — shift next_exec
    interval: 300,      // seconds
    datecheck: '',
    active: 'Y',
    next_exec: '',
    sort: 100,
    existError: true,
);
```

Agent method:

```php
namespace Vendor\Module\Cli\Agent;

final class QueueAgent
{
    public static function run(): string
    {
        \Bitrix\Main\Loader::includeModule('vendor.module');
        \Bitrix\Main\DI\ServiceLocator::getInstance()
            ->get(\Vendor\Module\Application\Service\QueueProcessor::class)
            ->processBatch(limit: 100);

        return self::class . '::run();'; // important: return string for re-registration
    }
}
```

### Rules

- An agent works either on hits or via cron (Admin Panel → Agent Settings).
- For heavy agents **always** enable cron — otherwise they block user hits.
- An agent running longer than 10 minutes is blocked by the kernel.
- Periodic (`period = 'Y'`) vs non-periodic (`period = 'N'`) agents differ in how `next_exec` is calculated.
- In module's `DoUninstall`: `CAgent::RemoveModuleAgents('vendor.module')`.
- Do not keep state in statics between calls — the process may change.
- Combine `addBackgroundJob` for immediate post-response work with `CAgent` for scheduled retries.

### One-time task for "in 5 minutes"

```php
\CAgent::AddAgent(
    \Vendor\Module\Cli\Agent\SendEmailAgent::class . "::run({$userId});",
    'vendor.module',
    'N',
    60,
    '',
    'Y',
    (new \Bitrix\Main\Type\DateTime())->add('+5 minutes')->toString(),
);
```
