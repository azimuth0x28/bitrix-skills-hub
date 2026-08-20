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

### Multisite

Agents are shared across the whole installation: stored in one database, executed from one common list, with no filtering by site. An agent does not run per site and gets no user/site context.

- Never rely on `SITE_ID` (or any current-site/user context) inside an agent function.
- If the logic is site-specific, pass the site ID explicitly in the agent call: `\Vendor\Module\Cli\Agent\SyncAgent::class . "::run('s2');"` — one registered agent per site if needed.
- When moving agents to cron, do **not** create identical cron jobs per site — cron runs the shared agent list and cannot inject a site context.

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
