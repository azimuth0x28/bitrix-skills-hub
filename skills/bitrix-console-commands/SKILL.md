---
name: bitrix-console-commands
description: Covers Bitrix CLI tools — php bitrix/bitrix.php, generators make:module/make:controller/make:tablet/make:entity/make:service/make:event/make:eventhandler/make:message/make:messagehandler/make:component/make:request, kernel commands (orm:annotate, messenger:consume, translate:index), creating custom commands on Symfony Console and registering them in the console section of module .settings.php. Applied for scaffolding new code, cron tasks, writing custom CLI commands, and running queue workers. Key terms — bitrix.php, make command, Symfony Console, CLI, command, console namespace.
---

# Bitrix Console Commands

All CLI operations are performed via `bitrix.php` from the `/bitrix/` folder:

```bash
cd /path/to/document_root/bitrix
php bitrix.php list                   # list all commands
php bitrix.php help <command>         # help for a command
php bitrix.php <command> [args] -n    # -n = no-interaction
```

Requires configured Composer (usually `/local/composer.json` + `composer install` → `/local/vendor/`).

Configure Composer path in `.settings.php`:

```php
'composer' => [
    'value' => ['config_path' => '../composer.json'],
    'readonly' => true,
],
```

Keep `composer.json` outside `DOCUMENT_ROOT` when possible.

## Code Generators (`make:*`)

**Since main 25.900.** On older versions, scaffold files manually using skill examples.

Commands are interactive but support `-n` and mandatory parameters.

| Command | What It Creates |
| --- | --- |
| `make:module vendor.module` | Minimal skeleton: `install/` (index, version, mysql SQL stubs), `default_option.php`, `lang/ru/install/index.php` — **not** `.settings.php` / `lib/` |
| `make:controller <Name> -m vendor.module --actions=crud` | Controller in `/lib/Infrastructure/Controller/` |
| `make:controller <Name> -m vendor.module --actions=list,get -C Web` | Controller in `Web` context subspace |
| `make:tablet my_post vendor.module` | ORM tablet in `/lib/Model/` |
| `make:entity post -m vendor.module --fields=title,description` | Domain entity |
| `make:service <Name> -m vendor.module` | Application layer service |
| `make:request <Name> -m vendor.module --fields=title,body` | Request DTO for parameter validation |
| `make:event <Name> -m vendor.module` | Event class `extends Event` |
| `make:eventhandler <Name> --event-module=... --handler-module=...` | Handler class |
| `make:message <Name> -m vendor.module` | Queue message (Messenger) |
| `make:messagehandler <Name> --message-module=... --handler-module=...` | Message handler |
| `make:agent <Name> -m vendor.module` | Agent + hint for `CAgent::AddAgent` |
| `make:component Vendor:Name --module=vendor.module` | Component inside a module |
| `make:component Vendor:Name --local` | Component in `/local/components/` |
| `dev:module-skeleton` | Extra module skeleton pieces beyond `make:module` |

**Placement / naming options** (where the generator supports them):

| Option | Short | Meaning |
| --- | --- | --- |
| `--prefix=V2` | `-P` | Subspace after module root, e.g. `lib/V2/Infrastructure/Controller/...` |
| `--context=FeatureName` | `-C` | Context segment inside the layer, e.g. `lib/Infrastructure/Agent/FeatureName/...` |
| `--alias=web` | — | Controller namespace alias from module `.settings.php` `controllers.namespaces` (make:controller) |

**Non-interactive Call Example:**

```bash
php bitrix.php make:controller Post -m vendor.blog --actions=crud -n
php bitrix.php make:tablet blog_post vendor.blog -n
php bitrix.php orm:annotate -m vendor.blog
```

After `make:module`, add `.settings.php`, `/lib/`, routes, etc. yourself or via further `make:*` / `dev:module-skeleton`.

## Built-in Utility Commands

- `orm:annotate [-m modules] [--clean]` — generates PHPDoc annotations for ORM entities for IDE autocompletion.
- `messenger:consume [queues] [--sleep N] [--time-limit N]` — message queue processing. Can be run via cron or Supervisor.
- `translate:index [--path=...]` — indexing translations. Requires the **`translate`** module installed and loaded.
- `update:modules [-m modules]`, `update:versions <file.json>`, `update:languages [-l codes]` — updates.

## Custom Console Command

CLI loads commands from **installed modules only**: it reads each module's `.settings.php` → `console.commands` and does `new $commandClass()`. There is **no constructor DI**. Global `/local/.settings.php` is **not** a source of `console.commands`.

1. Inherit from `Symfony\Component\Console\Command\Command`, place files in `/lib/Cli/Command/<Domain>/`.

    ```php
    namespace Vendor\Module\Cli\Command\Feature;

    use Bitrix\Main\DI\ServiceLocator;
    use Symfony\Component\Console\Attribute\AsCommand;
    use Symfony\Component\Console\Command\Command;
    use Symfony\Component\Console\Input\InputInterface;
    use Symfony\Component\Console\Input\InputOption;
    use Symfony\Component\Console\Output\OutputInterface;
    use Vendor\Module\Application\Service\RebuildService;

    #[AsCommand(name: 'feature:rebuild', description: 'Rebuild feature cache')]
    final class RebuildCommand extends Command
    {
        protected function configure(): void
        {
            $this->addOption('limit', 'l', InputOption::VALUE_OPTIONAL, 'Batch size', 1000);
            $this->addOption('dry-run', null, InputOption::VALUE_NONE);
        }

        protected function execute(InputInterface $input, OutputInterface $output): int
        {
            $limit = (int)$input->getOption('limit');
            $output->writeln("<info>Rebuilding, limit={$limit}</info>");

            try
            {
                /** @var RebuildService $service */
                $service = ServiceLocator::getInstance()->get(RebuildService::class);
                $service->rebuild($limit, (bool)$input->getOption('dry-run'));

                return Command::SUCCESS;
            }
            catch (\Throwable $e)
            {
                $output->writeln("<error>{$e->getMessage()}</error>");
                return Command::FAILURE;
            }
        }
    }
    ```

2. Register the command in `/local/modules/vendor.module/.settings.php` (module must be **installed**):

    ```php
    return [
        'console' => [
            'value' => [
                'commands' => [
                    \Vendor\Module\Cli\Command\Feature\RebuildCommand::class,
                ],
            ],
            'readonly' => true,
        ],
    ];
    ```

    > Section is named **`console`**, key is **`commands`**. Old name `cli` should not be used for new modules.

3. After this, the command will appear in `php bitrix.php list` and will be named by its attribute/name: `feature:rebuild`.

## Running via Cron

```cron
# Every 5 minutes — queue processing
*/5 * * * * php /var/www/site/bitrix/bitrix.php messenger:consume --sleep=1 --time-limit=270 --no-interaction

# Every hour — feature cache cleanup
0 * * * *   php /var/www/site/bitrix/bitrix.php feature:rebuild --no-interaction
```

Always use `--no-interaction` in cron.

## Checklist for a Good Command

- [ ] Descriptive name (`feature:rebuild`, not `do-stuff`).
- [ ] All parameters — via `InputArgument`/`InputOption`, not global variables.
- [ ] Returns `Command::SUCCESS`/`Command::FAILURE`/`Command::INVALID`.
- [ ] Logs and progress go to `OutputInterface`, errors — to stderr via `$output->getErrorOutput()`.
- [ ] Long logic lives in a service; command is a thin wrapper that resolves the service via `ServiceLocator::get()` in `execute()`.
- [ ] Command class has no constructor DI — CLI does `new $commandClass()`.
- [ ] Registered in an **installed** module's `console.commands`, not in global `/local/.settings.php`.
- [ ] In case of a fatal error, exception is logged and converted to `FAILURE`.
