---
name: bitrix-ui
description: Covers Bitrix UI library — main.popup, main.sidepanel, ui.system.dialog, ui.dialogs.messagebox, ui.system.menu, ui.system.input, ui.alerts, ui.notification (toasts), ui.entity-selector (Dialog, TagSelector, providers), main.ui.grid, main.ui.filter, ui.icon-set, ui.lottie, ui.a11y, typography. Applied when building admin interfaces and public UI with kernel components. Key terms — Extension::load, Popup, SidePanel, system-dialog, MessageBox, ui.alerts, entity-selector, grid, filter, ui.a11y, UI kit.
---

# Bitrix UI Library

Modern admin and public interfaces use JS extensions from `ui` and `main` modules. Load via `Extension::load()` in PHP, import classes in modular JS.

## Choosing a Component

| Scenario | Extension |
| --- | --- |
| Full modern dialog (title, content, custom layout) | `ui.system.dialog` (`Dialog`) — preferred for new UI |
| Simple confirm / alert / message box | `ui.dialogs.messagebox` (`MessageBox`) |
| Context/dropdown menu (modern) | `ui.system.menu` |
| Popup with custom positioning, legacy | `main.popup` |
| Slide-over panel (CRM-style) | `main.sidepanel` |
| Toast notifications | `ui.notification` (`BX.UI.Notification.Center`) |
| Alerts/banners (inline UI alerts) | `ui.alerts` |
| Form inputs (modern) | `ui.system.input`, `ui.system.label`, `ui.system.chip` |
| Pick users/departments/custom entities | `ui.entity-selector` (`Dialog`, `TagSelector`) |
| Data table: columns, sorting, paging, row actions | PHP component `bitrix:main.ui.grid` |
| Search + filter fields with presets above a list | PHP component `bitrix:main.ui.filter` |
| Icons | `ui.icon-set.api.core` + per-set CSS extension |
| Loading skeleton | `ui.system.skeleton` |
| Hints/tooltips | `ui.hint` |
| Lottie animations | `ui.lottie` |
| Keyboard focus, focus trap, screen-reader live region | `ui.a11y` |

### `ui.system.dialog` vs `ui.dialogs.messagebox`

- **`ui.system.dialog`** — modern system `Dialog` component (structured dialog UI for new admin screens).
- **`ui.dialogs.messagebox`** — classic `MessageBox` helpers (`confirm`, `alert`, `show`) for quick confirmations. Use MessageBox for simple prompts, Dialog for richer UI.

There is **no** extension `ui.system.alert` — use **`ui.alerts`**.

## Loading Pattern

```php
\Bitrix\Main\UI\Extension::load(['ui.system.dialog', 'ui.alerts', 'ui.notification']);
```

```javascript
import { Dialog } from 'ui.system.dialog';
import { MessageBox } from 'ui.dialogs.messagebox';
import { Alert, AlertColor } from 'ui.alerts';
// ui.notification is non-modular — use the global BX.UI.Notification.Center
```

Lazy-load in JS when needed: `Runtime.loadExtension('ui.entity-selector').then((exports) => { ... })`.

## System Dialog / Message Box / Alerts

```javascript
import { Dialog } from 'ui.system.dialog';
new Dialog({ title: 'Settings', content: contentNode /* HTMLElement */, rightButtons: [...] }).show();
// other options: subtitle, hasCloseButton, hasOverlay, closeByEsc, closeByClickOutside, width, background

import { MessageBox } from 'ui.dialogs.messagebox';
MessageBox.confirm('Delete item?', () => { /* on confirm */ });
MessageBox.alert('Done');

import { Alert, AlertColor } from 'ui.alerts';
const alert = new Alert({ text: 'Saved', color: AlertColor.SUCCESS });
```

## Popup (legacy/base) and Side Panel

```javascript
import { Popup } from 'main.popup';
new Popup({ id: 'my-popup', content: 'Saved', closeIcon: true }).show();

// main.sidepanel:
BX.SidePanel.Instance.open('/local/admin/custom-page.php', { width: 800, cacheable: false });
```

## Notifications (toasts)

Extension `ui.notification` (global API, no ES exports):

```javascript
BX.UI.Notification.Center.notify({ content: 'Saved', autoHide: true, autoHideDelay: 8000, position: 'top-right' });
```

Do not confuse with `ui.notification-manager` — a separate extension (`Notification`, `Notifier` in `BX.UI.NotificationManager`) for cross-tab/desktop notifications with categories and buttons, not for simple toasts.

## Entity Selector (`ui.entity-selector`)

Two widgets: `Dialog` (popup picker) and `TagSelector` (field showing selected items as tags). Items are identified by the pair `entityId` + `id`; minimal local item: `{ id, entityId, title }`.

```javascript
import { Dialog, TagSelector } from 'ui.entity-selector';

const dialog = new Dialog({
    targetNode: button,              // must be an existing DOM node
    context: 'MY_MODULE_RESPONSIBLE', // separate context per form — recent items don't mix
    multiple: false,
    enableSearch: true,
    entities: [{ id: 'user' }, { id: 'department' }], // server-side load via PHP providers
    events: { 'Item:onSelect': (e) => { const { item } = e.getData(); } },
});
button.addEventListener('click', () => dialog.show());
```

`TagSelector` with a linked dialog: pass `dialogOptions` (same options as `Dialog`); `preselectedItems: [['user', 1]]` loads selected items from the server; render with `selector.renderTo(container)`.

Provider entity ids come from installed modules — each registers them in its `.settings.php` under the `ui.entity-selector` key (e.g. `iblock-element` from iblock, `product`/`store` from catalog). Bitrix24 modules (intranet/socialnetwork/im) add `user`, `department`, `project`, `meta-user`, `im-chat` etc. Check the target module's `.settings.php` for the exact id before using it.

Custom provider — PHP class extending `Bitrix\UI\EntitySelector\BaseProvider` (implement `isAvailable()` — must check rights, `getItems()`; optionally `fillDialog()`, `doSearch()`), registered in module `.settings.php`:

```php
'ui.entity-selector' => [
    'value' => [
        'entities' => [[
            'entityId' => 'project',
            'provider' => ['moduleId' => 'my.module', 'className' => ProjectProvider::class],
        ]],
    ],
    'readonly' => true,
],
```

Rules: `entities[].id` in JS must equal the registered `entityId`; `dynamicLoad` / `dynamicSearch` only work when a PHP provider is registered and available.

## Grid and Filter (`main.ui.grid` / `main.ui.filter`)

PHP components for admin-style lists. They render UI and store user settings only — **your server code fetches, filters, sorts and limits the data** before `IncludeComponent()`. To link filter with grid, pass the **same id** to `FILTER_ID` and `GRID_ID`.

```php
use Bitrix\Main\UI\Filter\Options as FilterOptions;
use Bitrix\Main\Grid\Options as GridOptions;

$gridId = 'orders_grid';
$filterFields = [
    ['id' => 'FIND', 'name' => 'Search'],
    ['id' => 'STATUS', 'name' => 'Status', 'type' => 'list', 'items' => ['' => 'Any', 'new' => 'New']],
];
$filter = (new FilterOptions($gridId))->getFilter($filterFields); // user values
$sorting = (new GridOptions($gridId))->getSorting(['sort' => ['ID' => 'desc']]);
// build $ormFilter from $filter, run query with $sorting['sort'], build $rows

$APPLICATION->IncludeComponent('bitrix:main.ui.filter', '', [
    'FILTER_ID' => $gridId, 'GRID_ID' => $gridId, 'FILTER' => $filterFields, 'ENABLE_LABEL' => true,
]);
$APPLICATION->IncludeComponent('bitrix:main.ui.grid', '', [
    'GRID_ID' => $gridId,
    'COLUMNS' => [['id' => 'ID', 'name' => 'ID', 'sort' => 'ID', 'default' => true]],
    'ROWS' => $rows,        // each: ['id' => 42, 'data' => [...], 'actions' => [...]]
    'SORT' => $sorting['sort'], 'ALLOW_SORT' => true,
    'AJAX_MODE' => 'Y', 'AJAX_OPTION_JUMP' => 'N', 'AJAX_OPTION_HISTORY' => 'N',
]);
```

- Filter field types: `string`, `textarea`, `list` (multiple via `params.multiple = 'Y'`), `number`, `date` (`time => true` for datetime; hide subtypes via `exclude` + `Bitrix\Main\UI\Filter\DateType::*`), `custom_date`, `entity_selector` (dialog options in `params.dialogOptions`; `params.addEntityIdToResult = 'Y'` when several entity types share one field). Prefer `entity_selector` over legacy `dest_selector` / `custom_entity` in new UI. Ranges return suffixed keys: `_from`, `_to`, `_datesel`, `_numsel`.
- Presets: `FILTER_PRESETS => ['key' => ['name' => ..., 'fields' => [...], 'default' => true]]`. Settings are stored by `FILTER_ID`/`GRID_ID` — changing the id loses saved user presets/columns.
- Pagination: `Bitrix\Main\UI\PageNavigation` in `NAV_OBJECT` + `TOTAL_ROWS_COUNT`; apply `$nav->getLimit()/getOffset()` to the query yourself. Pass `PAGE_SIZES` / `SHOW_PAGESIZE` / `SHOW_PAGINATION` when the list is paged.
- Columns: use `COLUMNS` in new code (`HEADERS` is compatibility-only). `ROW_LAYOUT` disables column/row sorting. Row HTML goes into `ROWS[]['columns']` — escape user data with `HtmlFilter::encode()`.
- Group actions: `ACTION_PANEL` + `SHOW_ROW_CHECKBOXES`/`SHOW_ACTION_PANEL`/`SHOW_SELECTED_COUNTER`. Re-check rights server-side.
- For module-level grids with a `Bitrix\Main\Grid\Grid` subclass, pass `ComponentParams::get($grid)` (from `Bitrix\Main\Grid\Component\ComponentParams`) as component params. A dedicated `Bitrix\Main\Filter\Filter` + provider is optional; `FilterOptions::getFilter()` is enough for a plain component page.

## Lottie (`ui.lottie`)

Based on Lottie 5.13 (`import { Lottie } from 'ui.lottie'` or global `BX.UI.Lottie`):

```javascript
const animation = BX.UI.Lottie.loadAnimation({
    container: node,                 // must exist in DOM
    path: '/local/assets/loader.json', // or animationData: {...} — pass one source
    renderer: 'svg', loop: true, autoplay: true,
});
```

Returns an `AnimationItem`: `play()`, `stop()`, `pause()`, `togglePause()`, `setSpeed()`, `setDirection()`, `goToAndStop()`, `goToAndPlay()`, `destroy()` (call on teardown). Optional `name` lets you call `BX.UI.Lottie.play(name)` later. Events via `animation.addEventListener('complete' | 'loopComplete' | 'data_ready' | 'data_failed' | 'DOMLoaded' | 'destroy', ...)`.

## Accessibility (`ui.a11y`)

Use when a dialog, menu, or live UI must keep keyboard focus or announce changes to a screen reader. Load `ui.a11y` (`FocusMonitor.initialize()` runs on import).

| Need | Class |
| --- | --- |
| Restore focus after close / DOM redraw | `FocusMonitor` |
| Move focus to the next/previous focusable node | `FocusNavigator` |
| Trap Tab inside a modal/dialog | `FocusTrap` |
| Arrow / Home / End keys inside a widget | `FocusZone` |
| Keyboard vs mouse vs touch vs stylus | `InputModalityTracker` |
| Is the node visible / enabled / focusable | `InteractivityChecker` |
| Speak a message without moving focus | `LiveAnnouncer` |
| Visually hide, keep for AT | `VisuallyHidden` |

```javascript
import { FocusTrap, LiveAnnouncer } from 'ui.a11y';

const trap = new FocusTrap(dialogNode);
trap.activate();
// on close:
trap.deactivate();

LiveAnnouncer.announce('Saved', 'polite'); // or 'assertive'
```

Optional kernel config (`Configuration::getValue('ui')['a11y']` in the extension `config.php`):

```php
'ui' => [
    'value' => [
        'a11y' => [
            'restoreLostFocus' => true,
            'useFocusTrapInDialogs' => true,
        ],
    ],
    'readonly' => false,
],
```

On a regular product install both flags default to `false` (they default to `true` only when `\Dev\Main\Migrator\ModuleUpdater` exists). Do not assume traps are on globally — activate `FocusTrap` in your dialog.

## Icons (`ui.icon-set`)

JS API is `ui.icon-set.api.core` (class `Icon` + name sets); each set also needs its **CSS extension loaded, or the icon won't render**. Sets (exported from `ui.icon-set.api.core`): `Actions`, `Main`, `Outline`, `Solid`, `Social`, `CRM`, `Editor`, `ContactCenter`, `Animated`, `Special`, `Disk`/`DiskCompact` (fixed colors, `color` ignored), `SmallOutline` — CSS extensions `ui.icon-set.actions`, `ui.icon-set.main`, `ui.icon-set.outline`, etc.

```javascript
import { Icon, Outline, IconHoverMode } from 'ui.icon-set.api.core';
import 'ui.icon-set.outline';

new Icon({ icon: Outline.CHECK_L, size: 24, color: 'var(--ui-color-base-70)' }).renderTo(container);
```

- Vue: `BIcon` from `ui.icon-set.api.vue` (props `name`, `size`, `color`, `hoverable`, `responsive`).
- Static HTML (no JS control): `<div class="ui-icon-set --check-l"></div>`; size/color via CSS vars `--ui-icon-set__icon-size`, `--ui-icon-set__icon-color`.
- Use named icons from the sets, not inline SVG copies. Load `ui.design-tokens` / typography extensions for consistent styling.

## Checklist

- [ ] Prefer `ui.system.dialog` / `ui.system.*` over legacy `main.popup` for new admin UI; `ui.dialogs.messagebox` for simple confirms.
- [ ] Alerts via `ui.alerts`, not a non-existent `ui.system.alert`.
- [ ] Extensions loaded in PHP before inline scripts; modular JS uses `import`, not global `BX` where avoidable.
- [ ] Entity selector: `entities[].id` matches the registered provider `entityId`; provider `isAvailable()` checks rights; distinct `context` per form.
- [ ] Grid/filter share one `GRID_ID`; server code applies filter, sort and nav limits itself; row HTML escaped via `HtmlFilter::encode()`.
- [ ] Icons: `ui.icon-set.api.core` plus the set's CSS extension (e.g. `ui.icon-set.outline`) — both loaded.
- [ ] Lottie instances `destroy()`ed on teardown; side panel URLs are real routes with proper auth.
- [ ] Dialogs/menus that steal focus use `ui.a11y` (`FocusTrap` / `LiveAnnouncer`); do not assume global `ui.a11y` flags are on.
- [ ] Notifications for transient feedback, dialogs/message boxes for confirmations.
