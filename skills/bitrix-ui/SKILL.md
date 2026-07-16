---
name: bitrix-ui
description: Covers Bitrix UI library — main.popup, main.sidepanel, ui.system.dialog, ui.dialogs.messagebox, ui.system.menu, ui.system.input, ui.alerts, notification-manager, icons, typography. Applied when building admin interfaces and public UI with kernel components. Key terms — Extension::load, Popup, SidePanel, system-dialog, MessageBox, ui.alerts, UI kit.
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
| Toast notifications | `ui.notification-manager` |
| Alerts/banners (inline UI alerts) | `ui.alerts` |
| Form inputs (modern) | `ui.system.input`, `ui.system.label`, `ui.system.chip` |
| Icons | `ui.icon-set` / `ui.icons` |
| Loading skeleton | `ui.system.skeleton` |
| Hints/tooltips | `ui.hint` |
| Animations | `ui.lottie` |

### `ui.system.dialog` vs `ui.dialogs.messagebox`

- **`ui.system.dialog`** — modern system `Dialog` component (structured dialog UI for new admin screens).
- **`ui.dialogs.messagebox`** — classic `MessageBox` helpers (`confirm`, `alert`, `show`) for quick confirmations and alerts. Not a replacement for `ui.system.dialog`; use MessageBox for simple prompts, Dialog for richer UI.

There is **no** extension `ui.system.alert` — use **`ui.alerts`**.

## Loading Pattern

PHP:

```php
\Bitrix\Main\UI\Extension::load(['ui.system.dialog', 'ui.alerts', 'ui.notification-manager']);
```

JS (in extension):

```javascript
import { Dialog } from 'ui.system.dialog';
import { MessageBox } from 'ui.dialogs.messagebox';
import { Alert, AlertColor } from 'ui.alerts';
import { Notification } from 'ui.notification-manager';
```

## System Dialog (preferred for new UI)

```javascript
import { Dialog } from 'ui.system.dialog';

const dialog = new Dialog({
    title: 'Settings',
    content: 'Dialog body',
    // buttons / events per Dialog API
});
dialog.show();
```

## Message Box (simple confirm/alert)

```javascript
import { MessageBox } from 'ui.dialogs.messagebox';

MessageBox.confirm('Delete item?', () => {
    // on confirm
});

MessageBox.alert('Done');
MessageBox.show({
    message: 'Confirm action?',
    buttons: MessageBox.createButtons(MessageBox.BTN_OK, MessageBox.BTN_CANCEL),
    onOk: () => { /* ... */ },
});
```

## Alerts

```javascript
import { Alert, AlertColor, AlertSize } from 'ui.alerts';

const alert = new Alert({
    text: 'Saved successfully',
    color: AlertColor.SUCCESS,
    size: AlertSize.MD,
});
// render into a container per Alert API
```

## Popup (legacy/base)

```php
\Bitrix\Main\UI\Extension::load('main.popup');
```

```javascript
import { Popup } from 'main.popup';

const popup = new Popup({
    id: 'my-popup',
    content: 'Saved successfully',
    closeIcon: true,
});
popup.show();
```

## Side Panel

```php
\Bitrix\Main\UI\Extension::load('main.sidepanel');
```

```javascript
BX.SidePanel.Instance.open('/local/admin/custom-page.php', {
    width: 800,
    cacheable: false,
});
```

## Notifications

```javascript
import { Notification } from 'ui.notification-manager';

Notification.Center.notify({
    content: 'Saved',
    autoHideDelay: 3000,
});
```

## Typography and Icons

Load `ui.design-tokens` / typography extensions for consistent admin styling. Icons via `ui.icon-set` — use named icons, not inline SVG copies.

## Checklist

- [ ] Prefer `ui.system.dialog` / `ui.system.*` over legacy `main.popup` for new admin UI; use `ui.dialogs.messagebox` for simple confirms.
- [ ] Alerts via `ui.alerts`, not a non-existent `ui.system.alert`.
- [ ] Extensions loaded in PHP before inline scripts.
- [ ] Modular JS uses `import` from extension names, not global `BX` where avoidable.
- [ ] Side panel URLs are real routes or admin pages with proper auth.
- [ ] Notifications used for transient feedback, dialogs/message boxes for confirmations.
