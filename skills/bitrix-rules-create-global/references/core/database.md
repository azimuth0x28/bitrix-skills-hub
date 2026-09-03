# Database Standards

<context>
  <system_context>
    Rules for working with the database in a 1C-Bitrix (on-premise) project:
    D7 ORM for new entities, direct-SQL exceptions, table naming conventions,
    and cross-DBMS compatibility (the project runs on both MySQL/MariaDB and PostgreSQL).
  </system_context>

  <domain_context>
    PHP · D7 ORM (`\Bitrix\Main\ORM\*`) · `DataManager` entity classes ·
    `\Bitrix\Main\Application::getConnection()` · legacy `CIBlockElement::GetList` ·
    MySQL/MariaDB and PostgreSQL · migrations.
  </domain_context>
</context>

<critical_rules enforcement="strict">
  <rule id="d7-orm-new-entities" scope="new-entities">
    MUST implement all new entities through D7 ORM: classes extending
    `\Bitrix\Main\ORM\Data\DataManager`
  </rule>

  <rule id="direct-sql-via-connection" scope="sql">
    MUST execute direct SQL only through `\Bitrix\Main\Application::getConnection()`
  </rule>

  <rule id="parameterized-queries" scope="sql">
    MUST use parameterized queries to protect against SQL injection
  </rule>

  <rule id="db-table-prefix" scope="tables">
    MUST prefix custom tables from the vendor name (e.g. `Acme` → `acme`),
    confirmed at AGENTS.md initialization —  no more than 5 characters recommended;
    format `{{db_prefix}}_table_name`
  </rule>

  <rule id="cross-dbms-awareness" scope="all">
    MUST account for the target database engine (MySQL/MariaDB vs PostgreSQL)
    when writing queries, designing ORM tables, and any other DB operations
  </rule>
</critical_rules>

## ORM (D7)

- Place entity classes in `/local/modules/<vendor>.<module>/lib/Model/*Table.php`,`/local/php_interface/lib/Model/*Table.php`
- Use type-safe queries via `\Bitrix\Main\ORM\Query\Query`
- Describe entity properties via `\Bitrix\Main\ORM\Fields` (including `Reference` for relations)

## Exceptions from ORM

- Comment on each direct query why D7 ORM was not suitable
- Do not touch legacy code on `CIBlockElement::GetList` without need; for new code — D7 only

## Table Naming

- Use `snake_case` for table and column names
- Add indexes on frequently queried columns

## Cross-DBMS Compatibility (MySQL / PostgreSQL)

- The project may run on both MySQL (MariaDB) and PostgreSQL: account for the features and capabilities of the specific DB engine when composing queries, designing ORM tables, and other operations
- Do not rely on dialect-specific SQL without need: prefer constructs that work on both engines (type-safe queries via D7 ORM, standard syntax for direct SQL)
- Verify critical direct queries on both DB engines when the environment allows
