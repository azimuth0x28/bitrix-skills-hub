# Changelog

Все заметные изменения проекта. Формат — [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
версионирование — [SemVer](https://semver.org/lang/ru/).

## [1.6.0] — 2026-10-12

### Добавлено

- **Гейт вендор-нейтральности.** Третья автоматическая проверка перед PR: скрипт
  `skills/skill-validator/scripts/check-vendors.sh` падает, если в вендорном слоте (префикс пути
  модуля, префикс AJAX-действия, id в `includeModule`) стоит конкретный вендор. Модель — allowlist,
  default-deny: разрешены только нейтральный плейсхолдер `Acme`/`vendor` и вендор, объявленный в
  навыке как `metadata.vendor`. Шаг добавлен в CI (`.github/workflows/validate.yml`, джоба
  `consistency`).
- **Критерий Q11 «Vendor neutrality»** в `bitrix-skill-eval` со своим hard gate; итоговая оценка —
  среднее по Q1–Q11.
- **Правило вендор-нейтральности в мета-скиллах** `bitrix-knowledge-skill-creator` и
  `bitrix-workflow-skill-creator`: вендор по умолчанию нейтральный, назначенный пользователем
  применяется только при явном выборе и фиксируется в `metadata.vendor`.
- **Правило code references.** Любая ссылка на код в тексте навыка ведёт на ядро Bitrix или на
  файл, который поставляет сам навык; код вендорных и кастомных модулей поставляется выдержкой в
  `references/<name>.md` со ссылкой из тела. Исключение — навык под один конкретный проект.
- **Правило no editing notes.** Текст навыка несёт только суть: без пояснений, что вендор обезличен,
  путь переписан или пример урезан.
- **Новые примеры-референсы:** `references/crm-page-detector.md` в `bitrix-routing` и
  `bitrix-crm-smart`, `references/crm-kanban-detection.md` в `bitrix-crm-smart`.
- **Детекция страниц** в `bitrix-crm-smart`: раздел «Page detection (kanban, detail)» со сверкой
  обоих кандидатов пути против обоих корней CRM.

### Изменено

- Примеры в `bitrix-chef` и `bitrix-routing` переведены на нейтральный плейсхолдер вместо
  конкретного вендора.
- `bitrix-sprint-migration` объявляет `metadata.vendor: sprint` для задокументированного стороннего
  модуля.
- `AGENTS.md`: три автоматические проверки, подраздел «Vendor neutrality», пункт PR-чеклиста и
  запрет в «Hard prohibitions».
- Каталог и проза в `README.md` / `README.ru.md` выровнены на Q1–Q11.

### Версии скиллов

- **1.0.1** — `bitrix-chef`.
- **1.1.0** — `bitrix-skill-eval`.
- **1.1.1** — `bitrix-sprint-migration`.
- **1.2.0** — `bitrix-routing`, `bitrix-crm-smart`, `skill-validator`.
- **1.3.0** — `bitrix-workflow-skill-creator`.
- **1.4.0** — `bitrix-knowledge-skill-creator`.

## [1.5.0] — 2026-10-02

### Добавлено

- **Скилл `bitrix-userfield`** — кастомные типы пользовательских полей end to end: класс типа
  (наследование `BaseType`, обязательный `getDbColumnType`), регистрация через `OnUserTypeBuildList`,
  хранение (UTS/UTM, HL-блоки), рендер-компонент, JS-пикер с entity-selector, фильтр в CRM-гриде,
  вывод в бизнес-процессах. Следом — чеклисты-эхо: каждый запрет в правилах теперь продублирован
  проверяемым пунктом.

### Исправлено (верификация по ядру 26.400.0)

- **Точность API.** Из скиллов убраны несуществующие методы: в `bitrix-orm` выдуманный `addBatch`
  заменён на реальный `addMulti`, а `merge`/`insert-ignore` и удаление коллекций привязаны к версии
  ядра (Since main 25.575); в `bitrix-performance` вместо придуманной разметки композита описаны
  настоящие frame-API; в `bitrix-localization` хелпер публикации фраз получил реальный префикс `CUtil`.
- **Правильные сигнатуры вызовов.** Параметры `DiscountCouponsManager::init` в `bitrix-sale`,
  вызов `Model\Price::add` в `bitrix-catalog` (чтобы `PRICE_SCALE` выводился автоматически), имя
  параметра в `registerEventHandler` и legacy-контракт FIELDS в `bitrix-events`, константы
  `HttpMethod` в `bitrix-controllers`, подпись колбэка без команды в `bitrix-pull`, семантика ошибок
  `Generator::run` в `bitrix-seo`.
- **Жизненные сценарии.** `bitrix-settings` требует SMTP-логин только когда задан пароль;
  `bitrix-postgresql` описывает блокировку мастера конвертации на несовместимых модулях;
  `bitrix-database` уточнил stop-API трекера, предупреждения при вставке и плейсхолдеры дат;
  в `bitrix-sprint-migration` поправлены имена хелперов и дефолты extra-config;
  `bitrix-console-commands` — правильный путь к tablet и версионная пометка `--limit`.
- **UI-слой.** `bitrix-vue` переведён на импорт из `ui.vue3` и глобал `BX.Vue3`;
  в `bitrix-extensions` исправлен путь локального расширения и переименован лейбл, из-за которого
  security-сканер давал ложное срабатывание; `bitrix-landing` уточнил `skip_blocks`, возврат
  `addBlock` и область действия рецепта VIBE; `bitrix-background-jobs` — отсутствие аргументов
  родительского конструктора, корректная блокировка агента и тайминг.

### Документация и процесс

- Каталог в обоих README дополнен строкой под `bitrix-userfield`.
- Верификационная версия во всех скиллах выровнена на main 26.400.0.
- В AGENTS.md добавлена заметка о том, что корневой файл не попадает в установку через
  `npx skills add`.
- `.gitignore` закрыл локальные артефакты bmad.

### Версии скиллов

- **1.1.0** — 16 скиллов, включая новый `bitrix-userfield`.
- **1.1.1** — `bitrix-extensions`.
- **1.2.0** — `bitrix-database`, `bitrix-localization`, `bitrix-orm` (крупнейшие правки,
  сопровождались переоценкой по протоколу `bitrix-skill-eval`).

[1.6.0]: https://github.com/azimuth0x28/bitrix-skills-hub/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/azimuth0x28/bitrix-skills-hub/compare/v1.4.1...v1.5.0