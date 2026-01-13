import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/dashboard_tile_card.dart';
import 'package:assign_erp/features/inventory_ims/presentation/inventory_tiles.dart';
import 'package:flutter/material.dart';

// Integrating WMS into your ERP requires tracking stock movement, locations, bins, picking/packing, and shipment statuses
class WMSScreen extends StatelessWidget {
  const WMSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      isGradientBg: true,
      title: warehouseAppTitle,
      body: DashboardTileCard(tiles: warehouseSubTiles),
    );
  }
}

/*🏭 Example
A company receives 100 laptops:
Stock Management: inventory +100 laptops
WMS:
Assigns bins
Creates put-away tasks
Guides picking when orders arrive
Manages packing and shipping*/

/*You’re on the **right foundation**, but a real WMS needs **a bit more structure** to work in practice.

Below is a **clean, realistic WMS data model**, starting from what you already have and expanding **only what’s truly needed**.

I’ll keep it **pragmatic**, not over-engineered.

---

## 1️⃣ Warehouse (good, minor additions)

```text
Warehouse
---------
id (PK)
code
name
type (Main | Store | Transit)
isActive
addressId
```

✅ Optional but common:

* `addressId` → shipping, receiving, routing
* `isDefault` → for auto-allocation

---

## 2️⃣ Location / Bin (needs hierarchy & control)

Your current `Location` is missing **how the warehouse is structured**.

### Recommended structure (single table, flexible)

```text
Location
--------
id (PK)
warehouseId (FK)
parentLocationId (FK, nullable)
code
name
type (Zone | Aisle | Rack | Bin)
isPickLocation (bool)
isActive
```

### Why this matters

* Supports **Zone → Aisle → Rack → Bin**
* Works for **small & large warehouses**
* Avoids multiple tables

Example:

```
WH-01
 └─ Z-REC (Zone)
    └─ A-01 (Aisle)
       └─ R-02 (Rack)
          └─ B-15 (Bin)
```

---

## 3️⃣ Item Location (Bin Inventory) ⭐ **Critical**

This is where WMS becomes real.

```text
ItemLocation
------------
id (PK)
itemId (FK)
locationId (FK)
quantity
reservedQuantity
batchNo
serialNo
expiryDate
status (Available | Damaged | Quarantine)
```

📌 This is **NOT stock management** — this is *physical presence*.

---

## 4️⃣ Put-Away Rules (optional but very useful)

```text
PutAwayRule
-----------
id (PK)
warehouseId (FK)
itemCategoryId (FK, nullable)
preferredLocationId (FK)
priority
```

👉 Allows:

* Auto-suggest bins
* Fast receiving

---

## 5️⃣ Picking / Packing Locations

You can model this via flags, or explicitly:

```text
Location
--------
...
isPickLocation
isBulkLocation
```

OR

```text
LocationType
------------
code (PICK | BULK | STAGING | QC)
```

---

## 6️⃣ Internal Movements (Bin-to-Bin)

```text
WarehouseMovement
-----------------
id (PK)
fromLocationId (FK)
toLocationId (FK)
itemId (FK)
quantity
reason (PutAway | Replenish | Transfer | Adjustment)
status (Draft | Completed)
createdAt
```

---

## 7️⃣ Receiving (Inbound Execution)

```text
WarehouseReceipt
----------------
id (PK)
warehouseId (FK)
referenceType (PO | Transfer | Return)
referenceId
status (Draft | Received)
receivedAt
```

```text
WarehouseReceiptLine
--------------------
id (PK)
receiptId (FK)
itemId (FK)
quantity
```

---

## 8️⃣ Picking / Shipping (Outbound Execution)

```text
PickList
--------
id (PK)
warehouseId (FK)
referenceType (SO | Transfer)
referenceId
status (Open | Picked | Packed | Shipped)
```

```text
PickListLine
------------
id (PK)
pickListId (FK)
itemId (FK)
fromLocationId (FK)
quantity
```

---

## 9️⃣ Cycle Counting

```text
CycleCount
----------
id (PK)
warehouseId (FK)
status (Open | Completed)
```

```text
CycleCountLine
--------------
id (PK)
cycleCountId (FK)
itemId (FK)
locationId (FK)
systemQty
countedQty
```

---

## 🔑 Minimum Viable WMS (if you want lean)

If you want **just enough WMS**, don’t go beyond:

✔ Warehouse
✔ Location (hierarchical)
✔ ItemLocation
✔ WarehouseMovement

Everything else can come later.

---

## 🧠 Key Design Principle (important)

> **Stock Management owns “how much”**
> **WMS owns “where exactly”**

Never mix valuation, costing, or reorder logic into WMS tables.

---

## Final Takeaway

Your current model is **correct but incomplete**.
To be a *real* WMS, you must add:

* Location hierarchy
* Item ↔ Location quantities
* Movement tracking

If you want, next I can:

* Draw this as a **simple ER diagram**
* Help you decide **what NOT to build yet**
* Map this model to SAP / Odoo style WMS
* Help you design APIs or events between Stock & WMS

Just tell me where you want to go next.
*/

/*Great question. A **Warehouse Management System (WMS)** is a key component of ERP, especially in multi-tenant or multi-location environments. Integrating WMS into your ERP requires tracking **stock movement**, **locations**, **bins**, **picking/packing**, and **shipment statuses**—all per tenant (`workspaceId` in your case).

Let’s break this down by:

---

### 🏗️ Firestore Data Model for WMS per Workspace

```
workspaces/{workspaceId}/warehouses/{warehouseId}/
```

Each warehouse can have:

* `bins`: Storage units (rows, shelves, zones)
* `items`: SKUs or inventory units in that warehouse
* `transactions`: Stock ins/outs/movements
* `stats`: Aggregated warehouse-level metrics

---

### 📦 Sample Firestore Collections

#### 1. `workspaces/{workspaceId}/warehouses/{warehouseId}`

```json
{
  "name": "Main Warehouse",
  "location": "Dubai",
  "createdAt": "2024-01-01",
  "managerId": "user123"
}
```

#### 2. `/bins/{binId}`

```json
{
  "name": "A1-Shelf",
  "zone": "A",
  "capacity": 100,
  "occupied": 40
}
```

#### 3. `/items/{itemId}`

```json
{
  "productId": "sku123",
  "quantity": 50,
  "binId": "binA1",
  "lastUpdated": "2025-07-14T12:00:00Z"
}
```

#### 4. `/transactions/{transactionId}`

```json
{
  "type": "inbound", // or "outbound", "transfer"
  "productId": "sku123",
  "quantity": 10,
  "from": null,
  "to": "binA1",
  "timestamp": "2025-07-15T09:00:00Z",
  "userId": "user456"
}
```

#### 5. `/stats`

A document like:

```json
{
  "totalItems": 1200,
  "outOfStock": 4,
  "lowStock": 12,
  "binsUsed": 20,
  "spaceUtilization": 75.3 // percentage
}
```

---

### 📊 Dart: Fetch WMS Stats

```dart
Future<Map<String, dynamic>> fetchWMSMetrics(
  String workspaceId,
  String warehouseId,
) async {
  final doc = await FirebaseFirestore.instance
      .collection('workspaces')
      .doc(workspaceId)
      .collection('warehouses')
      .doc(warehouseId)
      .collection('stats')
      .doc('overview')
      .get();

  if (!doc.exists) return {};

  final data = doc.data()!;
  return {
    "Total Items": data['totalItems'] ?? 0,
    "Out of Stock": data['outOfStock'] ?? 0,
    "Low Stock": data['lowStock'] ?? 0,
    "Bins Used": data['binsUsed'] ?? 0,
    "Utilization (%)": data['spaceUtilization']?.toStringAsFixed(1) ?? '0.0',
  };
}
```

---

### 🔁 Updating Warehouse Stats

Use **Firestore triggers** or **on-write Cloud Functions** to:

* Update bin occupancy when items are moved
* Recalculate `totalItems` when stock is received or shipped
* Track space utilization by comparing bin capacity vs. usage

Example (in Cloud Functions):

```ts
exports.onItemUpdate = functions.firestore
  .document('workspaces/{workspaceId}/warehouses/{warehouseId}/items/{itemId}')
  .onWrite(async (change, context) => {
    // Recalculate total quantity, bin usage, etc.
  });
```

---

### 🔒 Security Rules (Multi-Tenant)

Make sure each tenant can only access their own warehouse data:

```js
match /workspaces/{workspaceId}/warehouses/{warehouseId} {
  allow read, write: if request.auth != null && request.auth.token.workspaceId == workspaceId;
}
```

---

### 🔍 WMS Features You Can Add Later

1. **Putaway algorithms** – Suggest bins to store incoming items
2. **Pick lists & wave picking** – Optimize order fulfillment
3. **Barcode scanning** – Mobile UI for moving/checking stock
4. **Cycle counts** – Regular inventory audits
5. **Replenishment triggers** – Auto-notify when stock is low

---

Would you like a Firestore schema export or helper functions for adding/moving stock in WMS?
*/
