---
name: bitrix-localization
description: Covers Bitrix localization — Loc, lang/code/ language files, Context::getCulture(), JS via BX.message and $Bitrix.Loc, user_lang overrides of kernel phrases. Applied when adding phrases, overriding kernel/module/component phrases without forking, multi-language sites, JS translations. Key terms — Loc, getMessage, lang file, user_lang, MESS, Culture, BX.message, loadMessages, i18n.
metadata:
  type: knowledge
---

# Localization

Baseline: **main 23.0+**.

## Language File

- Encoding **UTF-8 without BOM**.
- Translation file name **matches** the name of the PHP file it accompanies.
- Folder: `.../lang/<lang>/<...>` mirrors the structure of the main code.

```
/local/modules/vendor.module/lib/Application/Service/PostService.php
/local/modules/vendor.module/lib/Application/Service/lang/ru/PostService.php
/local/modules/vendor.module/lib/Application/Service/lang/en/PostService.php
```

Content:

```php
<?php
$MESS['VENDOR_MODULE_POST_PUBLISHED'] = 'Post #NAME# published';
$MESS['VENDOR_MODULE_POST_EMPTY_TITLE'] = 'Post title is empty';
```

Prefix rules: `<VENDOR>_<MODULE>_<CONTEXT>_<CODE>` — a short unique key. Without a prefix, conflicts with other modules are likely.

## `Loc::getMessage` and Loading Phrases

```php
use Bitrix\Main\Localization\Loc;

Loc::loadMessages(__FILE__); // knowing where we are — the kernel will find the translation file

echo Loc::getMessage('VENDOR_MODULE_POST_PUBLISHED', ['#NAME#' => $post->getTitle()]);
echo Loc::getMessage('VENDOR_MODULE_POST_PUBLISHED', ['#NAME#' => 'x'], 'en');
```

- Signature: `Loc::getMessage(string $code, ?array $replace = null, ?string $language = null)`.
- Substitutions — via `#PLACEHOLDER#` templates (historical convention). Keys in `$replace` — with hash marks.
- `$language` — language ID (`ru`, `en`). If not passed — current site language.

`Loc::loadMessages(__FILE__)` resolves the neighboring `lang/<lang>/<same_file>.php` from the caller path. `Loc::loadLanguageFile($path)` loads phrases for an arbitrary PHP file path (when the mapping is not “same name next to `__FILE__`”).

### When Explicit Loading is Needed

For components, component templates, site templates, and Bitrix admin files, the kernel will automatically include neighboring `lang/<lang>/<same_file>.php`. Manually call `Loc::loadMessages(__FILE__)` if:

- The file is outside the standard structure (e.g., `/local/php_interface/`).
- You have your own loader/class — each file must **itself** include its translations, otherwise lazy loading will break.

### Arbitrary File

```php
Loc::loadLanguageFile($_SERVER['DOCUMENT_ROOT'] . '/local/php_interface/custom.php');
```

### Module Default Language

```php
$lang = Loc::getDefaultLang(LANGUAGE_ID); // fallback from language settings: 'ru' → 'ru', 'ua' → 'ru'
```

Use this when forming language package names if the project language is broader than those supported in the module (`ua`, `kz` → "fall back" to `ru`).

## Lazy Loading and `BX_MESS_LOG`

The kernel loads a language file **only upon the first** `getMessage(...)` call from it — the "PHP file ↔ language file" mapping must be strict. If a `getMessage('FOO_BAR')` call comes from one file while the phrase is defined in another, the kernel will start scanning all files — this slows things down.

Diagnostics: enable in `/local/php_interface/init.php`:

```php
define('BX_MESS_LOG', $_SERVER['DOCUMENT_ROOT'] . '/var/log/bitrix/mess.log');
```

The log will contain entries like:

```
[ru]SOME_MESSAGE: not found for /path/to/file.php
CTranslateUtils::CopyMessage('DEMO_CODE', '/path/a.php', '/path/b.php');
```

How to fix:

- **Copy** the phrase to the language file of the module/code where the `getMessage` call originates.
- **Rename** the code to something unique if it conflicts with the kernel.
- **Move the code** to the correct file if it physically ended up in the wrong place.

Do not copy automatically — you might duplicate phrases; investigate the cause.

## Overriding Kernel Phrases (`user_lang`)

Reword a kernel-module or system-component phrase without forking it: put overrides into `php_interface/user_lang/<lang>/lang.php`. The kernel reads it via `getLocal()` — `/local/php_interface/user_lang/...` wins over `/bitrix/php_interface/user_lang/...` (`Loc::loadUserMessages()` in `bitrix/modules/main/lib/localization/loc.php`, legacy `__IncludeLang()` in `bitrix/modules/main/tools.php`).

Format: `$MESS` keys are **paths to the lang file** from the site root — leading `/` mandatory, matched via `realpath(DOCUMENT_ROOT . $key)`; values are `code => text` arrays:

```php
$MESS['/bitrix/modules/main/lang/ru/interface/index.php']['admin_index_sec'] = 'New wording';
$MESS['/bitrix/components/bitrix/system.auth.form/templates/.default/lang/ru/template.php']['AUTH_PROFILE'] = 'My profile';
```

**Never** key by the PHP file that calls `getMessage` — the merge fires only on the `lang/<lang>/...` file's `realpath()`; a wrong key never applies and fails silently.

### Which path to key

One component template can be served from several physical locations — the override fires only for the actually loaded one:

| Path (from site root) | When |
| --- | --- |
| `/local/templates/<tmpl>/components/<ns>/<name>/templates/<t>/lang/ru/<file>.php` | site-template copy — wins first |
| `/local/components/<ns>/<name>/templates/<t>/lang/ru/<file>.php` | local component copy |
| `/bitrix/components/<ns>/<name>/templates/<t>/lang/ru/<file>.php` | standard copy — module updates place install components here |
| `/bitrix/modules/<module>/install/components/<ns>/<name>/templates/<t>/lang/ru/<file>.php` | direct module source |

When the dev mirror does not show the live layout (`bitrix/` is often partially mirrored), write one `$MESS` entry per plausible path — unmatched keys are ignored — and verify the live one with `ls` on the host.

### Locating a phrase code

```bash
grep -rn '"PHRASE_CODE"' bitrix/modules/<module>/ local/   # definition + usages, PHP and JS
```

- Definitions live only in `lang/` trees: `bitrix/modules/<module>/lang/ru/...` (kernel/admin) and `.../install/components/<ns>/<name>/templates/<t>/lang/ru/<file>.php` (component templates).
- Component JS reads `BX.message('CODE')` — the template publishes its lang file (`BX.message(phpToJsObject(Loc::loadLanguageFile(__FILE__)))` in `template.php`); override the lang file, **never** patch `script.min.js`.
- The same code may exist in several dialogs of one module (old and new UI) — grep the whole module tree before keying a single file.
- Rewording only → `user_lang`; layout/logic changes → copy the component template (see skill `bitrix-components`).

### Limits

- A `/local/` user_lang file **shadows** `/bitrix/php_interface/user_lang/<lang>/lang.php` entirely — if the admin *Translation* UI already wrote one, merge its entries.
- Mail event templates are DB rows (`b_event`, *Settings → Mail & SMS*) — phrase overrides have no effect there.
- HTML/composite caches keep already-emitted `BX.message` — flush caches after deploy.
- Override only languages the portal serves (usually `ru`); other `lang/` variants keep originals.

## Regional Settings (`Culture`)

Date/time/name formats are retrieved from `Bitrix\Main\Context\Culture`:

```php
$culture = \Bitrix\Main\Context::getCurrent()->getCulture();
$culture->getDateTimeFormat();   // 'DD.MM.YYYY HH:MI:SS'
$culture->getDateFormat();       // 'DD.MM.YYYY'
$culture->getShortTimeFormat();  // 'HH:MI'
$culture->getNameFormat();       // '#LAST_NAME# #NAME# #SECOND_NAME#'
$culture->getNumberDecimals();
$culture->getNumberDecSeparator();
$culture->getNumberThousandsSeparator();
```

Formatting:

```php
use Bitrix\Main\Type\DateTime;

$date = new DateTime();
echo $date->format($culture->getDateTimeFormat());

// Via classic helpers:
echo \FormatDate($culture->getDateFormat(), $date->getTimestamp());
echo \CurrencyFormat(1234.5, 'RUB');
```

Language setup: *Settings → Product Settings → Language Parameters* (date/time/name formats are set per site language). If a component is configured for its own format — it will take precedence.

## Setting Phrases in JavaScript

PHP code publishes phrases in `BX.message(...)`:

```php
\Bitrix\Main\Page\Asset::getInstance()->addString(
    '<script>' . \Bitrix\Main\Web\Json::encode([
        'VENDOR_POST_SAVE'   => Loc::getMessage('VENDOR_POST_SAVE'),
        'VENDOR_POST_CANCEL' => Loc::getMessage('VENDOR_POST_CANCEL'),
    ]) . '</script>'
);
```

Or — more idiomatically — via a JS extension in `config.php`:

```php
return [
    'js'       => 'script.js',
    'css'      => 'style.css',
    'rel'      => ['main.core'],
    'lang_additional' => [
        'VENDOR_POST_SAVE', 'VENDOR_POST_CANCEL',
    ],
];
```

```js
BX.message('VENDOR_POST_SAVE');

BX.message({ VENDOR_POST_DYNAMIC: 'Loaded asynchronously' });

const welcome = BX.message('WELCOME_TEXT').replace('#NAME#', userName);
```

## BitrixVue 3

```js
// template
<button>{{ $Bitrix.Loc.getMessage('UI_BUTTON_SAVE') }}</button>

// with replacement + reactivity
{{ $Bitrix.Loc.getMessage('DEMO_COUNTER', { '#COUNTER#': this.counter }) }}

// programmatically
this.$Bitrix.Loc.setMessage({ DEMO_COUNTER: 'Counter: #COUNTER#' });

// optimization for heavy templates — (vueInstance, phrasePrefix, phrases?)
import { BitrixVue } from 'ui.vue3';

computed: {
    localize() { return BitrixVue.getFilteredPhrases(this, 'MYCOMP_'); }
}
```

## `translate:index` Command

```bash
php bitrix/bitrix.php translate:index
```

Indexes language files so that the *Settings → Localization → View Files* page works (CSV export/import, package building). Run this after bulk adding new phrases to a module.

## Multilingual Modules

- Store phrases in `lang/ru/`, `lang/en/`, `lang/de/` — in the root of the PHP file that uses them.
- In the module's `install/index.php`, include translations: `Loc::loadMessages(__FILE__)`.
- Use `Loc::getDefaultLang(LANGUAGE_ID)` to "fall back" to the module's base language (`ru`) if `kz`/`ua` is missing.
- Publish language names in the system via the *Interface Languages* form — it cannot be set from `.settings.php`.

## Antipatterns

- Hardcoding strings in services/controllers. `Error` message texts should be via `Loc::getMessage`.
- `getMessage('CODE')` in one file when the phrase is defined in another → scanning all files, slowdown.
- Rewording kernel phrases by editing `bitrix/` files or `script.min.js` — overrides go to `user_lang`.
- A `user_lang` key pointing at the PHP file instead of its `lang/<lang>/` file — the override never fires.
- Copying phrases between modules via `BX_MESS_LOG` without analysis — risk of duplication and confusion.
- Outputting dates via `date('d.m.Y')` instead of `Culture::getDateFormat()` — breaks multilingual projects.
- Mixing UTF-8 and CP1251 in `lang/` — Bitrix will "re-convert" and you'll get garbled text.
- JS phrases written as strings from PHP without `htmlspecialcharsbx` for headers going into attributes.

Set `default_language` in `.settings.php` for kernel default. BitrixVue 3 localization: skill `bitrix-vue`.
