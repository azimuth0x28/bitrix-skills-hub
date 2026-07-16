# SQL injection and SSRF

## SSRF

- Do not access URLs from user input directly: `file_get_contents($url)`, `curl` with user hosts.
- Use `Bitrix\Main\Web\HttpClient` with timeouts and **`privateIp => false`** for user-controlled URLs:

    ```php
    $client = new \Bitrix\Main\Web\HttpClient([
        'socketTimeout' => 5,
        'streamTimeout' => 10,
        'redirect' => false,
        'disableSslVerification' => false,
        // Default privateIp is TRUE (private IPs allowed). For SSRF protection:
        'privateIp' => false,
    ]);
    ```

- `privateIp` default **`true`** = private/link-local IPs **allowed**. Set `false` to block `127.0.0.1`, `169.254.*`, `10.*`, `192.168.*`, etc.
- Also whitelist schemes/hosts where possible; for user-provided webhooks — validate host/scheme/port, sign requests with a secret.

## SQL Injections

### Raw SQL (Old Kernel)

```php
$conn = \Bitrix\Main\Application::getConnection();
$helper = $conn->getSqlHelper();

$id = (int)$userInput; // for integers — forced casting
$login = $helper->forSql($userLogin); // string escaping

$conn->queryExecute("UPDATE b_user SET LOGIN = '{$login}' WHERE ID = {$id}");
```

For bulk inserts/updates:

```php
[$insertFields, $insertValues] = $helper->prepareInsert('b_user', $fields);
$conn->queryExecute("INSERT INTO b_user ({$insertFields}) VALUES ({$insertValues})");

$update = $helper->prepareUpdate('b_user', $fields);
$conn->queryExecute("UPDATE b_user SET {$update[0]} WHERE ID = {$id}", $update[1]);
```

### ORM Queries — Can Also Be Vulnerable

Dangerous spots in `getList`/`query()`:

- `select` and `order` — field names **are not escaped**. Never put a "field name from request" there without a whitelist:

    ```php
    $allowedOrder = ['ID', 'CREATED_AT', 'TITLE'];
    $order = in_array(strtoupper($userOrder), $allowedOrder, true) ? strtoupper($userOrder) : 'ID';

    PostTable::getList(['order' => [$order => 'DESC']]);
    ```

- `filter` — values are parameterized, but **keys** (field names with `=`, `>`, etc. prefixes) — are not. Also whitelist.
- `SqlExpression` and `ExpressionField` — the second argument is substituted as is. Never build it from user input:

    ```php
    // DANGEROUS:
    new \Bitrix\Main\DB\SqlExpression("IF({$userField} = 1, 'a', 'b')");

    // SAFE:
    new \Bitrix\Main\DB\SqlExpression('IF(?# = 1, "a", "b")', $userField);
    ```

- `runtime` fields — same rules.
