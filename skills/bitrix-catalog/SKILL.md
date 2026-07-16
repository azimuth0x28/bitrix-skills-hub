---
name: bitrix-catalog
description: Covers Trade Catalog module — products, SKU/offers, prices, inventory, discounts, bundles, export/import, catalog API choice. Applied for e-commerce features requiring prices, stock, and sale integration. Key terms — catalog, product, SKU, offer, price type, CCatalogProduct, catalog module.
---

# Trade Catalog Module

Baseline: **main 23.0+**. Features newer than baseline are marked **Since**.

Catalog attaches commerce data to iblock elements. Requires `iblock` + `catalog`. Cart/orders live in `sale` — see skill `bitrix-sale`.

```php
\Bitrix\Main\Loader::includeModule('iblock');
\Bitrix\Main\Loader::includeModule('catalog');
```

Product ID = iblock element ID. Trade row: `b_catalog_product` (`ProductTable`). Prices: `b_catalog_price` (`PriceTable`). Catalog↔iblock link: `b_catalog_iblock` (`CatalogIblockTable` / `CCatalog`).

## Linking an Iblock to Catalog

Register the product iblock as a catalog:

```php
\CCatalog::Add([
    'IBLOCK_ID' => $productIblockId,
    'YANDEX_EXPORT' => 'N',
    'SUBSCRIPTION' => 'N',
]);
```

Read binding via ORM:

```php
$row = \Bitrix\Catalog\CatalogIblockTable::getByPrimary($productIblockId)->fetch();
// IBLOCK_ID, PRODUCT_IBLOCK_ID, SKU_PROPERTY_ID, VAT_ID, …
```

Iblock catalog kinds (`CCatalogSku`, `catalog/general/catalog_sku.php`):

| Constant | Meaning |
| --- | --- |
| `TYPE_CATALOG` (`D`) | Simple catalog (no SKU) |
| `TYPE_PRODUCT` (`P`) | Product iblock with separate offers iblock |
| `TYPE_OFFERS` (`O`) | Offers (SKU) iblock |
| `TYPE_FULL` (`X`) | Product iblock that itself holds simple products + SKUs |

```php
$info = \CCatalogSku::GetInfoByIBlock($iblockId);
// CATALOG_TYPE, PRODUCT_IBLOCK_ID, SKU_PROPERTY_ID, …
```

## Product Types (`ProductTable`)

Verified in `catalog/lib/product.php`:

| Constant | Value | Meaning |
| --- | --- | --- |
| `TYPE_PRODUCT` | 1 | Simple product |
| `TYPE_SET` | 2 | Set / bundle |
| `TYPE_SKU` | 3 | Parent with offers |
| `TYPE_OFFER` | 4 | Offer (SKU variant) |
| `TYPE_FREE_OFFER` | 5 | Offer without parent link |
| `TYPE_EMPTY_SKU` | 6 | SKU parent without offers |
| `TYPE_SERVICE` | 7 | Service (no warehouse tracking) |

```php
use Bitrix\Catalog\ProductTable;

$product = ProductTable::getByPrimary($elementId, [
    'select' => ['ID', 'TYPE', 'QUANTITY', 'AVAILABLE', 'VAT_ID', 'VAT_INCLUDED'],
])->fetch();

ProductTable::update($elementId, [
    'QUANTITY' => 10,
    'QUANTITY_TRACE' => ProductTable::STATUS_YES,
    'CAN_BUY_ZERO' => ProductTable::STATUS_NO,
]);
```

Prefer `\Bitrix\Catalog\Model\Product` for add/update when you need catalog automation (availability, parent SKU type, subscriptions). Legacy: `CCatalogProduct`.

## SKU / Offers Pattern

1. Product iblock (parents) + offers iblock (variants).
2. In the **offers** iblock: property `PROPERTY_TYPE = E`, `LINK_IBLOCK_ID = product iblock` (SKU link). Prefer `USER_TYPE = SKU` (`PropertyTable::USER_TYPE_SKU`).
3. Register offers iblock as catalog linked to the product iblock:

```php
\CCatalog::Add([
    'IBLOCK_ID' => $offersIblockId,
    'PRODUCT_IBLOCK_ID' => $productIblockId,
    'SKU_PROPERTY_ID' => $skuPropertyId, // E-property on offers iblock
]);
```

Parent elements get `TYPE_SKU`; offer elements get `TYPE_OFFER`. Customer buys a specific offer (or a simple `TYPE_PRODUCT` when no SKU).

## Prices and Price Types

- Price type (catalog group): `b_catalog_group` → `Bitrix\Catalog\GroupTable` (`BASE`, `NAME`, …). Access: `GroupAccessTable` / legacy `CCatalogGroup`.
- Price row: `Bitrix\Catalog\PriceTable` — `PRODUCT_ID`, `CATALOG_GROUP_ID`, `PRICE`, `CURRENCY`, optional `QUANTITY_FROM` / `QUANTITY_TO`.

```php
use Bitrix\Catalog\PriceTable;
use Bitrix\Catalog\GroupTable;

$base = GroupTable::getRow(['filter' => ['=BASE' => 'Y']]);

PriceTable::add([
    'PRODUCT_ID' => $elementId,
    'CATALOG_GROUP_ID' => (int)$base['ID'],
    'PRICE' => 1990.00,
    'CURRENCY' => 'RUB',
]);

$prices = PriceTable::getList([
    'filter' => ['=PRODUCT_ID' => $elementId],
    'select' => ['ID', 'PRICE', 'CURRENCY', 'CATALOG_GROUP_ID'],
])->fetchAll();
```

Legacy write helpers: `CPrice`. VAT fields live on the product (`VAT_ID`, `VAT_INCLUDED`).

## Stock and Stores (Overview)

- Product-level qty: `ProductTable` fields `QUANTITY`, `QUANTITY_RESERVED`, `QUANTITY_TRACE`, `CAN_BUY_ZERO`, `AVAILABLE`.
- Multi-store: `StoreTable` (`b_catalog_store`) + `StoreProductTable` (`b_catalog_store_product`: `STORE_ID`, `PRODUCT_ID`, `AMOUNT`, `QUANTITY_RESERVED`).
- Documents / batches: `StoreDocumentTable`, `StoreBatchTable`, … — use for warehouse ops, not ad-hoc SQL.

```php
use Bitrix\Catalog\StoreProductTable;

$amounts = StoreProductTable::getList([
    'filter' => ['=PRODUCT_ID' => $elementId],
    'select' => ['STORE_ID', 'AMOUNT', 'QUANTITY_RESERVED'],
])->fetchAll();
```

`TYPE_SERVICE` products are not warehouse-tracked like ordinary goods.

## Boundary with `sale`

| Concern | Module |
| --- | --- |
| Product card, type, qty, prices, stores | `catalog` |
| Basket, order, payment, delivery, shipments | `sale` |

Basket lines reference catalog product/offer IDs; price resolution and discounts may involve both modules. Do not invent cart APIs inside `catalog` — use skill `bitrix-sale`.

## API Choice

| Use | Prefer |
| --- | --- |
| Read product/price/store rows | `ProductTable`, `PriceTable`, `StoreProductTable`, `CatalogIblockTable` |
| Write with catalog side effects | `\Bitrix\Catalog\Model\Product`, `CCatalog::Add/Update` |
| Legacy admin / compatibility | `CCatalogProduct`, `CPrice`, `CCatalogSku` |

Inspect `bitrix/modules/catalog/lib/` before adopting newer `v2` / REST helpers — confirm against the project kernel.

## Performance

- Batch price/stock updates; avoid per-item `CCatalogProduct::GetByID` in loops/templates.
- Cache list queries; warm after bulk import.
- Load with ORM collections / joins, not N+1.

## Checklist

- [ ] `iblock` + `catalog` included.
- [ ] Product iblock linked via `CCatalog::Add` / `CatalogIblockTable`.
- [ ] SKU: offers iblock + `PRODUCT_IBLOCK_ID` + `SKU_PROPERTY_ID`.
- [ ] Types use `ProductTable::TYPE_*`.
- [ ] Prices via `PriceTable` / price types (`GroupTable`).
- [ ] Stock via catalog API / `StoreProductTable`, not raw SQL.
- [ ] Cart/orders delegated to `sale` (`bitrix-sale`).
