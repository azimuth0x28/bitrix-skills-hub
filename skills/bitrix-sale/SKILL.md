---
name: bitrix-sale
description: Covers Sale module — FUSER, Basket, Order create overview, statuses, payment and delivery entry points, boundary with catalog. Applied for cart/checkout, order lifecycle, and pay/ship integration without building full admin UI. Key terms — sale, Basket, Order, Fuser, Payment, Shipment, PaySystem\Manager, Delivery\Services\Manager, STATUS_ID, catalog provider.
---

# Online Store (`sale`)

`sale` owns cart (basket), orders, payments, shipments, and related restrictions. Product master data and prices live in **`catalog` + `iblock`**. Baseline: main **23.0+**; use D7 entities below (not legacy `CSaleOrder` for new code).

```php
\Bitrix\Main\Loader::includeModule('sale');
\Bitrix\Main\Loader::includeModule('catalog'); // when adding catalog products
```

## Boundary with Catalog

| Concern | Module / API |
| --- | --- |
| Product, SKU, price, stock | `catalog` / `iblock` (`bitrix-catalog`, `bitrix-iblocks`) |
| Cart lines, order, pay, deliver | `sale` |
| Filling basket price/qty from catalog | `PRODUCT_PROVIDER_CLASS` → `\Bitrix\Catalog\Product\CatalogProvider` (`\Bitrix\Catalog\Product\Basket::getDefaultProviderName()`) |

Basket item `MODULE` is typically `'catalog'`; `PRODUCT_ID` is the catalog product (iblock element / offer) ID.

## FUSER (Cart Owner)

Anonymous and authorized carts are keyed by **FUSER** (`Bitrix\Sale\Fuser`), not only by `USER_ID`.

```php
<?php declare(strict_types=1);

use Bitrix\Sale\Fuser;

$fuserId = Fuser::getId();              // create if missing (unless skip)
$fuserId = Fuser::getId(skipCreate: true);
$userFuser = Fuser::getIdByUserId($userId); // false if cannot resolve/create
$userId = Fuser::getUserIdById($fuserId);
```

Session/cookie keys are internal (`SALE_USER_ID` / `SALE_UID`). Prefer `Fuser::*` over touching cookies directly.

## Basket

```php
<?php declare(strict_types=1);

use Bitrix\Catalog\Product\Basket as CatalogBasket;
use Bitrix\Main\Context;
use Bitrix\Sale\Basket;
use Bitrix\Sale\Fuser;

$siteId = Context::getCurrent()->getSite();
$basket = Basket::loadItemsForFUser(Fuser::getId(), $siteId);

$item = $basket->createItem('catalog', $productId);
$item->setFields([
    'QUANTITY' => 1,
    'CURRENCY' => 'USD',
    'LID' => $siteId,
    'PRODUCT_PROVIDER_CLASS' => CatalogBasket::getDefaultProviderName(),
]);

$result = $basket->save();
```

- `Basket` extends `BasketBase`; list ORM: `Bitrix\Sale\Internals\BasketTable` via `Basket::getList()`.
- Refresh prices/qty/coupons: `$basket->refreshData(['PRICE', 'QUANTITY', 'COUPONS'])` (also used inside `Order::setBasket`).

## Order Create (Overview)

```php
<?php declare(strict_types=1);

use Bitrix\Main\Context;
use Bitrix\Sale\Basket;
use Bitrix\Sale\Fuser;
use Bitrix\Sale\Order;
use Bitrix\Sale\PaySystem\Manager as PaySystemManager;
use Bitrix\Sale\Delivery\Services\Manager as DeliveryManager;

$siteId = Context::getCurrent()->getSite();
$basket = Basket::loadItemsForFUser(Fuser::getId(), $siteId);

$order = Order::create($siteId, $userId); // currency from site/base if null
$order->setPersonTypeId($personTypeId);

$setBasketResult = $order->setBasket($basket);
if (!$setBasketResult->isSuccess()) {
    // errors
}

// Payment
$paySystem = PaySystemManager::getObjectById($paySystemId);
$payment = $order->getPaymentCollection()->createItem($paySystem);
$payment->setField('SUM', $order->getPrice());
$payment->setField('CURRENCY', $order->getCurrency());

// Delivery (shipment)
$delivery = DeliveryManager::getObjectById($deliveryId);
$shipment = $order->getShipmentCollection()->createItem($delivery);
// bind basket items to shipment as needed for your flow

$order->doFinalAction(true);
$saveResult = $order->save();
```

Load existing: `Order::load($id)`. Persist always checks `$result->isSuccess()` / `getErrors()`.

Exact shipment item wiring and property collection setup vary by project (person type, location, required props) — keep that in a service, not a fat controller.

## Status

- Field: `STATUS_ID` on the order (`setField('STATUS_ID', $id)`).
- New orders get `Order::create` → `getInitialStatus()` (via `StatusBase`).
- Dictionary: `Bitrix\Sale\Internals\StatusTable` (+ `StatusLangTable` for names).
- Permissions / allow-pay rules depend on status configuration — do not hardcode magic statuses without checking site config.

## Payment and Delivery Entry Points

**Pay systems** — `Bitrix\Sale\PaySystem\Manager`:

- `getList()`, `getObjectById($id)`, `getListWithRestrictions(Payment $payment)`, `getListWithRestrictionsByOrder(Order $order)`.
- Handlers under `/local/php_interface/include/sale_payment/` (and module handlers). Legacy `/bitrix/modules/sale/payment/` is deprecated (unsupported since sale **22.200.0**).

**Delivery** — `Bitrix\Sale\Delivery\Services\Manager`:

- `getById($deliveryId)`, `getList()`, object resolution for `ShipmentCollection::createItem()`.
- Restrictions via delivery restriction framework (same idea as pay system restrictions).

Collections on order: `getPaymentCollection()`, `getShipmentCollection()`. Entities: `Bitrix\Sale\Payment`, `Bitrix\Sale\Shipment`.

This skill covers **API entry points**, not full checkout UI or every handler protocol.

## Module REST / Controllers

`sale` `.settings.php` enables `controllers.restIntegration.enabled`. Prefer thin Engine controllers + services for custom storefront APIs; reuse sale entities inside services (`bitrix-controllers`, `bitrix-rest`).

## Checklist

- [ ] `sale` (+ `catalog` when needed) included.
- [ ] Cart keyed by `Fuser::getId()` / `loadItemsForFUser`.
- [ ] Catalog lines use module `catalog` + `CatalogProvider` provider class.
- [ ] Order built via `Order::create` → `setBasket` → pay/ship collections → `doFinalAction` → `save`.
- [ ] All `Result` objects checked; no silent failure.
- [ ] Statuses taken from configured `STATUS_ID` values, not invented codes.
- [ ] Business logic in services; components/controllers stay thin.

## Related skills

`bitrix-catalog`, `bitrix-iblocks`, `bitrix-result-and-errors`, `bitrix-controllers`, `bitrix-service-locator`.
