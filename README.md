# Bitrix Framework Skills

Набор AI-скиллов для разработки на **1С-Битрикс / Bitrix Framework** (D7): ORM, контроллеры, роутинг, кеш, безопасность, компоненты и другие темы ядра.

Скиллы собирает и поддерживает сообщество **[BXMax](https://bxmax.ru)** — платформа для разработчиков 1С-Битрикс: практические материалы, разборы ядра, эксперименты с AI и обмен опытом между коллегами. Это не официальная документация Битрикс, а концентрированные operational-правила для AI-агентов при проектировании и написании кода в `/local/`.

**BXMax:** [bxmax.ru](https://bxmax.ru) · [Telegram](https://t.me/bxmaximum) · [Bitrix × AI](https://bxmax.ru/bitrix-ai)

Официальная документация по продукту:

- [docs.1c-bitrix.ru](https://docs.1c-bitrix.ru/) — «1С-Битрикс: Управление сайтом».
- [apidocs.bitrix24.ru](https://apidocs.bitrix24.ru/) — REST «Битрикс24».

## Skills

Каждый skill — самодостаточный справочник в `skills/<name>/SKILL.md`. Агент открывает нужный skill по задаче (см. таблицу в [AGENTS.md](https://github.com/bxmaximum/bitrix_ai_challenge/blob/main/AGENTS.md) проекта-челленджа).

Каталог (31 skill):

| Область | Skill |
| --- | --- |
| Структура проекта, autoload, `.settings.php` | `bitrix-project-structure` |
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
| Торговый каталог, цены, SKU | `bitrix-catalog` |
| HttpClient, SSRF | `bitrix-http-client` |
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

### Как добавить

Напрямую попросить агента:

```txt
Добавь в проект скиллы из репозитория https://github.com/bxmaximum/bitrix-framework-skills
```

Через [skills](https://www.npmjs.com/package/skills) — все скиллы сразу:

```bash
npx skills add bxmaximum/bitrix-framework-skills --all
```

Или конкретные:

```bash
npx skills add bxmaximum/bitrix-framework-skills --skill bitrix-orm bitrix-controllers
npx skills add bxmaximum/bitrix-framework-skills --list   # список без установки
```

Обновление:

```bash
npx skills update
```

После установки скиллы попадают в `.agents/skills/` целевого проекта. Lock-файл `skills-lock.json` фиксирует версии для команды.

## Связанные проекты

- [bxmaximum/bitrix_ai_challenge](https://github.com/bxmaximum/bitrix_ai_challenge) — исследование AI-моделей на Bitrix; системный промпт в `AGENTS.md`. Публикации на [bxmax.ru/bitrix-ai](https://bxmax.ru/bitrix-ai).
- [bitrix-tools/best-practice](https://github.com/bitrix-tools/best-practice) — operational best practices от команды Bitrix Tools (дополняет, не заменяет эти скиллы).

## Сообщество BXMax

Если скиллы помогают в работе — загляните на [bxmax.ru](https://bxmax.ru): там курсы, статьи, [Кофе && Код](https://bxmax.ru/coffee-code) и другие материалы по современной разработке на Битрикс. Новые скиллы и обновления анонсируем в [Telegram](https://t.me/bxmaximum).

## Лицензия

MIT License
