# Bitrix Skills Hub

AI skills for developing with **1C-Bitrix / Bitrix Framework** (D7). Straight out of the `skills/` folder of this repo.

Русская версия: [README.ru.md](README.ru.md)

## What a skill is

A skill is a folder with a `SKILL.md` in it: a name, a description of when to apply it, and a step-by-step procedure for the agent. At startup the agent reads only the description; the full text loads when the task matches. That is why skills scale where a two-thousand-line `CLAUDE.md` turns into noise.

Every skill here is a plain markdown file: readable in a couple of minutes, open to disagreement and rewriting. There is no framework and no runtime.

## Why a hub

Skills multiply like mushrooms after rain: every engineer ends up with a personal stash of prompts, rules, and wrappers. Six months later that is skills-hell — dozens of scattered files with no versions, no quality checks, no shared standard. The AvitoTech team made the case for centralization in their article [«Агентская разработка: как обеспечить качество»](https://habr.com/ru/companies/avito/articles/1060190/) (in Russian): a skills-hub keeps vetted skills in one place, versioned and quality-checked, built for exactly that moment.

This repo plays the hub role: one Bitrix skill collection, shared authoring conventions, and an evaluation gate before a skill enters the catalog.

## Installation

### Via npx skills

```bash
npx skills add azimuth0x28/bitrix-skills-hub --all   # all skills at once
npx skills add azimuth0x28/bitrix-skills-hub --list  # preview the list
npx skills add azimuth0x28/bitrix-skills-hub --skill bitrix-orm bitrix-controllers
npx skills update                                    # update installed ones
```

### Clone and copy

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
cp -r skills/bitrix-orm your-project/.agents/skills/
```

### Ask your agent

```txt
Add the skills from https://github.com/azimuth0x28/bitrix-skills-hub to this project
```

After installation the skills land in `.agents/skills/` of the target project. The rules and skill index from the original project live in [AGENTS.orig.md](AGENTS.orig.md): wire it up as a rule in Cursor or use it as the base for your own `AGENTS.md`.

## The catalog

41 skills covering D7 core topics and adjacent areas. Each one is a self-contained reference an agent can apply immediately.

| Area | Skill |
| --- | --- |
| Project structure, Loader, `/local` | `bitrix-project-structure` |
| Core `.settings.php` sections | `bitrix-settings` |
| Creating modules, install/uninstall | `bitrix-modules` |
| CLI, `make:*`, cron, commands | `bitrix-console-commands` |
| Controllers, actions, filters | `bitrix-controllers` |
| Routing, URL generation | `bitrix-routing` |
| ORM, tablets, queries | `bitrix-orm` |
| Events (new + legacy) | `bitrix-events` |
| Validation, DTO attributes | `bitrix-validation` |
| ServiceLocator, DI | `bitrix-service-locator` |
| Caching, composite | `bitrix-caching` |
| Performance | `bitrix-performance` |
| CSRF, XSS, SQLi, JWT | `bitrix-security` |
| Agents, background jobs, Messenger | `bitrix-background-jobs` |
| Result, Error, ErrorCollection | `bitrix-result-and-errors` |
| Components, templates, SEF | `bitrix-components` |
| Iblocks, properties, SEO | `bitrix-iblocks` |
| Highload blocks | `bitrix-highloadblock` |
| Commerce catalog, prices, SKU | `bitrix-catalog` |
| E-commerce, orders, payments | `bitrix-sale` |
| REST API, OAuth | `bitrix-rest` |
| Pull server, real-time | `bitrix-pull` |
| Landing, page builder | `bitrix-landing` |
| SEO, meta, sitemap | `bitrix-seo` |
| Business processes (bizproc) | `bitrix-bizproc` |
| HttpClient, SSRF, GeoIP | `bitrix-http-client` |
| PSR-3 logging | `bitrix-logger` |
| Localization, Loc | `bitrix-localization` |
| Date/DateTime, timezones | `bitrix-datetime` |
| Application, Context, Request/Response | `bitrix-request-response` |
| Sessions, separated mode | `bitrix-sessions` |
| SQL, transactions, SqlHelper | `bitrix-database` |
| PostgreSQL migration | `bitrix-postgresql` |
| Persistent Storage (25.1100+) | `bitrix-storage` |
| JS/CSS extensions | `bitrix-extensions` |
| UI kit (popup, sidepanel) | `bitrix-ui` |
| BitrixVue 3 | `bitrix-vue` |
| CMS: sites, menus, templates | `bitrix-cms-basics` |
| DB/schema migrations ([sprint.migration](https://marketplace.1c-bitrix.ru/solutions/sprint.migration/)) | `bitrix-sprint-migration` |

### Meta-skills

Skills about the skills themselves: authoring conventions and quality control.

| Task | Skill |
| --- | --- |
| Creating and refactoring skills following repo conventions | `bitrix-skill-creator` |
| Quality evaluation before acceptance: blind test, Q1–Q10 rubric | `bitrix-skill-eval` |

## Skill anatomy

```
skills/<name>/
├── SKILL.md      # router: description, triggers, links to rules
└── rules/*.md    # rules by topic; the agent reads only the ones it needs
```

Fat skills use progressive disclosure: the agent opens `SKILL.md` first, then only the `rules/` files it needs. Skills are self-sufficient and anchored to the core: verified against **main 26.150.0**, baseline patterns **main 23.0+**.

## Adding your own

Author a new skill through `bitrix-skill-creator`: it knows the repo conventions — structure, frontmatter, mandatory content layers, checklists. Run the finished draft through `bitrix-skill-eval`: the blind test and the Q1–Q10 rubric filter out weak skills before they enter the catalog.

## Links

- [docs.1c-bitrix.ru](https://docs.1c-bitrix.ru/) — documentation for "1C-Bitrix: Site Management"
- [apidocs.bitrix24.ru](https://apidocs.bitrix24.ru/) — REST API for Bitrix24
- [bitrix-tools/best-practice](https://github.com/bitrix-tools/best-practice) — operational practices from the Bitrix Tools team
- [bxmaximum/bitrix_ai_challenge](https://github.com/bxmaximum/bitrix_ai_challenge) — research on AI models applied to Bitrix

## License

MIT.

## Acknowledgements

This hub is built on top of [bxmaximum/bitrix-framework-skills](https://github.com/bxmaximum/bitrix-framework-skills) — a skill collection maintained by the [BXMax](https://bxmax.ru) community. Thanks for the great work and the open license: this entire repo grew from that foundation.
