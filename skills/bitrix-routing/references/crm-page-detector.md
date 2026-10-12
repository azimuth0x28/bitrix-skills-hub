# CRM page detector

Detects whether a CRM entity detail card is open — both path candidates (before and after urlrewrite) and both CRM roots (standard `/crm/`, custom `/page/`) are checked.

```php
<?php

declare(strict_types=1);

namespace Acme\Disableclientquickcreate\Integration\Crm;

use Bitrix\Crm\Service\Container;
use Bitrix\Main\HttpRequest;
use Bitrix\Main\Web\Uri;

/**
 * Detects whether a CRM entity detail card is open.
 *
 * CRM card URLs differ: standard pages live under /crm/ (entities, smart processes
 * type/{id}, the universal card item/{id}), custom sections live under the physical
 * root /page/ (Router::getCustomRoots). Both path candidates (before and after
 * urlrewrite) and both roots are therefore checked.
 */
final class PageDetector
{
	/** Detail-page mask for the standard CRM section. */
	private const URL_PATTERN_DETAIL = '~^/crm/(?:type/\d+|deal|lead|company|contact|invoice|quote|item/\d+)/details(?:/|$)~';

	/** Detail-page tail for a custom section, appended after preg_quote($customRoot). */
	private const URL_PATTERN_CUSTOM_ROOT_DETAIL = '(?:type/\d+/)?details(?:/|$)';

	/** Physical root of custom sections. */
	private const CUSTOM_SECTIONS_ROOT = '/page/';

	/** The page is a CRM entity detail card of any type. */
	public static function isCrmDetailPage(HttpRequest $request): bool
	{
		$paths = self::candidatePaths($request);

		if (self::matchPaths($paths, self::URL_PATTERN_DETAIL))
		{
			return true;
		}

		return self::matchCustomRoots($paths, self::URL_PATTERN_CUSTOM_ROOT_DETAIL);
	}

	/**
	 * Possible request paths: before (getRequestedPage) and after (getRequestUri) urlrewrite.
	 *
	 * @return string[]
	 */
	private static function candidatePaths(HttpRequest $request): array
	{
		$paths = [(string)$request->getRequestedPage()];

		$rawUri = trim((string)$request->getRequestUri());
		if ($rawUri !== '')
		{
			$paths[] = (new Uri($rawUri))->getPath();
		}

		return array_values(array_unique(array_filter($paths)));
	}

	/**
	 * @param string[] $paths
	 */
	private static function matchPaths(array $paths, string $pattern): bool
	{
		foreach ($paths as $path)
		{
			if (preg_match($pattern, $path) === 1)
			{
				return true;
			}
		}

		return false;
	}

	/**
	 * Detail page inside a custom section (/page/...).
	 *
	 * @param string[] $paths
	 */
	private static function matchCustomRoots(array $paths, string $suffixPattern): bool
	{
		if (self::matchPaths($paths, '#^' . self::CUSTOM_SECTIONS_ROOT . '#') === false)
		{
			return false;
		}

		$customRoots = Container::getInstance()->getRouter()->getCustomRoots();

		foreach ($customRoots as $customRoot)
		{
			$customRoot = trim((string)$customRoot);
			if ($customRoot === '')
			{
				continue;
			}

			$pattern = '~^' . preg_quote($customRoot, '~') . $suffixPattern . '~';

			if (self::matchPaths($paths, $pattern))
			{
				return true;
			}
		}

		return false;
	}
}
```
