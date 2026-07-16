# Application and Context

## Application

A singleton per hit, configures the kernel, provides access to general services.

```php
use Bitrix\Main\Application;

$app = Application::getInstance();

$app->getContext();           // current context
$app->getManagedCache();      // managed cache
$app->getTaggedCache();       // tagged cache
$app->getSession();           // session object (see bitrix-sessions)
$app->getConnection();        // primary DB connection
$app->getConnection('log');   // connection by name from connections
$app->getKernelSession();     // kernel session
$app->addBackgroundJob(fn () => /* ... */);     // see bitrix-background-jobs
```

Descendants: `HttpApplication` (HTTP hit), `CliApplication` (CLI hit — `bitrix.php`).

## Context

An "envelope" for a single request: `Request`, `Response`, `Server`, language, `Culture`, site.

```php
use Bitrix\Main\Context;

$ctx = Context::getCurrent();

$ctx->getRequest();    // HttpRequest
$ctx->getResponse();   // HttpResponse
$ctx->getServer();     // Server (wrapper over $_SERVER)
$ctx->getCulture();    // regional formats
$ctx->getLanguage();   // 'ru'
$ctx->getSite();       // 's1'
$ctx->getEnvironment();
```

`Context::getCurrent()` is a shorter alias for `Application::getInstance()->getContext()`.
