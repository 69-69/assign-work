import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/discount_type.dart';
import 'package:assign_erp/core/util/extensions/transaction_type.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

/*`DiscountType` defines **how the discount is calculated**.

In ERP systems, the most common types are:

| DiscountType  | Meaning                          |
| ------------- | -------------------------------- |
| percentage    | Reduce by %                      |
| fixedAmount   | Reduce by fixed currency value   |
| overridePrice | Replace selling price completely |
| freeItem      | Buy X get Y / free quantity      |
| tiered        | Quantity slab discount           |
| formula       | Custom calculation logic         |

---

# Recommended Enum for Your System

For your ERP, start simple:

```dart
enum DiscountType {
  percentage,
  fixedAmount,
  overridePrice,
}
```

This covers ~90% of ERP pricing scenarios.

---

# Example Usage

## 1. Percentage Discount

```text
Retail Price = 100
Discount = 10%
Final = 90
```

```dart
discountType: DiscountType.percentage
discountValue: 10
```

---

# 2. Fixed Amount Discount

```text
Retail Price = 100
Discount = 15
Final = 85
```

```dart
discountType: DiscountType.fixedAmount
discountValue: 15
```

---

# 3. Override Price

Very common in wholesale/distributor ERP.

```text
Original Price = 100
Override Price = 70
Final = 70
```

```dart
discountType: DiscountType.overridePrice
discountValue: 70
```

This is useful when:

* negotiated pricing exists
* customer contracts exist
* distributor pricing differs

---

# Recommended Helper

```dart
extension DiscountTypeX on DiscountType {
  String get name {
    switch (this) {
      case DiscountType.percentage:
        return 'Percentage';

      case DiscountType.fixedAmount:
        return 'Fixed Amount';

      case DiscountType.overridePrice:
        return 'Override Price';
    }
  }
}
```

---

# Recommended Calculation Engine

```dart
double applyDiscount({
  required double basePrice,
  required DiscountType type,
  required double value,
}) {
  switch (type) {
    case DiscountType.percentage:
      return basePrice - (basePrice * value / 100);

    case DiscountType.fixedAmount:
      return basePrice - value;

    case DiscountType.overridePrice:
      return value;
  }
}
```

---

# Advanced ERP Types (Later)

You can add later:

```dart
enum DiscountType {
  percentage,
  fixedAmount,
  overridePrice,

  buyXGetY,
  quantityTier,
  formula,
  couponCode,
  seasonal,
}
```

But these require:

* promotion engine
* rule evaluator
* condition builder

So avoid them initially.

---

# Recommended Initial ERP Design

Your pricing architecture should become:

```text
PriceListMaster
    ↓
PriceListEntry
    ↓
DiscountGroup
    ↓
DiscountRule
```

Where:

```text
PriceListEntry = Base selling price
DiscountRule = Adjustment logic
```

That separation is exactly how large ERP systems structure pricing engines.
*/

/// Discount Group Master Model
class DiscountGroup extends Equatable {
  final String id;
  final String storeNumber;
  final String name; // Promo, Christmas discount
  final TransactionType transactionType;
  final String description;

  /// Validity period
  final DateTime? validFrom;
  final DateTime? validUntil;

  /// Audit history
  final List<AuditLog> history;

  const DiscountGroup({
    this.id = '',
    required this.storeNumber,
    required this.name,
    this.transactionType = TransactionType.sales,
    required this.description,
    this.validFrom,
    this.validUntil,
    this.history = const [],
  });

  factory DiscountGroup.fromMap(Map<String, dynamic> map, {String? id}) {
    return DiscountGroup(
      id: id ?? map['id'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      name: map['name'] ?? '',
      transactionType: TransactionTypeUtil.fromString(map['transactionType']),
      description: map['description'] ?? '',
      validFrom: toDateTimeFn(map['validFrom']),
      validUntil: toDateTimeFn(map['validUntil'], isNullable: true),
      history: AuditLog.auditLogs(map['history']),
    );
  }

  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'storeNumber': storeNumber,
    'name': name,
    'transactionType': getTransactionType,
    'description': description,
    'history': history.map((e) => e.toMap()).toList(),
  };

  String get getTransactionType => transactionType.getName;

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

  /// [empty] Empty DiscountGroupMaster object.
  static final DiscountGroup empty = DiscountGroup(
    storeNumber: '',
    name: '',
    description: '',
  );

  /// [isEmpty] Checks if the DiscountGroupMaster is empty.
  bool get isEmpty => identical(this, DiscountGroup.empty);

  bool get isNotEmpty => !isEmpty;

  /// Filter/search
  bool filterByAny(String filter) => itemAsList.filterAny(filter);

  /// [findById] Find PriceList by ID.
  static DiscountGroup? findById(List<DiscountGroup> items, String id) =>
      items.firstWhereOrNull((i) => i.id == id);

  static List<String> get dataTableHeader => const [
    'ID',
    'Group',
    'Transaction',
    'Valid From',
    'Valid Until',
  ];

  /// ToList for Price List [itemAsList]
  List<String> get itemAsList => [
    id,
    name.toTitle,
    getTransactionType.toTitle,
    validFrom.toStandardDT,
    validUntil.toStandardDT,
  ];

  /// For Bulk Upload/Saving template
  static Map<String, dynamic> get templateHeader => empty.toMap();

  DiscountGroup copyWith({
    String? storeNumber,
    String? id,
    String? name,
    TransactionType? transactionType,
    String? description,
    DateTime? validFrom,
    DateTime? validUntil,
    List<AuditLog>? history,
  }) => DiscountGroup(
    storeNumber: storeNumber ?? this.storeNumber,
    id: id ?? this.id,
    name: name ?? this.name,
    transactionType: transactionType ?? this.transactionType,
    description: description ?? this.description,
    validFrom: validFrom ?? this.validFrom,
    validUntil: validUntil ?? this.validUntil,
    history: history ?? this.history,
  );

  @override
  List<Object?> get props => [
    id,
    storeNumber,
    name,
    transactionType,
    description,
    validFrom,
    validUntil,
    history,
  ];
}

/// Discount Rules/Entries
class DiscountRule {
  final String id;

  /// FK -> DiscountGroup.id
  final String discountGroupId;

  /// Optional FK -> PriceList.id
  final String? priceListId;

  /// Fixed or Percentage
  final DiscountType discountType;

  /// 10% OR 50 currency units
  final double discountValue;

  /// Quantity-based discounts
  /// Minimum quantity for this discount tier
  final int? minQuantity;

  /// Can this discount be combined with other discounts?
  final bool isStackable;
  final String? couponCode;

  /// Date validity
  final DateTime? validFrom;
  final DateTime? validUntil;

  final List<AuditLog> history;

  DiscountRule({
    required this.id,
    required this.priceListId,
    required this.discountGroupId,
    required this.discountValue,
    this.discountType = DiscountType.percentage,
    this.isStackable = false,
    this.minQuantity,
    this.couponCode,
    this.validFrom,
    this.validUntil,
    this.history = const [],
  });

  factory DiscountRule.fromMap(Map<String, dynamic> map, {String? id}) {
    return DiscountRule(
      id: id ?? map['id'] ?? '',
      isStackable: map['isStackable'] ?? false,
      priceListId: map['priceListId'] ?? '',
      discountGroupId: map['discountGroupId'] ?? '',
      discountType: DiscountTypeUtil.fromString(map['discountType']),
      discountValue: '${map['discountValue']}'.asDouble,
      couponCode: map['couponCode'] ?? '',
      minQuantity: '${map['minQuantity']}'.asInt,
      validFrom: toDateTimeFn(map['validFrom']),
      validUntil: toDateTimeFn(map['validUntil'], isNullable: true),
      history: AuditLog.auditLogs(map['history']),
    );
  }

  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'isStackable': isStackable,
    'priceListId': priceListId,
    'discountGroupId': discountGroupId,
    'discountType': getDiscountType,
    'discountValue': discountValue,
    'couponCode': couponCode,
    'minQuantity': minQuantity,
    'history': history.map((e) => e.toMap()).toList(),
  };

  String get getDiscountType => discountType.getName;

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
    var newMap = toMap();
    return {'id': id, 'data': newMap};
  }

  /// [empty] Empty DiscountRule object.
  static final DiscountRule empty = DiscountRule(
    id: '',
    priceListId: '',
    discountGroupId: '',
    discountValue: 0,
  );

  /// [isEmpty] Checks if the DiscountRule is empty.
  bool get isEmpty => identical(this, DiscountRule.empty);

  bool get isNotEmpty => !isEmpty;

  /// Filter/search
  bool filterByAny(String filter) => itemAsList.filterAny(filter);

  /// [findById] Find PriceList Entry by ID.
  static DiscountRule? findById(List<DiscountRule> items, String id) =>
      items.firstWhereOrNull((i) => i.id == id);

  static List<String> get dataTableHeader => const [
    'ID',
    'Type',
    'Coupon',
    'Discount Value',
    'Min Qty',
    'Stackable',
    'Valid From',
    'Valid Until',
  ];

  /// ToList for Price Entry [itemAsList]
  List<String> get itemAsList => [
    id,
    getDiscountType.toTitle,
    couponCode ?? '',
    discountValue.toString(),
    '${minQuantity ?? 0}',
    isStackable ? 'Yes' : 'No',
    getValidFrom,
    getValidUntil,
  ];

  static Map<String, dynamic> get templateHeader => empty.toMap();

  DiscountRule copyWith({
    String? id,
    DiscountType? discountType,
    bool? isStackable,
    String? priceListId,
    String? discountGroupId,
    double? discountValue,
    String? couponCode,
    int? minQuantity,
    DateTime? validFrom,
    DateTime? validUntil,
    List<AuditLog>? history,
  }) => DiscountRule(
    id: id ?? this.id,
    priceListId: priceListId ?? this.priceListId,
    discountGroupId: discountGroupId ?? this.discountGroupId,
    isStackable: isStackable ?? this.isStackable,
    discountType: discountType ?? this.discountType,
    discountValue: discountValue ?? this.discountValue,
    couponCode: couponCode ?? this.couponCode,
    minQuantity: minQuantity ?? this.minQuantity,
    validUntil: validUntil ?? this.validUntil,
    validFrom: validFrom ?? this.validFrom,
    history: history ?? this.history,
  );
}

/*class DiscountRule {
  final String id;

  /// FK -> DiscountGroup.id
  final String discountGroupId;

  /// Optional FK -> PriceList.id
  final String? priceListId;

  /// Fixed or Percentage
  final DiscountType discountType;

  /// 10% OR 50 currency units
  final double discountValue;

  /// Quantity-based discounts
  final int? minQuantity;

  /// Priority
  final int priority;

  /// Date validity
  final DateTime? validFrom;
  final DateTime? validUntil;

  final bool stackable;

  final List<AuditLog> history;
}*/
