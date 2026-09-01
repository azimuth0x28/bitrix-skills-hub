# Bitrix Skills Hub

AI-скиллы для разработки на **1С-Битрикс / Bitrix Framework** (D7). Прямо из папки `skills/` этого репозитория.

English version: [README.md](README.md)

## Что такое скилл

Скилл — папка с `SKILL.md`: название, описание ситуации «когда применять» и пошаговая процедура для агента. При старте агент читает только описание, а полный текст подтягивает, когда задача совпала. Именно поэтому скиллы масштабируются там, где `CLAUDE.md` на две тысячи строк превращается в шум.

Каждый скилл здесь — обычный markdown-файл: читается за пару минут, с ним можно спорить и переписывать под себя. Здесь нет фреймворка и рантайма.

## Зачем хаб

Скиллы появляются как грибы после дождя: каждый инженер заводит свой набор промптов, правил и обвязок. Через полгода это skills-hell — десятки разрозненных файлов без версий, проверки качества и единого стандарта. Идею централизации хорошо описала команда AvitoTech в статье [«Агентская разработка: как обеспечить качество»](https://habr.com/ru/companies/avito/articles/1060190/): skills-hub держит проверенные навыки в одном месте, с версиями и контролем качества, и придуман ровно для этого момента.

Роль хаба здесь выполняет сам репозиторий: одна коллекция скиллов по Bitrix, общие конвенции авторства и оценка перед попаданием в каталог.

## Быстрый старт

**Самый быстрый путь** — любой агент, одна команда. Открытый [skills CLI](https://github.com/vercel-labs/skills) устанавливается в 70+ агентов:

```bash
npx skills add azimuth0x28/bitrix-skills-hub --all   # все 43 скилла сразу
npx skills add azimuth0x28/bitrix-skills-hub --list  # посмотреть список
npx skills add azimuth0x28/bitrix-skills-hub --skill bitrix-orm bitrix-controllers
npx skills update                                    # обновить установленные
```

Или по одному:

```bash
npx skills add azimuth0x28/bitrix-skills-hub --skill bitrix-orm
npx skills add azimuth0x28/bitrix-skills-hub --skill bitrix-components
npx skills add azimuth0x28/bitrix-skills-hub --skill bitrix-rest
```

Предпочитаете нативную интеграцию? Выберите свой инструмент ниже.

<details>
<summary><b>Claude Code</b></summary>

Установка через маркетплейс:

```
/plugin marketplace add azimuth0x28/bitrix-skills-hub
/plugin install bitrix-skills-hub
```

Или локально:

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
claude --plugin-dir /path/to/bitrix-skills-hub
```

При установке через маркетплейс скиллы попадают в `~/.claude/skills/`.

</details>

<details>
<summary><b>Cursor</b></summary>

Скопируйте папки скиллов в `.cursor/skills/`, короткие политики — в `.cursor/rules/*.mdc`. Не вставляйте полные скиллы в правила.

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
cp -r bitrix-skills-hub/skills/bitrix-orm .cursor/skills/
cp -r bitrix-skills-hub/skills/bitrix-components .cursor/skills/
```

</details>

<details>
<summary><b>Gemini CLI</b></summary>

Установка как нативные скиллы для автообнаружения:

```bash
gemini skills install https://github.com/azimuth0x28/bitrix-skills-hub.git --path skills
```

Или из локального клона:

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
gemini skills install ./bitrix-skills-hub/skills/
```

</details>

<details>
<summary><b>OpenCode</b></summary>

Скопируйте скиллы в `.opencode/skills/` (или `~/.config/opencode/skills/`), добавьте локальный `AGENTS.md` и используйте встроенный инструмент skill для агентного выполнения.

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
cp -r bitrix-skills-hub/skills/bitrix-orm .opencode/skills/
```

</details>

<details>
<summary><b>GitHub Copilot</b></summary>

Подключите Copilot к агенту [agents/bitrix-coder.md](agents/bitrix-coder.md) и добавьте нужные правила из скиллов в `.github/copilot-instructions.md` вашего проекта.

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
# Укажите пути к скиллам из клона в ваших инструкциях для Copilot
```

</details>

<details>
<summary><b>Windsurf</b></summary>

Добавьте содержимое скиллов в конфигурацию правил Windsurf в `.windsurf/rules/`.

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
cp bitrix-skills-hub/skills/bitrix-orm/SKILL.md .windsurf/rules/bitrix-orm.mdc
```

</details>

<details>
<summary><b>Codex</b></summary>

Установка как нативный плагин Codex (Codex CLI v0.122+):

```bash
codex plugin marketplace add azimuth0x28/bitrix-skills-hub
codex plugin add bitrix-skills-hub@bitrix-skills-hub
```

Первая команда регистрирует маркетплейс, вторая устанавливает плагин. Codex читает корневую папку `skills/` через `.codex-plugin/plugin.json`. После установки вызывайте скиллы через `@`.

</details>

<details>
<summary><b>Kiro IDE</b></summary>

Скиллы для Kiro хранятся в `.kiro/skills/` на уровне проекта или глобально. Kiro также поддерживает `AGENTS.md`.

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
cp -r bitrix-skills-hub/skills/bitrix-orm .kiro/skills/
```

Подробнее: [документация Kiro](https://kiro.dev/docs/skills/).

</details>

<details>
<summary><b>Antigravity CLI</b></summary>

Установка как нативный плагин для скиллов, субагентов и слеш-команд:

```bash
agy plugin install https://github.com/azimuth0x28/bitrix-skills-hub.git
```

Или из локального клона:

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
agy plugin install ./bitrix-skills-hub
```

</details>

<details>
<summary><b>Другие агенты</b></summary>

Скиллы — это обычный Markdown, они работают с любым агентом, принимающим системные промпты или файлы инструкций.

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
cp -r bitrix-skills-hub/skills/bitrix-orm ваш-проект/.agents/skills/
```

</details>

После установки правила и индекс скиллов из исходного проекта лежат в [agents/bitrix-coder.md](agents/bitrix-coder.md): подключите файл как rule в Cursor или возьмите за основу собственного `AGENTS.md`.

## Каталог

43 скилла по темам ядра D7 и смежным областям. Каждый — самодостаточный справочник, который агент применяет сразу.

### Ядро и D7

| Skill | Что делает | Когда использовать |
| --- | --- | --- |
| [bitrix-project-structure](skills/bitrix-project-structure/SKILL.md) | `/local` vs `/bitrix`, PSR-4, `.settings.php`, Loader | Размещение кода, загрузка модулей, autoloading |
| [bitrix-settings](skills/bitrix-settings/SKILL.md) | Секции `.settings.php`: connections, cache, session, routing, messenger | Настройка поведения ядра |
| [bitrix-modules](skills/bitrix-modules/SKILL.md) | CModule, install/index.php, DoInstall/DoUninstall, make:module | Создание новых модулей, регистрация |
| [bitrix-console-commands](skills/bitrix-console-commands/SKILL.md) | CLI-инструменты, генераторы make:*, Symfony Console | Скелеты, cron, queue workers |
| [bitrix-controllers](skills/bitrix-controllers/SKILL.md) | Engine Controller/JsonController, actions, фильтры, CurrentUser | AJAX/REST/routed эндпоинты |
| [bitrix-routing](skills/bitrix-routing/SKILL.md) | RoutingConfigurator, /local/routes, PublicPageController, urlrewrite | Настройка публичных/API URL |
| [bitrix-orm](skills/bitrix-orm/SKILL.md) | D7 ORM: tablet'ы, ConditionTree, Objectify, batch/merge/deleteByFilter | Проектирование сущностей, чтение, персистентность |
| [bitrix-events](skills/bitrix-events/SKILL.md) | Система событий: новая модель (EventManager) + легаси (OnBefore*/OnAfter*) | Интеграция модулей, хуки жизненного цикла |
| [bitrix-validation](skills/bitrix-validation/SKILL.md) | ValidationService, #[NotEmpty]/#[Email]/#[Length], Request DTO | Валидация ввода для контроллеров/сервисов |
| [bitrix-service-locator](skills/bitrix-service-locator/SKILL.md) | DI-контейнер (PSR-11), autowire, constructor injection | Подключение зависимостей, отказ от статики |
| [bitrix-result-and-errors](skills/bitrix-result-and-errors/SKILL.md) | Result, Error, ErrorCollection, AddResult, UpdateResult | API сервисов, обработка ошибок без исключений |
| [bitrix-database](skills/bitrix-database/SKILL.md) | Connection, SqlHelper, SqlExpression, raw SQL, транзакции, bulk-операции | Когда ORM недостаточно, raw SQL, миграции |
| [bitrix-postgresql](skills/bitrix-postgresql/SKILL.md) | PgsqlConnection, миграция с MySQL, совместимый код, матрица поддержки | Настройка PostgreSQL Enterprise |
| [bitrix-datetime](skills/bitrix-datetime/SKILL.md) | Date/DateTime, маски ядра, часовые пояса, Culture, DateField | Расписания, конвертация часовых поясов, арифметика дат |
| [bitrix-request-response](skills/bitrix-request-response/SKILL.md) | HttpRequest/HttpResponse, Json/AjaxJson/Redirect, Uri | Замена $_GET/$_POST, сырые заголовки |
| [bitrix-storage](skills/bitrix-storage/SKILL.md) | PersistentStorageInterface, DeferredStorageDecorator, Option | Конфиг vs TTL-состояние vs производный кеш |
| [bitrix-caching](skills/bitrix-caching/SKILL.md) | Cache, ManagedCache, TaggedCache, ORM auto-cache, Composite | Производительность, инвалидация, TTL, прогрев |
| [bitrix-performance](skills/bitrix-performance/SKILL.md) | Composite site, оптимизация запросов, репликация, шардинг | Высоконагруженная оптимизация за пределами кеширования |
| [bitrix-background-jobs](skills/bitrix-background-jobs/SKILL.md) | CAgent, addBackgroundJob, брокеры/очереди Messenger | Отложенная и асинхронная обработка |
| [bitrix-sprint-migration](skills/bitrix-sprint-migration/SKILL.md) | sprint.migration: Version, HelperManager, builders, CLI migrate.php | Миграции БД/схемы/контента |

### Контент и интерфейс

| Skill | Что делает | Когда использовать |
| --- | --- | --- |
| [bitrix-iblocks](skills/bitrix-iblocks/SKILL.md) | Типы/элементы/секции инфоблоков, ORM compileEntity, свойства, SEO | Работа с инфоблоками, структурированные данные |
| [bitrix-highloadblock](skills/bitrix-highloadblock/SKILL.md) | HighloadBlockTable, compileEntity, DataManager CRUD, UF, ORM-события | Кастомные сущности, динамические модели данных |
| [bitrix-components](skills/bitrix-components/SKILL.md) | class.php, шаблоны, кеш, SEF, Controllerable AJAX | Создание или редактирование компонентов |
| [bitrix-extensions](skills/bitrix-extensions/SKILL.md) | /local/js/, bundle.config.js, Extension::load, @bitrix/cli | Добавление фронтенд-кода в модули |
| [bitrix-ui](skills/bitrix-ui/SKILL.md) | Popup, SidePanel, MessageBox, entity-selector, grid, alerts, toasts | Админ-интерфейсы, публичные UI-компоненты |
| [bitrix-vue](skills/bitrix-vue/SKILL.md) | BitrixVue 3, ui.vue3.bitrixvue, createApp, интеграция с REST | Реактивный UI на Vue в Bitrix |
| [bitrix-cms-basics](skills/bitrix-cms-basics/SKILL.md) | Сайты, шаблоны, меню, инклюды, хлебные крошки, стили, user fields | Структура сайта, управление контентом |
| [bitrix-landing](skills/bitrix-landing/SKILL.md) | Лендинги, репозиторий блоков, публикация, хуки | Страницы Sites24, витрины, базы знаний |
| [bitrix-seo](skills/bitrix-seo/SKILL.md) | Карты сайта, robots.txt, интеграция с вебмастером, IPROPERTY | Карты обхода, подключение к поисковикам |

### Торговля

| Skill | Что делает | Когда использовать |
| --- | --- | --- |
| [bitrix-catalog](skills/bitrix-catalog/SKILL.md) | Продукты, SKU/офферы, цены, инвентарь, скидки, бандлы | Электронная коммерция: цены, остатки, API каталога |
| [bitrix-sale](skills/bitrix-sale/SKILL.md) | Basket, Order, FUSER, оплата, доставка, скидки, купоны | Корзина/checkout, жизненный цикл заказа |
| [bitrix-bizproc](skills/bitrix-bizproc/SKILL.md) | CBPDocument, CBPRuntime, шаблоны workflows, кастомные activities | Согласования, документооборот, автоматизация |

### Интеграции и платформа

| Skill | Что делает | Когда использовать |
| --- | --- | --- |
| [bitrix-rest](skills/bitrix-rest/SKILL.md) | REST-методы, scopes, webhook/OAuth, настройки rest | Предоставление API приложениям/webhooks/маркетплейсу |
| [bitrix-pull](skills/bitrix-pull/SKILL.md) | Pull-модуль: realtime-события, подписка JS, watch tags | Живые обновления UI, уведомления |
| [bitrix-http-client](skills/bitrix-http-client/SKILL.md) | HttpClient, PSR-18, async Promise, SSRF, GeoIp | Интеграции с внешними API, webhooks |
| [bitrix-logger](skills/bitrix-logger/SKILL.md) | PSR-3: FileLogger, SysLogger, LogFormatter, Monolog | Логи модулей, отладка, ротация логов |
| [bitrix-localization](skills/bitrix-localization/SKILL.md) | Loc, lang-файлы, loadMessages, BX.message, translate:index | Интернационализация, многоязычные сайты, JS-переводы |
| [bitrix-security](skills/bitrix-security/SKILL.md) | CSRF, XSS, SQLi, SSRF, JWT/JWK, права доступа, шифрование | Обработка ввода, аудит безопасности |
| [bitrix-sessions](skills/bitrix-sessions/SKILL.md) | Application::getSession(), read-only/virtual-режимы, separated mode | Управление сессиями, настройка AJAX-блокировок |

### Мета

| Skill | Что делает | Когда использовать |
| --- | --- | --- |
| [bitrix-api-skill-creator](skills/bitrix-api-skill-creator/SKILL.md) | Конвенции авторства: морфология, frontmatter, baseline/Since, плотность | Создание API/ядерных скиллов (классы ядра, ORM, API модулей) |
| [bitrix-workflow-skill-creator](skills/bitrix-workflow-skill-creator/SKILL.md) | Конвенции для процессных скиллов: таблицы решений, проектные факты, процедуры, версии инструментов | Создание процессных скиллов (code style, DevOps, правила ревью) |
| [bitrix-skill-eval](skills/bitrix-skill-eval/SKILL.md) | Протокол слепого теста, рубрика Q1-Q10, хард-гейты, метрика плотности | Оценка черновиков скиллов |
| [skill-validator](skills/skill-validator/SKILL.md) | quick_validate.py (формат), prism-scanner (безопасность), грейд-гейты | Механическая проверка перед PR |

## Агентские персоны

Готовые специализированные персоны для разработки на Bitrix:

| Agent | Роль | Перспектива |
| --- | --- | --- |
| [bitrix-coder](agents/bitrix-coder.md) | Специалист по Bitrix Framework | Глубокое знание D7, границы DI, конвенции `/local/`, паттерны безопасности, политика версий |

## Устройство скилла

```
skills/<name>/
├── SKILL.md      # роутер: описание, триггеры, ссылки на правила
└── rules/*.md    # правила по темам, агент читает только нужные
```

«Толстые» скиллы используют progressive disclosure: агент открывает `SKILL.md`, затем только нужные файлы из `rules/`. Скиллы самодостаточны и опираются на ядро: проверены на **main 26.150.0**, baseline-паттерны — **main 23.0+**.

## Как добавить свой

Новый скилл создавайте через `bitrix-api-skill-creator` (API/ядерные скиллы — тип по умолчанию) или `bitrix-workflow-skill-creator` (процессные скиллы: конвенции, code style, окружение). Готовый черновик прогоните через `skill-validator` (формат + безопасность) и `bitrix-skill-eval`: слепой тест и рубрика Q1-Q10 отсеивают слабые скиллы до попадания в каталог.

## Ссылки

- [docs.1c-bitrix.ru](https://docs.1c-bitrix.ru/) — документация «1С-Битрикс: Управление сайтом»
- [apidocs.bitrix24.ru](https://apidocs.bitrix24.ru/) — REST «Битрикс24»
- [bitrix-tools/best-practice](https://github.com/bitrix-tools/best-practice) — operational-практики от команды Bitrix Tools
- [bxmaximum/bitrix_ai_challenge](https://github.com/bxmaximum/bitrix_ai_challenge) — исследование AI-моделей на Bitrix

## Лицензия

MIT.

## Благодарность

Хаб собран на базе [bxmaximum/bitrix-framework-skills](https://github.com/bxmaximum/bitrix-framework-skills) — коллекции скиллов от сообщества [BXMax](https://bxmax.ru). Спасибо за отличную работу и открытую лицензию: на этом фундаменте вырос весь репозиторий.
