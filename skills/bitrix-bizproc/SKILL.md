---
name: bitrix-bizproc
description: Covers business processes (bizproc) — start/stop workflows from PHP, document types, custom activities in /local/activities/, boundary vs agents/Messenger; mentions bizprocdesigner. Applied for approvals, document workflows, automation activities. Key terms — CBPDocument, CBPRuntime, CBPWorkflow, CBPActivity, document type, Starter, workflow template, activities.
---

# Business Processes (`bizproc`)

Baseline: **main 23.0+**. Verified against kernel module `bizproc` in this repo.

```php
\Bitrix\Main\Loader::includeModule('bizproc');
```

Visual template designer UI lives in module **`bizprocdesigner`** (optional; feature flag `BizProc`). Runtime execution, documents, and activities are in **`bizproc`**.

## Core Runtime Classes

| Class | Role |
| --- | --- |
| `\CBPDocument` | Start / terminate / kill workflows; templates for start; permissions |
| `\CBPRuntime` | Runtime singleton; `createWorkflow`, `getWorkflow`, feature checks |
| `\CBPWorkflow` | Running instance |
| `\CBPActivity` | Base class for all activities (`execute()`, properties) |
| `\CBPWorkflowTemplateLoader` | Template search/load |
| `\CBPDocumentService` | Document provider bridge (module entity callbacks) |
| `\CBPDocumentEventType` | Create / Edit / Manual / Automation / … |

Document identity is always a **complex id** array: `[MODULE_ID, ENTITY, DOCUMENT_ID]` (or type: `[MODULE_ID, ENTITY, DOCUMENT_TYPE]`).

Providers (CRM, lists, disk, …) register document services. Resolve helpers: `\CBPHelper::ParseDocumentId()`, `normalizeComplexDocumentId()`. Copy real `[module, entity, id|type]` triples from the owning module or an existing template — do not invent them.

## Start / Stop from PHP

```php
\Bitrix\Main\Loader::includeModule('bizproc');

$documentId = ['crm', 'CCrmDocumentDeal', $dealId]; // shape is provider-specific
$errors = [];

$workflowId = \CBPDocument::startWorkflow(
    $templateId,
    $documentId,
    [
        \CBPDocument::PARAM_TAGRET_USER => 'user_' . $userId, // spelling as in kernel
        \CBPDocument::PARAM_DOCUMENT_EVENT_TYPE => \CBPDocumentEventType::Manual,
    ],
    $errors,
);

\CBPDocument::autoStartWorkflows(
    $documentType, // [module, entity, type]
    \CBPDocumentEventType::Create, // or Edit
    $documentId,
    $parameters,
    $errors,
);

\CBPDocument::terminateWorkflow($workflowId, $documentId, $errors, $stateTitle = '');
\CBPDocument::killWorkflow($workflowId, terminate: true, documentId: $documentId);
\CBPDocument::sendExternalEvent($workflowId, $eventName, $parameters, $errors);

$can = \CBPDocument::canUserOperateDocument(
    \CBPCanUserOperateOperation::StartWorkflow,
    $userId,
    $documentId,
);
```

Also: `getTemplatesForStart`, `getDocumentStates`, `getDocumentState`.

Modern API: `\Bitrix\Bizproc\Starter\Starter::getByScenario(Scenario::onManual)` → `setDocument` / `setTemplateIds` / `start()` → `StartResult`. Facade: `\Bitrix\Bizproc\Public\Service\Workflow\StarterService`. AJAX: `\Bitrix\Bizproc\Controller\Workflow\Starter`.

## Document Types Overview

A **document type** selects the provider that implements fields/rights via `CBPDocumentService` (`GetDocumentFields`, `GetDocument`, …). Starting a workflow needs: template id, matching complex document id, and parameters (`CBPDocument::PARAM_*` + template vars).

## Custom Activities (`/local/activities/`)

Activity search order (`\Bitrix\Bizproc\Runtime\ActivitySearcher\Searcher`):

1. `/local/activities`
2. `/local/activities/custom`
3. `/bitrix/activities/custom`
4. `/bitrix/activities/bitrix`
5. `/bitrix/modules/bizproc/activities`

Minimal activity folder:

```
/local/activities/myvendorapprove/
├── .description.php      # ActivityDescription → $arActivityDescription
├── myvendorapprove.php   # class CBPMyVendorApprove extends CBPActivity
├── properties_dialog.php # optional designer form
└── lang/ru/*.php
```

Kernel sample pattern (`DelayActivity`):

```php
// myvendorapprove.php
class CBPMyVendorApprove extends CBPActivity
{
    public function __construct($name)
    {
        parent::__construct($name);
        $this->arProperties = [
            'Title' => '',
            'Comment' => '',
        ];
    }

    public function execute()
    {
        // business work; use $this->GetDocumentId(), workflow services
        return CBPActivityExecutionStatus::Closed;
    }
}
```

`.description.php` should build `\Bitrix\Bizproc\Activity\ActivityDescription` (see `install/activities/bitrix/delayactivity/.description.php`) with `setClass`, type (`ActivityType::ACTIVITY`), category/groups.

Rules:

- Class name convention: `CBP` + activity directory name (PascalCase), matching `setClass`.
- No long blocking I/O inside `execute()` without scheduling — use delay/event activities or external jobs.
- Register nothing in `.settings.php` for filesystem activities — discovery is by folder scan.

## Boundary vs Agents / Messenger

See skill `bitrix-background-jobs`.

| Mechanism | Use when |
| --- | --- |
| **Bizproc** | Human tasks, approvals, document-state machine, branching by fields |
| **`CAgent`** | Periodic maintenance without document UI |
| **`addBackgroundJob`** | Short post-response work in same hit |
| **Messenger** | Reliable async jobs, retries, consumers (`messenger:consume`) |

Bizproc **can** schedule delays (`CBPDelayActivity`, scheduler service) and may enqueue start via Messenger receivers (e.g. `WorkflowStartReceiver`) — that is internal runtime support, not a reason to replace BP with a queue for approvals.

Do **not** reimplement approval chains as agents. Do **not** run heavy CRM sync inside an activity `execute()` — start a Messenger message / agent and let the activity wait on an external event if needed (`sendExternalEvent`).

## Designer Module

- **`bizprocdesigner`**: template designer UI; requires BP feature enabled (`include.php` checks `CBXFeatures::IsFeatureEnabled('BizProc')`).
- Template editing is admin/UI; runtime code should not depend on designer classes.

## Checklist

- [ ] `Loader::includeModule('bizproc')` (and owning document module: `crm`, `lists`, …).
- [ ] Complex document id matches template document type.
- [ ] Handle `$errors` from `startWorkflow` / `terminateWorkflow` — do not ignore.
- [ ] Check `canUserOperateDocument` / type rights before manual start.
- [ ] Custom activities under `/local/activities/…` with `.description.php` + `CBP*` class.
- [ ] Approvals → bizproc; cron sync → agents/Messenger (`bitrix-background-jobs`).
- [ ] Prefer `Result`/`StartResult` patterns at module boundary when wrapping starters in services.
