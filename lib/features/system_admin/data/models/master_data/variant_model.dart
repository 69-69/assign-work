import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/variant_attr_ext.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';
import 'package:equatable/equatable.dart';

/*Step 3: Display in table/list
Example UI:
Color | Size | SKU
-------------------
Red   | M    | TS-001-R-M
Red   | L    | TS-001-R-L
Blue  | M    | TS-001-B-M
Blue  | L    | TS-001-B-L*/

/// Variant
class Variant extends Equatable {
  final String id;
  final String sku; // TS-001-R-M
  final String itemCode; // TS-001 (parent)
  final Map<String, String> attributes; // {Color: Red, Size: M}
  final List<AuditLog> history;

  const Variant({
    this.id = '',
    required this.sku,
    required this.itemCode,
    required this.attributes,
    List<AuditLog>? history,
  }) : history = history ?? const []; // Set default itemCode

  static List<Variant> buildVariants({
    required List<Map<String, Attribute>> variants,
    required String itemCode,
  }) {
    return variants.map((variant) {
      // Full readable values
      final attributes = variant.toCodeMap(useValue: true);

      // Short codes for SKU
      final codeMap = variant.toCodeMap();

      final sku = buildSKU(itemCode, codeMap).itemSKU;

      return Variant(sku: sku, itemCode: itemCode, attributes: attributes);
    }).toList();
  }

  static ({String variantSKU, String itemSKU}) buildSKU(
    String itemCode,
    Map<String, String> variant,
  ) {
    final sortedKeys = variant.keys.toList()..sort();

    final suffix = sortedKeys.map((k) => variant[k]!.toUpperAll).join('-');

    return (itemSKU: '$itemCode-$suffix', variantSKU: suffix);
  }

  /// fromFirestore / fromJson Function [StoreLocation.fromMap]
  factory Variant.fromMap(Map<String, dynamic> map, {String? id}) {
    return Variant(
      id: id ?? map['id'] ?? '',
      sku: map['sku'] ?? '',
      itemCode: map['itemCode'] ?? '',
      attributes: Map<String, String>.from(map['attributes'] ?? {}),
      history: AuditLog.auditLogs(map['history']),
    );
  }

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() => {
    'id': id,
    'sku': sku,
    'itemCode': itemCode,
    'attributes': attributes,
    'history': history.map((e) => e.toMap()).toList(),
  };

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = toMap();

    return {'id': id, 'data': newMap};
  }

  /// A singleton instance representing an empty/default Variant.
  /// Used as a fallback when no matching Variant is found.
  static final Variant empty = Variant(
    sku: '',
    itemCode: '',
    attributes: const {},
  );

  /// Returns true if this instance is the singleton [empty] Variant.
  /// Use this to check if the Variant is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, Variant.empty);

  bool get isNotEmpty => !isEmpty;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  // String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  // String get getUpdatedAt => updatedAt.toStandardDT;

  String get itemAsString => sku.toTitle;

  /// Filter/Search
  bool filterByAny(String filter) => {sku, itemCode, id}.filterAny(filter);

  /// [findVariantsById]
  static Iterable<Variant> findVariantsById(
    List<Variant> variants,
    String id,
  ) => variants.where((d) => d.id == id);

  /// copyWith method
  Variant copyWith({
    String? id,
    String? sku,
    String? itemCode,
    Map<String, String>? attributes,
    List<AuditLog>? history,
  }) {
    return Variant(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      itemCode: itemCode ?? this.itemCode,
      attributes: attributes ?? this.attributes,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [id, sku, itemCode, attributes, history];

  List<String> itemAsList(List<String> attrKeys) {
    return [
      id,
      sku.toUpperAll,
      itemCode.toTitle,
      ...attrKeys.map((k) => attributes[k]?.toTitle ?? ''),
    ];
  }

  List<String> dataHeader(List<String> keys) => [
    'ID',
    'SKU',
    'Item Code', // item/service Code
    ...keys,
  ];
}

/*Yes — that structure is very solid for a scalable ERP Item Master.

But I’d slightly refine it based on how enterprise ERPs actually separate operational domains.

# Recommended Enterprise ERP Item Master Structure

## 1️⃣ Basic Information

Core identity.

```text id="5z7mne"
- Item Name
- Description
- Short Description
- Item Code
- Parent Item
```

Recommended icon:

```dart id="7o3v1n"
Icons.badge
```

---

## 2️⃣ Classification & Identification

Business categorization.

```text id="5n6gm6"
- Item Type
- Item Group
- Brand
- Model
- SKU Pattern
- Barcode
- Tags
```

Recommended icon:

```dart id="yizjlwm"
Icons.category
```

---

## 3️⃣ Units & Inventory Rules

Inventory behavior.

```text id="3lz94j"
- Base UOM
- Purchase UOM
- Sales UOM
- UOM Conversion
- Track Inventory
- Allow Negative Stock
- Serialized
- Batch Managed
```

Recommended icon:

```dart id="7pq6f4"
Icons.straighten
```

---

## 4️⃣ Inventory Planning

Supply chain planning.

```text id="tnq2np"
- Safety Stock
- Reorder Point
- EOQ
- Lead Time
- Min/Max Stock
- Forecasting
```

Recommended icon:

```dart id="chrm1e"
Icons.analytics
```

---

## 5️⃣ Procurement

Purchasing configuration.

```text id="m8g2xe"
- Preferred Vendor
- Vendor SKU
- MOQ
- Purchase Lead Time
- Purchase Tax Group
```

Recommended icon:

```dart id="m5j7je"
Icons.shopping_cart
```

---

## 6️⃣ Sales

Sales behavior.

```text id="lzgh2r"
- Selling Price
- Price List
- Discount Group
- Commission Group
- Sellable
- Ecommerce Enabled
```

Recommended icon:

```dart id="rk4cuw"
Icons.point_of_sale
```

---

## 7️⃣ Costing & Accounting

Financial integration.

```text id="p1l68x"
- Cost Method
- Standard Cost
- FIFO/LIFO
- Inventory Account
- COGS Account
- Revenue Account
```

Recommended icon:

```dart id="3z8bqj"
Icons.account_balance
```

---

## 8️⃣ Taxes & Compliance

Regulatory data.

```text id="mhxj7l"
- Tax Group
- VAT
- HSN/SAC
- Country Compliance
- Customs Codes
```

Recommended icon:

```dart id="0ux35j"
Icons.receipt_long
```

---

## 9️⃣ Warehousing & Logistics

Storage + shipping.

```text id="u5l78o"
- Default Warehouse
- Bin Location
- Weight
- Dimensions
- Shipping Class
- Packaging
```

Recommended icon:

```dart id="10owyy"
Icons.warehouse
```

---

## 🔟 Attributes & Variants

Variant generation.

```text id="j8otf4"
- Color
- Size
- Material
- Variant Matrix
- Variant SKU
- Variant Barcode
```

Recommended icon:

```dart id="h9jfqv"
Icons.widgets
```

---

## 1️⃣1️⃣ Manufacturing

Production-related settings.

```text id="tx3h2n"
- BOM
- Routing
- Work Center
- Scrap %
- Make-to-Order
- Make-to-Stock
```

Recommended icon:

```dart id="0tb4xq"
Icons.precision_manufacturing
```

---

## 1️⃣2️⃣ Quality Control

Inspection + QA.

```text id="ybjlwm"
- QC Required
- Inspection Template
- Acceptance Rules
- Shelf Life
- Expiry Rules
```

Recommended icon:

```dart id="cb92ic"
Icons.verified
```

---

## 1️⃣3️⃣ Attachments & Media

Supporting files.

```text id="d0ebv0"
- Images
- Datasheets
- Certificates
- SDS/MSDS
- Manuals
```

Recommended icon:

```dart id="0dqv4y"
Icons.attach_file
```

---

## 1️⃣4️⃣ Lifecycle & Status

Operational governance.

```text id="y2w80y"
- Active
- Obsolete
- Launch Date
- End-of-Life
- Approval Status
- Created/Updated By
```

Recommended icon:

```dart id="pcg7fe"
Icons.timeline
```

---

# One Important Enterprise Recommendation

You should make sections conditional based on item type.

Example:

| Section            | Inventory | Service  |
| ------------------ | --------- | -------- |
| Warehouse          | ✅         | ❌        |
| Manufacturing      | ✅         | ❌        |
| Inventory Planning | ✅         | ❌        |
| Variants           | ✅         | Optional |

This keeps the ERP clean.

---

# Suggested Flutter UX

Your current `FormGroupCard` architecture is GOOD.

You already have the right pattern:

```dart id="jlwmww"
FormGroupCard(
  title: '',
  subTitle: '',
  children: [],
)
```

That scales very well.

---

# Final Recommendation

For a modern ERP:

## Keep visible by default:

```text id="gprg3u"
1–8
```

## Collapse advanced sections:

```text id="owpyl4"
9–14
```

because enterprise item masters can easily exceed 150+ fields.

Your architecture is already moving in the correct direction.
*/

/*Your structure is already strong for a modern ERP Item Master. The next step is mostly about covering operational edge cases, accounting integration, and scalability.

Here’s what’s commonly added in enterprise ERP systems beyond what you already have.

---

# Recommended Additional Sections

## 2️⃣ Classification & Type (Missing in UI)

You referenced it in comments but it isn’t rendered yet.

Usually includes:

```dart
- Item Type
- Item Group / Category
- Brand
- Model
- SKU
- Barcode / QR Code
- HSN/SAC / Harmonized Code
- Serial/Lot Controlled
- Batch Managed
- Shelf Life Enabled
- Perishable
```

Recommended icon:

```dart
Icons.category
```

---

# 9️⃣ Inventory Control

Very important in ERP.

Typical fields:

```dart
- Safety Stock
- Minimum Stock
- Maximum Stock
- Reorder Point
- Reorder Quantity
- ABC Classification
- Cycle Count Frequency
- Negative Stock Allowed
- Stock Reservation Allowed
```

Useful because planning + stock policies usually grow large later.

Recommended icon:

```dart
Icons.inventory
```

---

# 🔟 Serial / Batch Tracking

If manufacturing, pharma, electronics, food, etc.

Fields:

```dart
- Serial Number Required
- Batch Number Required
- Expiry Tracking
- Manufacturing Date Tracking
- Warranty Period
- Traceability Level
```

---

# 1️⃣1️⃣ Sales Information

Very common separation from purchasing.

```dart
- Sales UOM
- Default Selling Price
- Price List
- Discount Group
- Commission Group
- Sellable
- Online Available
```

Recommended icon:

```dart
Icons.point_of_sale
```

---

# 1️⃣2️⃣ Purchasing Information

```dart
- Preferred Vendor
- Vendor Item Code
- Purchase UOM
- Last Purchase Price
- Lead Time
- MOQ (Minimum Order Qty)
- Purchase Tax Group
```

Recommended icon:

```dart
Icons.shopping_cart
```

---

# 1️⃣3️⃣ Manufacturing / BOM

If ERP supports production.

```dart
- BOM Enabled
- Default BOM
- Production UOM
- Scrap %
- Routing
- Work Center
- Make-to-Stock / Make-to-Order
```

Recommended icon:

```dart
Icons.precision_manufacturing
```

---

# 1️⃣4️⃣ Accounting Integration

Critical for finance integration.

```dart
- Inventory GL Account
- COGS Account
- Sales Account
- Purchase Account
- Asset Account
- Expense Account
- Cost Center
```

Recommended icon:

```dart
Icons.account_balance
```

---

# 1️⃣5️⃣ Quality Control

Useful for enterprise systems.

```dart
- Inspection Required
- QC Template
- Acceptance Criteria
- Quality Grade
```

---

# 1️⃣6️⃣ Dimensions & Logistics

Especially useful for shipping.

```dart
- Weight
- Height
- Width
- Length
- Volume
- Packing Type
- Shipping Class
```

Recommended icon:

```dart
Icons.straighten
```

---

# 1️⃣7️⃣ Media & Documents

Very modern ERP feature.

```dart
- Product Images
- Datasheets
- Certificates
- Attachments
- MSDS files
```

Recommended icon:

```dart
Icons.attach_file
```

---

# 1️⃣8️⃣ Status & Lifecycle

Useful operationally.

```dart
- Active / Inactive
- Obsolete
- Launch Date
- End-of-Life Date
- Approval Status
```

Recommended icon:

```dart
Icons.timeline
```

---

# Architecture Recommendation

Your current grouping is good for SMEs.

For enterprise scalability, I’d recommend this structure:

```text
1. Basic Information
2. Classification & Identification
3. Units & Inventory Rules
4. Inventory Planning
5. Procurement
6. Sales
7. Costing & Accounting
8. Taxes & Pricing
9. Warehousing & Logistics
10. Attributes & Variants
11. Manufacturing
12. Quality Control
13. Attachments & Media
14. Lifecycle & Status
```

---

# Important ERP Design Advice

Avoid placing too many fields in one giant form.

Enterprise ERPs usually use:

* Expansion panels (like you already do)
* Tabs
* Lazy-loaded sections
* Dynamic sections based on item type

Example:

```dart
if (_itemType == ItemType.service)
```

Hide:

* warehouse
* stock
* manufacturing
* dimensions

This dramatically improves UX.

---

# Smart Enterprise Features You May Want Later

These become huge differentiators:

### AI / Smart Fields

* Suggested reorder quantity
* Auto classification
* Auto tax code

### Multi-company Support

* Company-specific pricing
* Warehouse restrictions

### Multi-UOM Conversion

Example:

```text
1 Box = 24 Pieces
```

### Variant Matrix

Instead of generating variants one-by-one.

### Audit Trail

Track:

```text
Created By
Modified By
Approved By
```

---

# Your Current Design Quality

You’re already designing closer to:

* SAP Business One
* Oracle NetSuite
* Odoo Enterprise
* Microsoft Dynamics 365

than a basic inventory app.

The modular panel approach is the correct architecture.
*/


/*You’re **closer**, but this still has the same structural flaw — just renamed.

Right now your `Attribute` model is still doing **two jobs at once**:

```dart
final String name;  // Color
final String value; // Red
```

That means each row is:

> “Color = Red”

But your ERP table needs:

> “Color = Red AND Size = M = ONE SKU”

So this model is still **not capable of representing a full variant row**.

---

## ⚠️ The subtle but important problem

With your current design, your data will look like:

```text
Attribute(name: Color, value: Red)
Attribute(name: Color, value: Blue)
Attribute(name: Size, value: M)
Attribute(name: Size, value: L)
```

That’s fine **for defining options**, but:

👉 There is **no link that says**:

```
Red + M = TS-001-R-M
```

So you still **cannot generate or store ERP variants properly**.

---

## ✅ What you did right

This part is good:

✔ Clean model
✔ Good audit trail
✔ Works well for:

* dropdowns (Color list, Size list)
* filtering
* configuration UI

So keep it — just **don’t use it as the final variant model**.

---

## ❗ What’s missing (critical)

You are missing the **actual SKU entity**.

You need something like this:

```dart
class ProductVariant {
  final String id;
  final String sku;
  final String storeNumber;

  // KEY: combination of attributes
  final Map<String, String> attributes;
  // Example: { "Color": "Red", "Size": "M" }

  final DateTime createdAt;
}
```

---

## 🔥 How your system should work (ERP flow)

### Step 1: Define attributes (your current model)

```text
Color → Red, Blue
Size  → M, L
```

Stored using your `Attribute` class ✅

---

### Step 2: Generate combinations (service layer)

Result:

```text
[Color: Red, Size: M]
[Color: Red, Size: L]
[Color: Blue, Size: M]
[Color: Blue, Size: L]
```

---

### Step 3: Create ProductVariants (missing layer)

```text
SKU: TS-001-R-M → {Color: Red, Size: M}
SKU: TS-001-R-L → {Color: Red, Size: L}
```

---

## 🧠 Key design rule (important)

* `Attribute` → defines options
* `ProductVariant` → defines **sellable item (SKU)**

If you don’t separate these, you’ll hit problems with:

* inventory tracking
* pricing per variant
* barcode assignment
* reporting

---

## 💡 Small improvement to your current model

Right now:

```dart
final String name;
final String value;
```

This creates duplication like:

* "Color" repeated for every value

### Better (optional improvement):

Split internally:

```dart
class Attribute {
  final String id;
  final String name; // Color
}

class AttributeValue {
  final String id;
  final String attributeId;
  final String value; // Red
}
```

This avoids repeating `"Color"` 1000 times.

---

## 🧱 Final verdict

Your current model is:

✅ Good for:

* attribute/value storage
* UI selection
* filtering

❌ Not sufficient for:

* ERP variant generation
* SKU-level operations
* inventory system

---

## 👍 What I’d do in your place

1. **Keep your `Attribute` model (slightly refactor later)**
2. **Add `ProductVariant` immediately**
3. Move:

   ```dart
   sku
   ```

   → into `ProductVariant`

---

If you want, next step I can give you:

* ✅ Cartesian combination generator (clean Dart)
* ✅ Auto SKU generator (`TS-001-R-M`)
* ✅ Firestore structure for scaling

That’s where this really becomes “ERP-grade.”
*/
