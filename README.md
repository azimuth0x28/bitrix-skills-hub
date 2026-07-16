# Bitrix Framework Skills

Набор AI-скиллов для разработки на **1С-Битрикс / Bitrix Framework** (D7): ORM, контроллеры, роутинг, кеш, безопасность, компоненты, REST, Sale и другие темы ядра.

Скиллы собирает и поддерживает сообщество **[BXMax](https://bxmax.ru)** — платформа для разработчиков 1С-Битрикс: практические материалы, разборы ядра, эксперименты с AI и обмен опытом между коллегами. Это не официальная документация Битрикс, а концентрированные operational-правила для AI-агентов при проектировании и написании кода в `/local/`.

**BXMax:** [bxmax.ru](https://bxmax.ru) · [Telegram](https://t.me/bxmaximum) · [Bitrix × AI](https://bxmax.ru/bitrix-ai)

Официальная документация по продукту:

- [docs.1c-bitrix.ru](https://docs.1c-bitrix.ru/) — «1С-Битрикс: Управление сайтом».
- [apidocs.bitrix24.ru](https://apidocs.bitrix24.ru/) — REST «Битрикс24».

## AGENTS.md

Системный промпт для AI-агентов — [AGENTS.md](AGENTS.md) в корне репозитория. Содержит приоритеты D7, границы DI, чеклист перед коммитом, анти-паттерны и индекс скиллов.

Скиллы проверены на ядре **main 26.150.0**; baseline-паттерны — **main 23.0+** (см. version policy в AGENTS.md).

## Skills

Каждый skill — самодостаточный справочник в `skills/<name>/SKILL.md`. После установки через `npx skills` попадает в `.agents/skills/<name>/` целевого проекта.

«Толстые» скиллы используют progressive disclosure: агент открывает `SKILL.md` (роутер), затем только нужные файлы из `rules/*.md`. Полный индекс — в [AGENTS.md](AGENTS.md).

Каталог (38 skills):

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

После установки скиллы попадают в `.agents/skills/` целевого проекта. Скопируйте [AGENTS.md](AGENTS.md) в корень Bitrix-проекта (или подключите как rule в Cursor), чтобы агент знал приоритеты и индекс скиллов.

## Связанные проекты

- [bxmaximum/bitrix_ai_challenge](https://github.com/bxmaximum/bitrix_ai_challenge) — исследование AI-моделей на Bitrix; публикации на [bxmax.ru/bitrix-ai](https://bxmax.ru/bitrix-ai).
- [bitrix-tools/best-practice](https://github.com/bitrix-tools/best-practice) — operational best practices от команды Bitrix Tools

## About

**[BXMax](https://bxmax.ru)** — первая специализированная платформа для разработчиков 1С-Битрикс. Мы делаем современную разработку на D7 понятнее: от разборов ядра до практики с AI-агентами.

Эти скиллы — часть нашей открытой экосистемы. Их собираем на реальных задачах, проверяем в [Bitrix × AI](https://bxmax.ru/bitrix-ai) и обновляем по мере развития ядра.

### Что есть на BXMax

| Раздел | Что внутри |
| --- | --- |
| [Блог](https://bxmax.ru/blog) | Разборы API, туториалы, мнения о ядре |
| [Кофе && Код](https://bxmax.ru/coffee-code) | Короткие практические советы по D7 |
| [Bitrix × AI](https://bxmax.ru/bitrix-ai) | Сравнение AI-моделей на реальных ТЗ |
| [Telegram](https://t.me/bxmaximum) | Анонсы материалов, скиллов и обновлений |

### Зачем эти скиллы

Официальная документация отвечает на вопрос «что есть в продукте». Наши скиллы отвечают на «как писать в `/local/` правильно»: D7 вместо legacy, сервисный слой, безопасность, кеш, ORM — в формате, который AI-агент может применить сразу.

Если скиллы экономят вам время — [загляните на bxmax.ru](https://bxmax.ru). Там больше материалов, курсов и живого сообщества единомышленников.

**Ссылки:** [bxmax.ru](https://bxmax.ru) · [Telegram](https://t.me/bxmaximum) · [Bitrix × AI](https://bxmax.ru/bitrix-ai) · [GitHub](https://github.com/bxmaximum)

## Лицензия

MIT License
