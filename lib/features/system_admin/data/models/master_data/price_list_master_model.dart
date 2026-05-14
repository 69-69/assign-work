import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/price_list_types.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

/*
The **Price List is usually created independently**, but the **Price List Entries are created during or after Item Master variant generation**.

So the sequence is:

```text id="2p2s85"
1. Create Price Lists
2. Create Item Master
3. Generate Variants/SKUs
4. Link Variants to Price Lists
```

---

# Think of It This Way

## Price List

A price list is just a pricing category/template.

Examples:

| PriceListID | Name          |
| ----------- | ------------- |
| RETAIL      | Retail        |
| WHOLESALE   | Wholesale     |
| VIP         | VIP Customers |

These exist globally in the ERP.

They are NOT tied to one item.

So you create them once.

---

# Then Item Master Is Created

Example:

```text id="v4g3qz"
TS-001
T-Shirt
```

---

# Then Variants Are Generated

```text id="w6jz6r"
TS-001-RED-M
TS-001-RED-L
TS-001-BLK-M
```

---

# THEN Price Entries Are Generated

Example:

| PriceList | SKU          | Price |
| --------- | ------------ | ----- |
| RETAIL    | TS-001-RED-M | 100   |
| RETAIL    | TS-001-RED-L | 110   |
| WHOLESALE | TS-001-RED-M | 85    |

These rows are called:

```text id="u8gk4m"
PriceListEntries
```

---

# Important Distinction

## Price List

Master/configuration data.

Created BEFORE items.

Example:

* Retail
* Wholesale
* Distributor
* Online Store

---

## Price List Entry

Transactional/commercial data.

Created AFTER variants exist.

Because:

* you need the SKU/variantSku first
* prices attach to variants

---

# In Your System

You likely need:

## 1. PriceList

```dart id="kew7s2"
class PriceList {
  final String id;
  final String name;
}
```

Created once by admin.

---

# 2. ItemMaster

```dart id="rqowv1"
class ItemMaster {
  final String itemCode;
  final double basePrice;
}
```

---

# 3. Variant

Generated dynamically.

```dart id="k5q8b4"
class Variant {
  final String id;
  final String sku;
}
```

---

# 4. PriceListEntry

Created after variants.

```dart id="9mh3rj"
class PriceListEntry {
  final String variantSku;
  final String priceListId;
  final double price;
}
```

---

# Typical Save Flow in Your App

## User Creates Item

```text id="0pd5sv"
T-Shirt
```

---

## User Selects Attributes

```text id="i09x2v"
Color: Red, Black
Size: M, L
```

---

## App Generates Variants

```text id="f4mh9v"
TS-001-RED-M
TS-001-RED-L
...
```

---

## User Enters Price Adjustments

Inside your table:

| SKU   | Price Adjust |
| ----- | ------------ |
| RED-M | 0            |
| RED-L | 10           |

---

## App Saves

### Save ItemMaster

then

### Save Variants

then

### Save PriceListEntries

Example:

```text id="r1f3az"
variantSku: V1
PriceList: RETAIL
Price: 100
```

---

# Best Practice

Usually:

* Item Master owns base/default price
* Variant owns adjustment
* Price List Entry owns actual selling price

This gives maximum flexibility later.

*/

class PriceListMaster extends Equatable {
  final String id;
  final String storeNumber;
  final String name; // Wholesale, Retail, VIP Customers, etc
  final PriceListType type; // determines if the lines are selling or purchase
  final String currencyCode;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool taxInclusive;

  /// Audit history
  final List<AuditLog> history;

  const PriceListMaster({
    this.id = '',
    required this.storeNumber,
    required this.name,
    this.type = PriceListType.sales,
    required this.currencyCode,
    this.validFrom,
    this.validUntil,
    this.taxInclusive = false,
    this.history = const [],
  });

  factory PriceListMaster.fromMap(Map<String, dynamic> map, {String? id}) {
    return PriceListMaster(
      id: id ?? map['id'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      name: map['name'] ?? '',
      type: PriceListUtil.fromString(map['type']),
      currencyCode: map['currencyCode'] ?? '',
      validFrom: toDateTimeFn(map['validFrom']),
      validUntil: toDateTimeFn(map['validUntil'], isNullable: true),
      taxInclusive: map['taxInclusive'] ?? false,
      history: AuditLog.auditLogs(map['history']),
    );
  }

  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'storeNumber': storeNumber,
    'name': name,
    'type': getType,
    'currencyCode': currencyCode,
    'taxInclusive': taxInclusive,
    'history': history.map((e) => e.toMap()).toList(),
  };

  String get getType => type.getName;

  String get getValidFrom => validFrom.dateOnly;

  String get getValidUntil => validUntil.dateOnly;

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap([bool formatDate = false]) {
    var newMap = _mapTemp();
    newMap['validFrom'] = formatDate ? getValidFrom : validFrom?.toISOString;
    newMap['validUntil'] = formatDate ? getValidUntil : validUntil?.toISOString;

    return newMap;
  }

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();

    newMap['validFrom'] = validFrom?.toMilliseconds;
    newMap['validUntil'] = validUntil?.toMilliseconds;

    return {'id': id, 'data': newMap};
  }

  /// [empty] Empty PriceListMaster object.
  static final PriceListMaster empty = PriceListMaster(
    storeNumber: '',
    name: '',
    currencyCode: '',
  );

  /// [isEmpty] Checks if the PriceListMaster is empty.
  bool get isEmpty => identical(this, PriceListMaster.empty);

  bool get isNotEmpty => !isEmpty;

  /// Filter/search
  bool filterByAny(String filter) => itemAsList.filterAny(filter);

  /// [findById] Find PriceList by ID.
  static PriceListMaster? findById(List<PriceListMaster> items, String id) =>
      items.firstWhereOrNull((i) => i.id == id);

  static List<String> get dataTableHeader => const [
    'ID',
    'Price List',
    'Type',
    'Currency',
    'Taxed',
    'Valid From',
    'Valid Until',
  ];

  /// ToList for Price List [itemAsList]
  List<String> get itemAsList => [
    id,
    name.toTitle,
    getType.toSentence,
    currencyCode.toUpperAll,
    taxInclusive ? 'Yes' : 'No',
    validFrom.toStandardDT,
    validUntil.toStandardDT,
  ];

  /// For Bulk Upload/Saving template
  static Map<String, dynamic> get templateHeader => empty.toMap();

  PriceListMaster copyWith({
    String? storeNumber,
    String? id,
    String? name,
    bool? taxInclusive,
    PriceListType? type,
    String? currencyCode,
    DateTime? validFrom,
    DateTime? validUntil,
    List<AuditLog>? history,
  }) => PriceListMaster(
    storeNumber: storeNumber ?? this.storeNumber,
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    taxInclusive: taxInclusive ?? this.taxInclusive,
    currencyCode: currencyCode ?? this.currencyCode,
    validFrom: validFrom ?? this.validFrom,
    validUntil: validUntil ?? this.validUntil,
    history: history ?? this.history,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    currencyCode,
    validFrom,
    validUntil,
    taxInclusive,
  ];
}

class PriceListEntry {
  final String id;

  /// FK -> PriceList.id
  final String priceListId;

  /// FK -> Variant.sku
  final String variantSku;

  /// Actual customer-facing selling price
  final double sellingPrice;

  /// Minimum quantity for this pricing tier
  final int? minQuantity;

  /// Additional discount percentage
  final double discountPercent;

  /// Audit history
  final List<AuditLog> history;

  PriceListEntry({
    required this.id,
    required this.priceListId,
    required this.variantSku,
    required this.sellingPrice,
    this.minQuantity,
    this.discountPercent = 0.0,
    this.history = const [],
  });

  factory PriceListEntry.fromMap(Map<String, dynamic> map, {String? id}) {
    return PriceListEntry(
      id: id ?? map['id'] ?? '',
      priceListId: map['priceListId'] ?? '',
      variantSku: map['variantSku'] ?? '',
      sellingPrice: '${map['sellingPrice']}'.asDouble,
      minQuantity: '${map['minQuantity']}'.asInt,
      discountPercent: '${map['discountPercent']}'.asDouble,
      history: AuditLog.auditLogs(map['history']),
    );
  }

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() => {
    'id': id,
    'priceListId': priceListId,
    'variantSku': variantSku,
    'sellingPrice': sellingPrice,
    'minQuantity': minQuantity,
    'discountPercent': discountPercent,
    'history': history.map((e) => e.toMap()).toList(),
  };

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = toMap();
    return {'id': id, 'data': newMap};
  }

  /// [empty] Empty PriceListEntry object.
  static final PriceListEntry empty = PriceListEntry(
    id: '',
    priceListId: '',
    variantSku: '',
    sellingPrice: 0,
  );

  /// [isEmpty] Checks if the PriceListMaster is empty.
  bool get isEmpty => identical(this, PriceListMaster.empty);

  bool get isNotEmpty => !isEmpty;

  /// Filter/search
  bool filterByAny(String filter) => itemAsList.filterAny(filter);

  /// [findById] Find PriceList Entry by ID.
  static PriceListEntry? findById(List<PriceListEntry> items, String id) =>
      items.firstWhereOrNull((i) => i.id == id);

  static List<String> get dataTableHeader => const [
    'ID',
    'SKU',
    'Price',
    'Min Qty',
    'Discount %',
  ];

  /// ToList for Price Entry [itemAsList]
  List<String> get itemAsList => [
    id,
    variantSku,
    sellingPrice.toCurrency.toString(),
    minQuantity?.toString() ?? '0',
    discountPercent.toPercent.toString(),
  ];

  static Map<String, dynamic> get templateHeader => empty.toMap();

  PriceListEntry copyWith({
    String? id,
    String? variantSku,
    String? priceListId,
    double? sellingPrice,
    int? minQuantity,
    double? discountPercent,
    List<AuditLog>? history,
  }) => PriceListEntry(
    id: id ?? this.id,
    history: history ?? this.history,
    variantSku: variantSku ?? this.variantSku,
    priceListId: priceListId ?? this.priceListId,
    minQuantity: minQuantity ?? this.minQuantity,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    discountPercent: discountPercent ?? this.discountPercent,
  );
}
