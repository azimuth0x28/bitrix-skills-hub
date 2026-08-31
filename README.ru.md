# Bitrix Skills Hub

AI-скиллы для разработки на **1С-Битрикс / Bitrix Framework** (D7). Прямо из папки `skills/` этого репозитория.

English version: [README.md](README.md)

## Что такое скилл

Скилл — папка с `SKILL.md`: название, описание ситуации «когда применять» и пошаговая процедура для агента. При старте агент читает только описание, а полный текст подтягивает, когда задача совпала. Именно поэтому скиллы масштабируются там, где `CLAUDE.md` на две тысячи строк превращается в шум.

Каждый скилл здесь — обычный markdown-файл: читается за пару минут, с ним можно спорить и переписывать под себя. Здесь нет фреймворка и рантайма.

## Зачем хаб

Скиллы появляются как грибы после дождя: каждый инженер заводит свой набор промптов, правил и обвязок. Через полгода это skills-hell — десятки разрозненных файлов без версий, проверки качества и единого стандарта. Идею централизации хорошо описала команда AvitoTech в статье [«Агентская разработка: как обеспечить качество»](https://habr.com/ru/companies/avito/articles/1060190/): skills-hub держит проверенные навыки в одном месте, с версиями и контролем качества, и придуман ровно для этого момента.

Роль хаба здесь выполняет сам репозиторий: одна коллекция скиллов по Bitrix, общие конвенции авторства и оценка перед попаданием в каталог.

## Установка

### Через npx skills

```bash
npx skills add azimuth0x28/bitrix-skills-hub --all   # все скиллы сразу
npx skills add azimuth0x28/bitrix-skills-hub --list  # посмотреть список
npx skills add azimuth0x28/bitrix-skills-hub --skill bitrix-orm bitrix-controllers
npx skills update                                    # обновить установленные
```

### Клонировать и скопировать

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
cp -r skills/bitrix-orm ваш-проект/.agents/skills/
```

### Попросить агента

```txt
Добавь в проект скиллы из репозитория https://github.com/azimuth0x28/bitrix-skills-hub
```

После установки скиллы попадают в `.agents/skills/` целевого проекта. Правила и индекс скиллов из исходного проекта лежат в [AGENTS.orig.md](AGENTS.orig.md): подключите файл как rule в Cursor или возьмите за основу собственного `AGENTS.md`.

## Каталог

42 скилла по темам ядра D7 и смежным областям. Каждый — самодостаточный справочник, который агент применяет сразу.

| Область | Skill |
| --- | --- |
| Структура проекта, Loader, `/local` | `bitrix-project-structure` |
| Секции `.settings.php` ядра | `bitrix-settings` |
| Создание модулей, install/uninstall | `bitrix-modules` |
| CLI, `make:*`, cron, команды | `bitrix-console-commands` |
| Контроллеры, actions, filters | `bitrix-controllers` |
| Роутинг, URL generation | `bitrix-routing` |
| ORM, tablets, queries | `bitrix-orm` |
| События (new + legacy) | `bitrix-events` |
| Валидация, DTO attributes | `bitrix-validation` |
| ServiceLocator, DI | `bitrix-service-locator` |
| Кеш, composite | `bitrix-caching` |
| Производительность | `bitrix-performance` |
| CSRF, XSS, SQLi, JWT | `bitrix-security` |
| Агенты, background jobs, Messenger | `bitrix-background-jobs` |
| Result, Error, ErrorCollection | `bitrix-result-and-errors` |
| Компоненты, templates, SEF | `bitrix-components` |
| Инфоблоки, свойства, SEO | `bitrix-iblocks` |
| Highload-блоки | `bitrix-highloadblock` |
| Торговый каталог, цены, SKU | `bitrix-catalog` |
| Интернет-магазин, заказы, оплата | `bitrix-sale` |
| REST API, OAuth | `bitrix-rest` |
| Pull-сервер, real-time | `bitrix-pull` |
| Landing, конструктор страниц | `bitrix-landing` |
| SEO, мета, sitemap | `bitrix-seo` |
| Бизнес-процессы | `bitrix-bizproc` |
| HttpClient, SSRF, GeoIP | `bitrix-http-client` |
| PSR-3 logging | `bitrix-logger` |
| Локализация, Loc | `bitrix-localization` |
| Date/DateTime, timezones | `bitrix-datetime` |
| Application, Context, Request/Response | `bitrix-request-response` |
| Сессии, separated mode | `bitrix-sessions` |
| SQL, transactions, SqlHelper | `bitrix-database` |
| PostgreSQL migration | `bitrix-postgresql` |
| Persistent Storage (25.1100+) | `bitrix-storage` |
| JS/CSS extensions | `bitrix-extensions` |
| UI kit (popup, sidepanel) | `bitrix-ui` |
| BitrixVue 3 | `bitrix-vue` |
| CMS: sites, menus, templates | `bitrix-cms-basics` |
| Миграции БД/схемы ([sprint.migration](https://marketplace.1c-bitrix.ru/solutions/sprint.migration/)) | `bitrix-sprint-migration` |

### Мета-скиллы

Скиллы про сами скиллы: конвенции авторства, контроль качества и механическая валидация.

| Задача | Skill |
| --- | --- |
| Создание и рефакторинг скиллов по конвенциям репозитория | `bitrix-skill-creator` |
| Оценка качества скилла перед приёмкой: слепой тест, рубрика Q1–Q10 | `bitrix-skill-eval` |
| Механическая валидация скилла перед PR: формат + безопасность | `skill-validator` |

## Устройство скилла

```
skills/<name>/
├── SKILL.md      # роутер: описание, триггеры, ссылки на правила
└── rules/*.md    # правила по темам, агент читает только нужные
```

«Толстые» скиллы используют progressive disclosure: агент открывает `SKILL.md`, затем только нужные файлы из `rules/`. Скиллы самодостаточны и опираются на ядро: проверены на **main 26.150.0**, baseline-паттерны — **main 23.0+**.

## Как добавить свой

Новый скилл создавайте через `bitrix-skill-creator`: он знает конвенции репозитория — структуру, frontmatter, обязательные слои, чеклисты. Готовый черновик прогоните через `skill-validator` (формат + безопасность) и `bitrix-skill-eval`: слепой тест и рубрика Q1–Q10 отсеивают слабые скиллы до попадания в каталог.

## Ссылки

- [docs.1c-bitrix.ru](https://docs.1c-bitrix.ru/) — документация «1С-Битрикс: Управление сайтом»
- [apidocs.bitrix24.ru](https://apidocs.bitrix24.ru/) — REST «Битрикс24»
- [bitrix-tools/best-practice](https://github.com/bitrix-tools/best-practice) — operational-практики от команды Bitrix Tools
- [bxmaximum/bitrix_ai_challenge](https://github.com/bxmaximum/bitrix_ai_challenge) — исследование AI-моделей на Bitrix

## Лицензия

MIT.

## Благодарность

Хаб собран на базе [bxmaximum/bitrix-framework-skills](https://github.com/bxmaximum/bitrix-framework-skills) — коллекции скиллов от сообщества [BXMax](https://bxmax.ru). Спасибо за отличную работу и открытую лицензию: на этом фундаменте вырос весь репозиторий.
