# Bitrix Skills Hub

AI skills for developing with **1C-Bitrix / Bitrix Framework** (D7). Straight out of the `skills/` folder of this repo.

Русская версия: [README.ru.md](README.ru.md)

## What a skill is

A skill is a folder with a `SKILL.md` in it: a name, a description of when to apply it, and a step-by-step procedure for the agent. At startup the agent reads only the description; the full text loads when the task matches. That is why skills scale where a two-thousand-line `CLAUDE.md` turns into noise.

Every skill here is a plain markdown file: readable in a couple of minutes, open to disagreement and rewriting. There is no framework and no runtime.

## Why a hub

Skills multiply like mushrooms after rain: every engineer ends up with a personal stash of prompts, rules, and wrappers. Six months later that is skills-hell, dozens of scattered files with no versions, no quality checks, no shared standard. The AvitoTech team made the case for centralization in their article [«Agentic Development: How to Ensure Quality»](https://habr.com/ru/companies/avito/articles/1060190/) (in Russian): a skills-hub keeps vetted skills in one place, versioned and quality-checked, built for exactly that moment.

This repo plays the hub role: one Bitrix skill collection, shared authoring conventions, and an evaluation gate before a skill enters the catalog.

## Quick Start

**Fastest path** — any agent, one command. The open [skills CLI](https://github.com/vercel-labs/skills) installs into 70+ agents:

```bash
npx skills add azimuth0x28/bitrix-skills-hub --all   # all skills at once
npx skills add azimuth0x28/bitrix-skills-hub --list  # browse before installing
npx skills add azimuth0x28/bitrix-skills-hub --skill bitrix-orm bitrix-controllers
npx skills update                                    # update installed ones
```

Or grab individual skills:

```bash
npx skills add azimuth0x28/bitrix-skills-hub --skill bitrix-orm bitrix-components bitrix-rest
```

Prefer a native integration? Pick your tool below.

<details>
<summary><b>Claude Code</b></summary>

Install via the marketplace:

```
/plugin marketplace add azimuth0x28/bitrix-skills-hub
/plugin install bitrix-skills-hub
```

Or clone locally:

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
claude --plugin-dir /path/to/bitrix-skills-hub
```

Skills land in `~/.claude/skills/` when installed via marketplace.

</details>

<details>
<summary><b>Cursor</b></summary>

Copy skill folders into `.cursor/skills/` and short policies into `.cursor/rules/*.mdc`. Do not paste full skills into rules.

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
cp -r bitrix-skills-hub/skills/bitrix-orm .cursor/skills/
cp -r bitrix-skills-hub/skills/bitrix-components .cursor/skills/
```

</details>

<details>
<summary><b>Gemini CLI</b></summary>

Install as native skills for auto-discovery:

```bash
gemini skills install https://github.com/azimuth0x28/bitrix-skills-hub.git --path skills
```

Or from a local clone:

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
gemini skills install ./bitrix-skills-hub/skills/
```

</details>

<details>
<summary><b>OpenCode</b></summary>

Copy skills to `.opencode/skills/` (or `~/.config/opencode/skills/`), add a project-local `AGENTS.md`, and use the built-in skill tool for agent-driven execution.

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
cp -r bitrix-skills-hub/skills/bitrix-orm .opencode/skills/
```

</details>

<details>
<summary><b>GitHub Copilot</b></summary>

Point Copilot at the agent in [agents/bitrix-coder.md](agents/bitrix-coder.md) and add the skill rules you need to your project's `.github/copilot-instructions.md`.

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
# Reference skill paths from the cloned repo in your copilot instructions
```

</details>

<details>
<summary><b>Windsurf</b></summary>

Add skill contents to your Windsurf rules configuration under `.windsurf/rules/`.

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
cp bitrix-skills-hub/skills/bitrix-orm/SKILL.md .windsurf/rules/bitrix-orm.mdc
```

</details>

<details>
<summary><b>Codex</b></summary>

Install as a native Codex plugin (Codex CLI v0.122+):

```bash
codex plugin marketplace add azimuth0x28/bitrix-skills-hub
codex plugin add bitrix-skills-hub@bitrix-skills-hub
```

The first command registers the marketplace; the second installs the plugin. Codex reads the root `skills/` directory through `.codex-plugin/plugin.json`. Once installed, invoke skills in chat using `@`.

</details>

<details>
<summary><b>Kiro IDE</b></summary>

Skills for Kiro reside under `.kiro/skills/` and can be stored at project or global level. Kiro also supports `AGENTS.md`.

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
cp -r bitrix-skills-hub/skills/bitrix-orm .kiro/skills/
```

See [Kiro docs](https://kiro.dev/docs/skills/) for details.

</details>

<details>
<summary><b>Antigravity CLI</b></summary>

Install as a native plugin for skills, subagents, and slash commands:

```bash
agy plugin install https://github.com/azimuth0x28/bitrix-skills-hub.git
```

Or from a local clone:

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
agy plugin install ./bitrix-skills-hub
```

</details>

<details>
<summary><b>Other Agents</b></summary>

Skills are plain Markdown — they work with any agent that accepts system prompts or instruction files.

```bash
git clone https://github.com/azimuth0x28/bitrix-skills-hub.git
cp -r bitrix-skills-hub/skills/bitrix-orm your-project/.agents/skills/
```

</details>

After installation, the rules and skill index from the original project live in [agents/bitrix-coder.md](agents/bitrix-coder.md): wire it up as a rule in Cursor or use it as the base for your own `AGENTS.md`.

## The catalog

Skills covering D7 core topics and adjacent areas. Each one is a self-contained reference an agent can apply immediately.

### Core & D7

| Skill | What It Does | Use When |
| --- | --- | --- |
| [bitrix-project-structure](skills/bitrix-project-structure/SKILL.md) | `/local` vs `/bitrix`, PSR-4, `.settings.php`, Loader | Placing code, module loading, autoloading config |
| [bitrix-settings](skills/bitrix-settings/SKILL.md) | Kernel `.settings.php` sections: connections, cache, session, routing, messenger | Configuring kernel behavior |
| [bitrix-modules](skills/bitrix-modules/SKILL.md) | CModule, install/index.php, DoInstall/DoUninstall, make:module | Creating new modules, registration |
| [bitrix-console-commands](skills/bitrix-console-commands/SKILL.md) | CLI tools, make:* generators, Symfony Console commands | Scaffolding, cron, queue workers |
| [bitrix-controllers](skills/bitrix-controllers/SKILL.md) | Engine Controller/JsonController, actions, filters, CurrentUser | AJAX/REST/routed endpoints |
| [bitrix-routing](skills/bitrix-routing/SKILL.md) | RoutingConfigurator, /local/routes, PublicPageController, urlrewrite | Public/API URL setup |
| [bitrix-orm](skills/bitrix-orm/SKILL.md) | D7 ORM tablets, ConditionTree, Objectify, batch/merge/deleteByFilter | Entity design, reads, persistence |
| [bitrix-events](skills/bitrix-events/SKILL.md) | Event system: new model (EventManager) + legacy (OnBefore*/OnAfter*) | Module integration, lifecycle hooks |
| [bitrix-validation](skills/bitrix-validation/SKILL.md) | ValidationService, #[NotEmpty]/#[Email]/#[Length], Request DTO | Input validation for controllers/services |
| [bitrix-service-locator](skills/bitrix-service-locator/SKILL.md) | DI container (PSR-11), autowire, constructor injection | Wiring dependencies, avoiding statics |
| [bitrix-result-and-errors](skills/bitrix-result-and-errors/SKILL.md) | Result, Error, ErrorCollection, AddResult, UpdateResult | Service APIs, error handling without exceptions |
| [bitrix-database](skills/bitrix-database/SKILL.md) | Connection, SqlHelper, SqlExpression, raw SQL, transactions, bulk ops | When ORM is insufficient, raw SQL, migrations |
| [bitrix-postgresql](skills/bitrix-postgresql/SKILL.md) | PgsqlConnection, MySQL migration, compatible code, support matrix | PostgreSQL Enterprise configuration |
| [bitrix-datetime](skills/bitrix-datetime/SKILL.md) | Date/DateTime, kernel masks, time zones, Culture, DateField | Schedules, timezone conversion, date arithmetic |
| [bitrix-request-response](skills/bitrix-request-response/SKILL.md) | HttpRequest/HttpResponse, Json/AjaxJson/Redirect, Uri | Replacing $_GET/$_POST, raw headers |
| [bitrix-storage](skills/bitrix-storage/SKILL.md) | PersistentStorageInterface, DeferredStorageDecorator, Option | Config vs TTL state vs derived cache |
| [bitrix-caching](skills/bitrix-caching/SKILL.md) | Cache, ManagedCache, TaggedCache, ORM auto-cache, Composite | Performance, invalidation, TTL, warm-up |
| [bitrix-performance](skills/bitrix-performance/SKILL.md) | Composite site, query optimization, replication, sharding | High-load optimization beyond caching |
| [bitrix-background-jobs](skills/bitrix-background-jobs/SKILL.md) | CAgent, addBackgroundJob, Messenger brokers/queues | Deferred and async processing |
| [bitrix-sprint-migration](skills/bitrix-sprint-migration/SKILL.md) | sprint.migration: Version, HelperManager, builders, CLI migrate.php | DB/schema/content migrations |

### Content & UI

| Skill | What It Does | Use When |
| --- | --- | --- |
| [bitrix-iblocks](skills/bitrix-iblocks/SKILL.md) | Iblock types/elements/sections, ORM compileEntity, properties, SEO | Content iblock work, structured data |
| [bitrix-highloadblock](skills/bitrix-highloadblock/SKILL.md) | HighloadBlockTable, compileEntity, DataManager CRUD, UF, ORM events | Custom entities, dynamic data models |
| [bitrix-components](skills/bitrix-components/SKILL.md) | class.php, templates, cache, SEF, Controllerable AJAX | Building or editing components |
| [bitrix-extensions](skills/bitrix-extensions/SKILL.md) | /local/js/ structure, bundle.config.js, Extension::load, @bitrix/cli | Adding frontend code to modules |
| [bitrix-ui](skills/bitrix-ui/SKILL.md) | Popup, SidePanel, MessageBox, entity-selector, grid, alerts, toasts | Admin interfaces, public UI components |
| [bitrix-vue](skills/bitrix-vue/SKILL.md) | BitrixVue 3, ui.vue3.bitrixvue, createApp, REST integration | Reactive admin/public UI with Vue |
| [bitrix-cms-basics](skills/bitrix-cms-basics/SKILL.md) | Sites, templates, menus, includes, breadcrumbs, styles, user fields | Site structure, content management |
| [bitrix-landing](skills/bitrix-landing/SKILL.md) | Landing sites, blocks repository, publish/unpublish, hooks | Sites24 pages, storefronts, knowledge bases |
| [bitrix-seo](skills/bitrix-seo/SKILL.md) | Sitemap, robots.txt, webmaster integration, IPROPERTY | Crawl maps, search engine wiring |

### Commerce

| Skill | What It Does | Use When |
| --- | --- | --- |
| [bitrix-catalog](skills/bitrix-catalog/SKILL.md) | Products, SKU/offers, prices, inventory, discounts, bundles | E-commerce: prices, stock, catalog API |
| [bitrix-sale](skills/bitrix-sale/SKILL.md) | Basket, Order, FUSER, payments, delivery, discounts, coupons | Cart/checkout, order lifecycle, pay/ship |
| [bitrix-bizproc](skills/bitrix-bizproc/SKILL.md) | CBPDocument, CBPRuntime, workflow templates, custom activities | Approvals, document workflows, automation |
| [bitrix-crm-smart](skills/bitrix-crm-smart/SKILL.md) | Smart processes (CRM dynamic entities): Service Container, Factory, operations, Item | Reading/filtering/updating smart-process items from code |

### Bitrix24 workspace

| Skill | What It Does | Use When |
| --- | --- | --- |
| [bitrix-tasks](skills/bitrix-tasks/SKILL.md) | Tasks V2 services + Internals ORM: TaskTable, MemberTable, UpdateTaskService, responsible changes | Reading/updating tasks, reassignment, status filters |
| [bitrix-socialnetwork](skills/bitrix-socialnetwork/SKILL.md) | Workgroups & projects: UserToGroupTable, WorkgroupTable, CSocNetUserToGroup, roles, SetOwner | Membership changes, role/owner transfer, member queries |

### Project Rules & Onboarding

| Skill | What It Does | Use When |
| --- | --- | --- |
| [bitrix-prime-codebase](skills/bitrix-prime-codebase/SKILL.md) | Reality map of an existing codebase: structure, ORM, migrations, events, agents, style, git — with file:line evidence | Brownfield analysis before generating project rules |
| [bitrix-rules-create-global](skills/bitrix-rules-create-global/SKILL.md) | Global rules: lean root AGENTS.md + `.agents/rules/core/` files, from templates (Greenfield) or codebase analysis (Brownfield) | Project init, developer onboarding, replacing generic init |
| [rules-check-drift](skills/rules-check-drift/SKILL.md) | Checks the rules file against recent changes; minimal edits keep it true and lean | Before merges, inside code-review passes |

### Integrations & Platform

| Skill | What It Does | Use When |
| --- | --- | --- |
| [bitrix-rest](skills/bitrix-rest/SKILL.md) | REST methods, scopes, webhook/OAuth, rest settings | Exposing APIs to apps/webhooks/marketplace |
| [bitrix-pull](skills/bitrix-pull/SKILL.md) | Pull module: realtime events, JS subscription, watch tags | Live UI updates, notifications |
| [bitrix-http-client](skills/bitrix-http-client/SKILL.md) | HttpClient, PSR-18, async Promise, SSRF, GeoIp | External API integrations, webhooks |
| [bitrix-logger](skills/bitrix-logger/SKILL.md) | PSR-3: FileLogger, SysLogger, LogFormatter, Monolog | Module logs, debugging, log rotation |
| [bitrix-localization](skills/bitrix-localization/SKILL.md) | Loc, lang files, loadMessages, BX.message, translate:index | i18n, multi-language sites, JS translations |
| [bitrix-security](skills/bitrix-security/SKILL.md) | CSRF, XSS, SQLi, SSRF, JWT/JWK, access rights, encryption | Input handling, security auditing |
| [bitrix-sessions](skills/bitrix-sessions/SKILL.md) | Application::getSession(), read-only/virtual modes, separated mode | Session management, AJAX lock tuning |

### Meta

| Skill | What It Does | Use When |
| --- | --- | --- |
| [bitrix-knowledge-skill-creator](skills/bitrix-knowledge-skill-creator/SKILL.md) | Authoring conventions: morphology, frontmatter, baseline/Since, density | Creating knowledge skills (how to work correctly/incorrectly with kernel classes, ORM, module APIs; best practices) |
| [bitrix-workflow-skill-creator](skills/bitrix-workflow-skill-creator/SKILL.md) | Workflow-skill conventions: decision tables, project facts, procedures, tool versions | Creating workflow/process skills (code style, devops setup, review rules) |
| [bitrix-skill-eval](skills/bitrix-skill-eval/SKILL.md) | Blind test protocol, Q1-Q10 rubric, hard gates, density metric | Grading skill drafts |
| [skill-validator](skills/skill-validator/SKILL.md) | quick_validate.py (format), prism-scanner (security), grade gates | Pre-PR mechanical validation |

## Agent Personas

Pre-configured specialist personas for Bitrix development:

| Agent | Role | Perspective |
| --- | --- | --- |
| [bitrix-coder](agents/bitrix-coder.md) | Bitrix Framework Specialist | Deep D7 knowledge, DI boundaries, `/local/` conventions, security patterns, version policy |

## Skill anatomy

```
skills/<name>/
├── SKILL.md      # router: description, triggers, links to rules
├── rules/*.md    # rules by topic; the agent reads only the ones it needs
└── references/   # template assets (some workflow skills): copied verbatim into the target project
```

Fat skills use progressive disclosure: the agent opens `SKILL.md` first, then only the `rules/` files it needs. Skills are self-sufficient and anchored to the core: verified against **main 26.150.0**, baseline patterns **main 23.0+**.

## Adding your own

Author a new skill through `bitrix-knowledge-skill-creator` (knowledge skills: correct/incorrect usage and best practices — the default) or `bitrix-workflow-skill-creator` (workflow skills: processes, conventions, environment setup). Run the finished draft through `skill-validator` (format + security) and `bitrix-skill-eval`: the blind test and the Q1-Q10 rubric filter out weak skills before they enter the catalog.

## Links

- [docs.1c-bitrix.ru](https://docs.1c-bitrix.ru/) — documentation for "1C-Bitrix: Site Management"
- [apidocs.bitrix24.ru](https://apidocs.bitrix24.ru/) — REST API for Bitrix24
- [bitrix-tools/best-practice](https://github.com/bitrix-tools/best-practice) — operational practices from the Bitrix Tools team
- [bxmaximum/bitrix_ai_challenge](https://github.com/bxmaximum/bitrix_ai_challenge) — research on AI models applied to Bitrix

## License

MIT.

## Acknowledgements

This hub is built on top of [bxmaximum/bitrix-framework-skills](https://github.com/bxmaximum/bitrix-framework-skills) — a skill collection maintained by the [BXMax](https://bxmax.ru) community. Thanks for the great work and the open license: this entire repo grew from that foundation.
