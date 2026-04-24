import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

/*class ProductVariant {
  final String id;
  final String sku;
  final String storeNumber;

  // KEY: combination of attributes
  final Map<String, String> attributes;
  // Example: { "Color": "Red", "Size": "M" }

  final DateTime createdAt;
}*/

/*Step 3: Display in table/list
Example UI:
Color | Size | SKU
-------------------
Red   | M    | TS-001-R-M
Red   | L    | TS-001-R-L
Blue  | M    | TS-001-B-M
Blue  | L    | TS-001-B-L*/

/// Variant Attributes
class Variant extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String sku; // TS-001-R-M
  final String itemCode; // TS-001 (parent)
  final Map<String, String> attributes; // {Color: Red, Size: M}
  final String storeNumber; // FK CompanyStore.storeNumber
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;
  final List<AuditLog> history;

  Variant({
    this.id = '',
    required this.sku,
    required this.itemCode,
    required this.attributes,
    required this.storeNumber,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) : history = history ?? const [],
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default itemCode

  static List<Variant> buildVariants({
    required List<Map<String, String>> variants,
    required String itemCode,
  }) {
    return variants.map((variant) {
      final sku = buildVariantSKU(itemCode, variant);

      return Variant(
        sku: sku,
        itemCode: itemCode,
        attributes: variant,
        storeNumber: '',
        createdBy: '',
      );
    }).toList();
  }

  static String buildVariantSKU(String itemCode, Map<String, String> variant) {
    /*final suffix = variant.values
        .map((e) => e.isNotEmpty ? e.toUpperAll : '')
        .join('-');*/
    final sortedKeys = variant.keys.toList()..sort();

    final suffix = sortedKeys
        .map((k) => variant[k]!.toUpperAll)
        .join('-');

    return '$itemCode-$suffix';
  }

  /// fromFirestore / fromJson Function [StoreLocation.fromMap]
  factory Variant.fromMap(Map<String, dynamic> map, {String? id}) {
    return Variant(
      id: id ?? map['id'] ?? '',
      sku: map['sku'] ?? '',
      itemCode: map['itemCode'] ?? '',
      attributes: Map<String, String>.from(map['attributes'] ?? {}),
      storeNumber: map['storeNumber'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(map['updatedAt']),
      history: AuditLog.auditLogs(map['history']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'sku': sku,
    'itemCode': itemCode,
    'attributes': attributes,
    'storeNumber': storeNumber,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'history': history.map((e) => e.toMap()).toList(),
  };

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.toMilliseconds;
    newMap['updatedAt'] = updatedAt.toMilliseconds;

    return {'id': id, 'data': newMap};
  }

  /// A singleton instance representing an empty/default Variant.
  /// Used as a fallback when no matching Variant is found.
  static final Variant empty = Variant(
    sku: '',
    itemCode: '',
    attributes: const {},
    createdBy: '',
    storeNumber: '',
  );

  /// Returns true if this instance is the singleton [empty] Variant.
  /// Use this to check if the Variant is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, Variant.empty);

  bool get isNotEmpty => !isEmpty;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  /// Current / Today's Products/Stocks
  bool get isToday {
    var dt = createdAt.toDateTime;

    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  String get itemAsString => sku.toTitle;

  /// Filter/Search
  bool filterByAny(String filter) =>
      {sku, itemCode, id, storeNumber}.filterAny(filter);

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
    String? storeNumber,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) {
    return Variant(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      itemCode: itemCode ?? this.itemCode,
      attributes: attributes ?? this.attributes,
      storeNumber: storeNumber ?? this.storeNumber,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [
    id,
    sku,
    itemCode,
    attributes,
    storeNumber,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
    history,
  ];

  /// ToList for StoreLocation [itemAsList]
  List<String> get itemAsList => [
    id,
    sku.toUpperAll,
    itemCode.toTitle,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataHeader => const [
    'ID',
    'SKU',
    'Parent', // item/service Code
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}

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
