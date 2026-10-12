# CRM kanban page detector

Detects whether a kanban board is open — standard `/crm/` roots and custom `/page/` section roots, matched against both path candidates (before and after urlrewrite).

```php
<?php

declare(strict_types=1);

use Bitrix\Crm\Service\Container;
use Bitrix\Main\HttpRequest;
use Bitrix\Main\Web\Uri;

/**
 * Detects whether a CRM kanban board is open (standard root or custom section).
 *
 * Kanban URLs differ: standard pages live under /crm/ (entities, smart processes
 * type/{id}, the universal item/{id}), custom sections under the physical root /page/
 * (Router::getCustomRoots). Both path candidates (before and after urlrewrite) and
 * both roots are therefore checked.
 */
function isCrmKanbanPage(HttpRequest $request): bool
{
	// candidates: post-rewrite page + raw SEF path
	$paths = [(string)$request->getRequestedPage()];
	$paths[] = (new Uri((string)$request->getRequestUri()))->getPath();
	$paths = array_values(array_unique(array_filter($paths)));

	// 1) cheap standard patterns, broadened and anchored
	$kanban = '~^/crm/(?:type/\d+|deal|lead|invoice|quote|item/\d+)/kanban(?:/|$)~';
	foreach ($paths as $path)
	{
		if (preg_match($kanban, $path) === 1)
		{
			return true;
		}
	}

	// 2) custom sections: guard the physical root, then Router roots
	$inCustomSection = false;
	foreach ($paths as $path)
	{
		if (preg_match('#^/page/#', $path) === 1)
		{
			$inCustomSection = true;
			break;
		}
	}

	if ($inCustomSection)
	{
		foreach (Container::getInstance()->getRouter()->getCustomRoots() as $root)
		{
			$custom = '~^' . preg_quote((string)$root, '~') . '(?:type/\d+/)?kanban(?:/|$)~';
			foreach ($paths as $path)
			{
				if (preg_match($custom, $path) === 1)
				{
					return true;
				}
			}
		}
	}

	return false;
}
```
