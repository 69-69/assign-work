import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/dashboard_tile_card.dart';
import 'package:assign_erp/features/warehouse_wms/presentation/warehouse_tiles.dart';
import 'package:flutter/material.dart';

// Integrating WMS into your ERP requires tracking stock movement, locations, bins, picking/packing, and shipment statuses
class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      isGradientBg: true,
      title: warehouseAppTitle,
      tiles: warehouseTiles,
      body: _buildDashboard(),
    );
  }

  DashboardTileCard _buildDashboard() => DashboardTileCard(
    tiles: warehouseTiles,
    metricsTitle: "POS Metrics",
    metricsSubtitle:
        "Oversee stock movement, bin usage, and warehouse efficiency.",
    metrics: {
      "Total Items": 34,
      "Out of Stock": 34,
      "Low Stock": 34,
      "Bins Used": 210,
      "Utilization (%)": 5,
    },
  );
}

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
