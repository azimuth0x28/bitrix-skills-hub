---
name: bitrix-sale
description: Covers Sale module — API choice (D7 object model vs ORM vs CSale*), FUSER, Basket, Order create/update, properties, statuses and events, payments, delivery/shipments, discounts and coupons, reservation/deduction, permissions, buyer accounts. Applied for cart/checkout, order lifecycle, pay/ship integration, and order automation. Key terms — sale, Basket, Order, Fuser, Payment, Shipment, PaySystem\Manager, Delivery\Services\Manager, doFinalAction, STATUS_ID, DiscountCouponsManager, tryReserve, CanUserUpdateOrder.
---

# Online Store (`sale`)

`sale` owns cart (basket), orders, payments, shipments, discounts, statuses, and history. Product master data, prices, stock live in **`catalog` + `iblock`**. Baseline: main **23.0+**.

```php
\Bitrix\Main\Loader::includeModule('sale');
\Bitrix\Main\Loader::includeModule('catalog'); // products, prices, stock, reservation
```

## Choosing the API

| Task | API |
| --- | --- |
| Create/change basket, order, payment, shipment | Object model `Bitrix\Sale\*` (validates, saves collections, fires events, writes history) |
| Lists, reports, aggregates | ORM `Bitrix\Sale\Internals\*Table` (`OrderTable`, `BasketTable`, `PaymentTable`, `ShipmentTable`) — **read-only for order data** |
| Settings/dictionaries via code | Profile ORM: `PersonTypeTable`, `OrderPropsTable`, `StatusTable` (+`StatusLangTable`), `OrderPropsGroupTable` — writes allowed |
| Pick a configured service | Managers: `PaySystem\Manager`, `Delivery\Services\Manager`, `Cashbox\Manager`/`CheckManager`, `Services\Company\Manager`, `DiscountCouponsManager` |
| Operations with no full D7 replacement | Legacy `CSale*`: `CSaleOrder::CanUser*()` (rights), `CSaleOrderChange` (history read), `CSaleDiscount::Add/Update` (cart rules), `CSaleOrderUserProps` (buyer profiles), `CSaleUserAccount` (account balance), `CSaleOrderTax` (tax rows) |

Never change an order via `OrderTable::update()` or create payments/shipments as raw ORM rows — collections, recalcs, events, and history desync. Never `Order::load()` in a loop for a list — use `OrderTable::getList()` / `Order::getList()`. Don't mix legacy `CSale*` writes with a loaded `Order` object in memory.

## FUSER (Cart Owner)

Anonymous and authorized carts are keyed by **FUSER** (`Bitrix\Sale\Fuser`), not `USER_ID`.

```php
$fuserId = Fuser::getId();               // creates if missing
$fuserId = Fuser::getId(true);           // skip create → null if none
$fuserId = Fuser::getIdByUserId($userId); // false if cannot resolve/create
```

`USER_ID` (site account, required on saved order) and `FUSER_ID` (basket owner) are different — don't substitute one for the other.

## Basket

```php
<?php declare(strict_types=1);

use Bitrix\Catalog\Product\Basket as CatalogBasket;
use Bitrix\Sale\Basket;
use Bitrix\Sale\Basket\RefreshFactory;
use Bitrix\Sale\Fuser;

$basket = Basket::loadItemsForFUser(Fuser::getId(), $siteId); // only rows with ORDER_ID = null

// Preferred for catalog products: sets module, provider, and product data itself
$r = CatalogBasket::addProductToBasket($basket, ['PRODUCT_ID' => $productId, 'QUANTITY' => 1], ['SITE_ID' => $siteId]);
// merges into an existing row by default; pass ['USE_MERGE' => 'N'] as 4th arg for a separate row

// Manual alternative:
$item = $basket->createItem('catalog', $productId);
$item->setFields(['QUANTITY' => 1, 'PRODUCT_PROVIDER_CLASS' => CatalogBasket::getDefaultProviderName()]);
$basket->refresh(RefreshFactory::createSingle($item->getBasketCode())); // provider fills PRICE/CURRENCY/NAME/VAT/weight

$result = $basket->save();                 // only for a basket NOT bound to an order
```

- Don't set `PRICE`/`CURRENCY` for catalog products — the provider does. Own pricing: `CUSTOM_PRICE => 'Y'` + `PRICE` + `CURRENCY`.
- With SKUs put the **offer ID** in `PRODUCT_ID`, never the parent. Verify the element is a product (`Bitrix\Catalog\ProductTable`) before adding.
- Basket of a saved order: get via `$order->getBasket()`, save via `Order::save()` — never `loadItemsForFUser()` / `$basket->save()` for it.
- Before order creation: `$basket->refresh()` (`refreshData()` is deprecated), then `$basket->getOrderableItems()` — separate basket with only purchasable, non-delayed items.
- Item properties: `$item->getPropertyCollection()->createItem()` / `redefine()`. Prices: `getPrice()`, `getBasePrice()`, `getPriceWithVat()`, `getDiscountPrice()`.
- Pre-order discounts preview: `Discount::buildFromBasket($basket, new Discount\Context\Fuser($basket->getFUserId()))` → `calculate()` → `$basket->applyDiscount($data['BASKET_ITEMS'])`. Never for an order-bound basket.

## Order Create (Pipeline)

Order of operations matters: basket → order → person type → basket in → properties → shipment → delivery calc → payment → `doFinalAction(true)` → sync payment SUM → re-check restrictions → `save()`.

```php
<?php declare(strict_types=1);

use Bitrix\Sale\Delivery\Services\Manager as DeliveryManager;
use Bitrix\Sale\Order;
use Bitrix\Sale\PaySystem\Manager as PaySystemManager;
use Bitrix\Sale\Services\Base\RestrictionManager;

$order = Order::create($siteId, $userId); // currency: site's, else base
$order->setPersonTypeId($personTypeId);   // BEFORE getPropertyCollection(); not validated vs site
$order->setBasket($orderableBasket);      // new (unsaved) order only

// Properties (set depends on person type)
$prop = $order->getPropertyCollection()->getItemByOrderPropertyCode('PHONE');
$prop?->setValue($phone);                 // each setValue returns Result

// Shipment: create user shipment, bind basket items, pick allowed delivery
$shipment = $order->getShipmentCollection()->createItem(); // system shipment exists already — never assign it a service
foreach ($order->getBasket() as $basketItem) {
    $shipmentItem = $shipment->getShipmentItemCollection()->createItem($basketItem);
    $shipmentItem->setQuantity($basketItem->getQuantity());
}
$deliveries = DeliveryManager::getRestrictedObjectsList($shipment);
$shipment->setDeliveryService($deliveries[$deliveryId] ?? throw new \RuntimeException('delivery unavailable'));
$order->getShipmentCollection()->calculateDelivery();

// Payment: create, preliminary SUM, pick allowed pay system
$payment = $order->getPaymentCollection()->createItem();
$payment->setField('SUM', $order->getPrice());
$allowed = PaySystemManager::getListWithRestrictions($payment, RestrictionManager::MODE_CLIENT);
isset($allowed[$paySystemId]) or throw new \RuntimeException('pay system unavailable');
$payment->setPaySystemService(PaySystemManager::getObjectById($paySystemId));

$order->doFinalAction(true);              // discounts, taxes, totals — check Result
$payment->setField('SUM', $order->getPrice()); // sync after final calc
// re-check getRestrictedObjectsList / getListWithRestrictions here — totals may change availability

$saveResult = $order->save();             // check isSuccess() AND getWarningMessages()
$orderId = $saveResult->getId();
```

Payment and user shipment are optional at first save (digital goods, deferred flows) — skip those blocks; add later on the loaded order. Idempotency for integrations: store operation key yourself (`XML_ID` is not unique-constrained). Load later: `Order::load($id)`, `Order::loadByAccountNumber($number)`, `Order::loadByFilter([...])`; lock while editing with `Order::lock()/isLocked()/unlock()`.

## Order Update

Work on one loaded object, save once. After a change decide what to rerun:

| Change | calculateDelivery | doFinalAction(true) | sync unpaid payments SUM |
| --- | --- | --- | --- |
| Status, cancel, mark, comment, tracking, allow-delivery | – | – | – |
| Location/address in restrictions | yes | yes | if price changed |
| Basket items/quantity; delivery service/cost; shipment removal | yes | yes | if price changed |
| Coupon/discount/tax data | if delivery affected | yes | if price changed |

- Quantity down: reduce `ShipmentItem::setQuantity()` **first**, then `BasketItem::setField('QUANTITY')`; up: basket first, then shipment. Then `refresh` the item, recalc, save.
- Cancel via `setField('CANCELED', 'Y')` (+ `REASON_CANCELED`); blocked while a paid payment or shipped shipment exists. `Order::delete()` is a service-only hard delete — never use for customer refusal.
- `PERSON_TYPE_ID` change is a migration (property values are not remapped). `CURRENCY`/`USER_ID` are not changeable via `setField()`. Don't write `SUM_PAID`/`PAYED` directly.

## Order Properties

Setting (`OrderPropsTable`, bound to a person type; `ENTITY_TYPE` ORDER/SHIPMENT) vs value in an order (`PropertyValueCollection`). Create settings via `OrderPropsGroupTable::add()` + `OrderPropsTable::add()` in migrations, never during checkout.

- Find values: `getItemByOrderPropertyCode()` (first match), `getItemByOrderPropertyId()`, by role: `getDeliveryLocation()`, groups via `getGroups()`.
- `LOCATION` takes the internal location code, not a name. `ENUM` takes variant `VALUE` (options via `$propertyValue->getPropertyObject()->getOptions()`); `MULTIPLE=Y` takes an array. Files/forms: `PropertyValueCollection::setValuesFromPost($_POST, $_FILES)` + `verify()`.
- Required check before save: iterate collection, `isRequired()` + `checkRequiredValue()`.
- Values save with `Order::save()` only; never write `OrderPropsValueTable` directly.

## Statuses, Permissions

- Order: `STATUS_ID`, initial `N`, final `F`, class `Bitrix\Sale\OrderStatus`. Shipment: own `STATUS_ID`, `DN`→`DF`, class `DeliveryStatus`. Dictionary `StatusTable` (`TYPE_ORDER`/`TYPE_SHIPMENT`) + `StatusLangTable` names.
- Allowed transitions for a user: `OrderStatus::getAllowedUserStatuses($userId, $currentStatusId)`; operations per status: `getStatusesUserCanDoOperations()`, `canGroupDoOperations()` (operations: `view`, `update`, `delete`, `cancel`, `mark`, `payment`, `delivery`, `deduction`, `from`, `to`).
- **Object API does not check rights.** Before acting on a user request check the concrete order via legacy `CSaleOrder`: `CanUserViewOrder()`, `CanUserUpdateOrder()` (pass `0, $groups, $siteId` for create), `CanUserCancelOrder()`, `CanUserChangeOrderStatus()`, `CanUserChangeOrderFlag($id, 'PERM_PAYMENT'|'PERM_DELIVERY'|'PERM_DEDUCTION', $groups)`, `CanUserDeleteOrder()`. Check view rights **before** `Order::load()`.
- Module levels: `D` denied, `P` company binding, `U` order processing (still needs site + status-task grants), `W` full.
- History: written by `OrderHistory` on save; read via legacy `CSaleOrderChange::GetList()` (`@TYPE => ['ORDER_STATUS_CHANGED', ...]`).

## Events

Register via `EventManager` in `init.php`. Key ones: `OnSaleOrderBeforeSaved` (may modify/deny), `OnSaleOrderSaved` (`IS_NEW`, `IS_CHANGED`; result ignored), deferred after save: `OnSaleStatusOrderChange` (`VALUE`/`OLD_VALUE`), `OnSaleOrderPaid`, `OnSaleOrderCanceled`, `OnSaleStatusShipmentChange`, `OnShipmentDeducted`, `OnShipmentAllowDelivery`, `OnShipmentTrackingNumberChange`; per-entity `On[Before]Sale{BasketItem,Payment,Shipment,ShipmentItem,PropertyValue}SetField` and `OnSale*EntitySaved`; basket: `OnSaleBasketItemBeforeSaved/Saved`, `OnSaleBasketItemRefreshData`; final calc: `On{Before,After}SaleOrderFinalAction`.

**Never call `$order->save()` from `OnSaleOrderSaved`** — recursion. Mutate in `OnSaleOrderBeforeSaved` instead, or queue a job that reloads the order. `OnBefore*` handlers returning `EventResult::ERROR` surface as `setField()`/`save()` errors.

## Payments

- Create via `getPaymentCollection()->createItem($service)`; several payments per order = split/partial pay. Available: `PaySystem\Manager::getListWithRestrictions($payment, MODE_CLIENT|MODE_MANAGER)` (or `getListWithRestrictionsByOrder()` pre-payment).
- Run: `$payment->getPaySystem()->initiatePay($payment, $request, BaseServiceHandler::STRING)` → `ServiceResult` (`getTemplate()`, `getPaymentUrl()`, QR). Manual confirm: `$payment->setPaid('Y')`; refund: `$payment->setReturn(Payment::RETURN_PS|RETURN_INNER|RETURN_NONE)`, partial via `Service::refund($payment, $sum)` (handler must implement `IRefund`). Recurring: `IRecurring`, `isRecurring()/repeatRecurrent()`.
- Internal account pay system: `PaySystem\Manager::getInnerPaySystemId()`, `Payment::isInner()`. Balance itself: legacy `CSaleUserAccount::GetByUserID()` / `UpdateAccount($userId, $delta, ...)` — **pass the delta, not the new total**; journal read via `Internals\UserTransactTable`. Buyer aggregates: `Bitrix\Sale\BuyerStatistic` (per user+site+currency).
- Custom handlers: `/local/php_interface/include/sale_payment/<code>/` (`handler.php` extending `PaySystem\ServiceHandler`, `.description.php`, `template/`). Legacy `/bitrix/modules/sale/payment/` unsupported since sale **22.200.0**. Callback entry: `/bitrix/tools/sale_ps_result.php` (verify signature/sum/currency; handle repeated notifications idempotently). Custom restrictions: extend `Services\Base\Restriction`, register on `onSalePaySystemRestrictionsClassNamesBuildList`.

## Delivery and Shipments

- Available services for a shipment: `Delivery\Services\Manager::getRestrictedObjectsList($shipment)` or `getRestrictedList($shipment, Restrictions\Manager::MODE_CLIENT)`. Single service object: `getObjectById()` — never trust a raw request ID without the restricted list.
- Cost: `ShipmentCollection::calculateDelivery()` (all non-system shipments; skips `CUSTOM_PRICE_DELIVERY='Y'`) or `Manager::calculateDeliveryPrice($shipment, $deliveryId, $extraServices)` → `CalculationResult` (price, period).
- The collection always holds a **system shipment** (`isSystem()`) with undistributed quantity — never assign it a service or edit it. Partial/split shipments: distribute quantities; guard with `getBasketItemDistributedQuantity()`.
- State: `allowDelivery()`/`disallowDelivery()`, deduct via `setField('DEDUCTED', 'Y')`, `TRACKING_NUMBER`, `setStoreId()` for pickup. Custom handler: extend `Delivery\Services\Base` (`calculateConcrete()`, `getConfigStructure()`), register on `onSaleDeliveryHandlersClassNamesBuildList`, add via `Manager::add()`; restrictions on `onSaleDeliveryRestrictionsClassNamesBuildList`; extra services in `Delivery\ExtraServices\*` + `Shipment::setExtraServices()`.

## Discounts and Coupons

- Cart rules are created via legacy `CSaleDiscount::Add()/Update()` (`CONDITIONS`/`ACTIONS` trees, `PRIORITY`+`SORT`, `LAST_DISCOUNT`) — no full D7 replacement; delete via `Internals\DiscountTable::delete()`. Never compute discounts by hand or write final prices.
- Calculation: standalone basket → `Discount::buildFromBasket()` + `calculate()` + `applyDiscount()`; saved order → `Order::doFinalAction(true)` (never `buildFromBasket()` on an order basket).
- Coupons: `DiscountCouponsManager::init(MODE_CLIENT|MODE_MANAGER|MODE_ORDER [, userId/orderId])` → `add($code)`. **`add() === true` does not mean the discount applied** — recalc, then `get(true, ['COUPON' => $code], true, true)` and check `STATUS === STATUS_APPLYED`. Coupon rows: `Internals\DiscountCouponTable` (`TYPE_ONE_ORDER`, `TYPE_MULTI_ORDER` + `MAX_USE`).
- Applied result: `$order->getDiscount()->getApplyResult()`; saved orders: `OrderDiscount::loadResultFromDb($orderId)`, rows in `Internals\OrderRulesTable`.

## Reservation and Deduction

- Reserve a shipment: `Shipment::tryReserve()` / `tryUnreserve()`; full-reserve check `isReserved()`. Per-item store rows: `BasketItem::getReserveQuantityCollection()` (`create()` → `setStoreId()` **then** `setQuantity()`). Always finish with `Order::save()` — never edit `RESERVED*` table fields.
- Deduct (write-off) = `Shipment::setField('DEDUCTED', 'Y')`; catalog provider updates stock (`StoreProductTable.AMOUNT/QUANTITY_RESERVED`) on save. Set the store first when inventory management is on.
- Auto-reserve config: `Sale\Configuration::getProductReservationCondition()` → `ReserveCondition::ON_CREATE|ON_PAY|ON_FULL_PAY|ON_ALLOW_DELIVERY|ON_SHIP`; TTL `getProductReserveClearPeriod()`; stale reserves cleaned by `Helpers\ReservedProductCleaner`. Available qty: `Reservation\BasketReservationService::getAvailableCountForBasketItem()/ForOrder()`.

## Reports, Archive, Performance

- Lists/aggregates: ORM with explicit `select`, batch related tables by `ORDER_ID` array (no N+1); order-level flags `PAYED`/`DEDUCTED` avoid loading collections. Mass updates: pick IDs in chunks, then load/change/save each order.
- Archived orders disappear from active tables — read them via `Bitrix\Sale\Archive\Manager::getList()/getById()`; `returnArchivedOrder()` returns a **read-only** object (don't save it as active). Combine active + archive explicitly in reports.
- One `doFinalAction(true)` and one `save()` per logical operation; check `Result::isSuccess()` **and** `getWarningMessages()` (warnings can hide sub-object failures — reload and verify critical state).

## Module REST / Controllers

`sale` enables `controllers.restIntegration`. Prefer thin Engine controllers + services reusing sale entities (`bitrix-controllers`); standard public checkout is `bitrix:sale.order.ajax` — customize business logic via the object model, not by patching component internals.

## Checklist

- [ ] `sale` (+ `catalog`) included; API level chosen per task (object model / ORM read / manager / legacy).
- [ ] Cart keyed by `Fuser`; catalog lines via `addProductToBasket` or provider class + `refresh`.
- [ ] Order pipeline: person type → basket → props → shipment+delivery calc → payment → `doFinalAction(true)` → SUM sync → restriction re-check → `save()`.
- [ ] Services chosen from restricted lists, never by raw ID from request.
- [ ] Rights checked (`CSaleOrder::CanUser*`, `getAllowedUserStatuses`) before user-driven load/changes.
- [ ] Cancel via `CANCELED='Y'`, not `Order::delete()`; no direct ORM writes to order tables.
- [ ] Coupon applied status verified (`STATUS_APPLYED`), not just `add()`.
- [ ] All `Result`s checked incl. warnings; no `save()` from `OnSaleOrderSaved`.
- [ ] Business logic in services; components/controllers stay thin.

## Related skills

`bitrix-catalog`, `bitrix-iblocks`, `bitrix-result-and-errors`, `bitrix-events`, `bitrix-controllers`, `bitrix-service-locator`.
