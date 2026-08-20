# HttpRequest and JSON body

## HttpRequest

Inherits from `ParameterDictionary`: `$request['id']` is filtered, `$request->get('id')` is too.

### Parameters

Prefer `$this->getRequest()` (in controllers) or `Context::getCurrent()->getRequest()` over `$_GET` / `$_POST` / `$_REQUEST` / `$_COOKIE`.

When the source is known, use the specific API — do not merge via `get()` / `$_REQUEST` unless the contract truly accepts either:

| Source | API |
| --- | --- |
| Query string | `getQuery()` / `getQueryList()` |
| Form body | `getPost()` / `getPostList()` |
| Header | `getHeader()` / `getHeaders()` |
| Cookie | `getCookie()` / `getCookieList()` (`getCookieRaw*` only when raw is required) |
| Merged (compatibility) | `get()` — only when source truly does not matter |

```php
$request = Context::getCurrent()->getRequest();

$id    = (int)$request->getQuery('id');
$title = (string)$request->getQuery('title');
$body  = (string)$request->getPost('body');
$file  = $request->getFile('upload');
$token = $request->getHeader('X-Auth-Token');
$cookie = $request->getCookie('BITRIX_SM_GUEST_ID');

$query = $request->getQueryList();
$post  = $request->getPostList();
$files = $request->getFileList();
```

- `$request['x']` returns a value processed by system filters (proactive). This **does not** protect against SQL injections/XSS — escape yourself.
- For typed input, a Request DTO wired with `ValidationParameter` in `getAutoWiredParameters()` is preferred (see `bitrix-validation`). It is an AutoWire rule, not a parameter attribute.

### JSON body

| Need | API |
| --- | --- |
| Controller action JSON contract | `JsonPayload` autowire, or `JsonController` / `ContentType` filter |
| Decoded list/array from body | `isJson()` + `getJsonList()` |
| Tolerant decode (invalid/empty OK) | `decodeJson()` |
| Fail-fast valid `application/json` | `decodeJsonStrict()` |
| Raw body (rare) | `getInput()` |

Do not `json_decode(file_get_contents('php://input'))` in every action when framework APIs cover the case.

### About the Request

```php
$request->getRequestMethod();       // GET|POST|PUT|DELETE
$request->isGet();
$request->isPost();
$request->isPut();
$request->isDelete();
$request->isAjaxRequest();          // X-Requested-With: XMLHttpRequest header
$request->isHttps();
$request->isAdminSection();         // /bitrix/admin/*
$request->getRequestUri();          // '/news/?id=1'
$request->getRequestedPage();       // '/news/index.php'
$request->getRequestedPageDirectory();
$request->getScriptFile();
$request->getUserAgent();
$request->getAcceptedLanguages();
```

### Server

```php
$server = Context::getCurrent()->getServer();
$server->get('REMOTE_ADDR');
$server->getHttpHost();
$server->getDocumentRoot();
```

## ParameterDictionary

`HttpRequest::getQueryList()`, `getPostList()`, `getFileList()` return this object.

```php
$params = $request->getPostList();

$params->get('id');             // value
$params->getRaw('id');          // value before filters
$params->getValues();           // array
$params->isEmpty();             // bool
$params->offsetExists('id');    // ArrayAccess
```
