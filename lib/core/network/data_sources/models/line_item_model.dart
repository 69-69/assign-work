import 'package:assign_erp/core/util/extensions/item_category.dart';
import 'package:assign_erp/core/util/extensions/line_item_type.dart';
import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/tax_model.dart';

/// Taxable Line Item
mixin TaxableLineItem on LineItem {
  /// Computes tax for this 'per line' item based on its tax codes.
  /// [computeTax] Returns a tuple:
  /// - `percent`: combined tax rate for the line
  /// - `amount`: tax amount for this line (`netAmount × percent`)
  ({double percent, double amount}) computeTax(
    Map<String, ResolveTaxCode> taxMap,
  ) {
    if (taxCodes.isEmpty || taxMap.isEmpty) return (percent: 0.0, amount: 0.0);

    // Summing up tax rates (Percent) based on tax codes.
    final percent = taxCodes.fold(
      0.0,
      (sum, code) => sum + (taxMap[code]?.rate ?? 0.0),
    );
    final amount = ((percent / 100) * netAmount).toPercent;

    return (percent: percent, amount: amount);
  }

  /// Return the names of all taxes applied to this 'per line' item.
  String buildTaxNames(
    Map<String, ResolveTaxCode> taxMap, {
    String separator = ', ',
  }) {
    if (taxCodes.isEmpty) return '';
    return taxCodes
        .map((code) => taxMap[code]?.taxLabel ?? 'N/A')
        .whereType<String>()
        .join(separator);
  }

  /// [PerLineTotal] Calculated total for a line item including tax & discount.
  @override
  double get totalWithTaxes => netAmount + taxAmount;
}

/// [LineItem] Represents a line item (e.g., product or service)
abstract class LineItem {
  final String id;
  final String notes;

  /// [discountPercent] Discount is in percentage
  final double discountPercent;
  final double quantity;
  final LineItemType type;
  final String description;

  /// [leadTimeDays] How long it take to get/fulfill this line item?
  /// Used in PR, SO, SQ
  final int leadTimeDays;
  final ItemCategory category;

  /// [requiredDate] When do I need this line item?
  /// Used in PR, PO, SO, SQ
  final DateTime? requiredDate;
  final UnitOfMeasure unitOfMeasure;

  LineItem({
    this.id = '',
    this.notes = '',
    required this.type,
    this.discountPercent = 0.0,
    this.leadTimeDays = 0,
    required this.quantity,
    required this.description,
    this.category = ItemCategory.unknown,
    this.unitOfMeasure = UnitOfMeasure.unknown,
    this.requiredDate,
  });

  /// Polymorphic getter — subclasses define actual unitPrice
  double get unitPrice;

  /// 1. [grossAmount] Total 'Per Line' amount before discounts, tax, or additional charges.
  /// Calculated as unitPrice × quantity.
  double get grossAmount => quantity * unitPrice;

  /// 2. [discountAmount] — The discount applied to this line item.
  ///
  /// Calculated as a percentage of the [grossAmount]:
  /// ```dart
  /// discountAmount = grossAmount * (discountPercent / 100)
  /// ```
  ///
  /// Constraints:
  /// - Clamped to a minimum of 0 (negative discounts are ignored)
  /// - Clamped to a maximum of [grossAmount] (cannot exceed total line value)
  ///
  /// This value is subtracted from [grossAmount] to compute [netAmount] before taxes.
  // double get discountAmount => (grossAmount * discountPercent) / 100;
  double get discountAmount =>
      (grossAmount * (discountPercent / 100)).clamp(0, grossAmount);

  /// 3. [netAmount] or [SubTotal] or [netPrice]
  /// 'Per Line' amount after discount, before tax and shipping.
  double get netAmount => grossAmount - discountAmount;

  /// [taxNames] 'Per Line' Tax names derived from tax codes.
  String get taxNames => '';

  /// [taxPercent] Percentage of tax applied 'Per Line' item
  double get taxPercent => 0.0;

  /// [taxAmount] Derived from taxPercent: Amount of tax applied 'Per Line' item
  double get taxAmount => 0.0;

  List<String> get taxCodes => const [];

  List<String> itemAsList([bool isPerLine = false]);

  List<String> dataTableHeader([bool isPerLine = false]);

  double get totalWithTaxes => netAmount + taxAmount;

  String get getType => type.getLabel.toTitle;

  String get getCategory => category.getLabel;

  String get getUnitOfMeasure => unitOfMeasure.getLabel;

  String get getRequiredDate => requiredDate.dateOnly;

  /*=> type == LineItemType.material
      ? MaterialLineItem.getDataTableHeader
      : ServiceLineItem.getDataTableHeader;*/

  /// Factory to rebuild correct subclass
  factory LineItem.fromMap(
    Map<String, dynamic> map, {
    String? lineType,
    String? id,
  }) {
    final typeStr = lineType ?? map['type'];
    if (typeStr == null) {
      throw ArgumentError("Missing 'type' for Line-Item");
    }

    final type = LineItemTypeUtil.fromString(typeStr.toLowerCase());

    return switch (type) {
      LineItemType.material => MaterialLineItem.fromMap(map, id: id),
      LineItemType.service => ServiceLineItem.fromMap(map, id: id),
    };
  }

  /// [lineItems] Converts a list of maps from the provided [map] under the given [key] into a list of [LineItem] objects.
  static List<LineItem> lineItems(List<dynamic>? map) {
    return map
            ?.map((i) => LineItem.fromMap(Map<String, dynamic>.from(i)))
            .toList() ??
        [];
  }

  /// [toMap] Polymorphic serialization
  /// if [isDate] is true, convert millisecondsSinceEpoch to DateTime, else keep as is
  Map<String, dynamic> toMap([bool isDate = false]) => {
    'id': id,
    'type': getType,
    'description': description,
    'quantity': quantity,
    'category': getCategory,
    'unitOfMeasure': getUnitOfMeasure,
    'discountPercent': discountPercent,
    'notes': notes,
    'leadTimeDays': leadTimeDays,
    'requiredDate': isDate ? getRequiredDate : requiredDate?.toMilliseconds,
  };

  /// Polymorphic cloning
  LineItem copyWith({
    List<String>? taxCodes,
    double? taxAmount,
    String? taxNames,
  });

  /// Filter/Search
  bool filterByAny(String filter) => {
    '$quantity',
    '$discountPercent',
    '$quantity',
    '$leadTimeDays',
    getRequiredDate,
    description,
    notes,
    getCategory,
    getUnitOfMeasure,
    getType,
  }.filterAny(filter);

  /// [updateLineTax] Returns a new instance with updated tax info if applicable
  LineItem updateLineTax({
    required double taxPercent,
    required double taxAmount,
    required String taxNames,
  }) {
    if (this is! TaxableLineItem) return this;

    return switch (this) {
      MaterialLineItem m => m.copyWith(
        taxPercent: taxPercent,
        taxAmount: taxAmount,
        taxNames: taxNames,
      ),
      ServiceLineItem s => s.copyWith(
        taxPercent: taxPercent,
        taxAmount: taxAmount,
        taxNames: taxNames,
      ),
      _ => this, // fallback for unknown TaxableLineItem subclasses
    };
  }

  /// Common props (if using Equatable)
  List<Object?> get props => [
    id,
    type,
    description,
    quantity,
    category,
    unitOfMeasure,
    discountPercent,
    notes,
    leadTimeDays,
    requiredDate,
  ];
}

/// [MaterialLineItem] Represents a material/product line item (e.g., product POs)
class MaterialLineItem extends LineItem with TaxableLineItem {
  final double _unitPrice;

  @override
  final List<String> taxCodes;

  /// [taxNames] is a non-persistent, UI-only field derived from [taxCodes] using the tax map.
  /// This value is not saved in the database.
  @override
  final String taxNames;

  /// [taxPercent] & [taxAmount]is a non-persistent, computed value for UI display only.
  /// Calculated when [TaxMode.perLineTax] is used. Not stored in the database.
  @override
  final double taxPercent;
  @override
  final double taxAmount; // Derived from taxPercent

  MaterialLineItem({
    super.id,
    required super.description,

    /// [quantity] Represent the number of units of the material(Products)
    required super.quantity,
    super.unitOfMeasure,
    super.category,
    super.discountPercent,
    super.notes,
    super.leadTimeDays,
    super.requiredDate,
    double unitPrice = 0.0,
    this.taxCodes = const [],

    /// [taxPercent] & [taxAmount] UI-only, non-persistent value (per-line tax)
    this.taxAmount = 0.0,
    this.taxPercent = 0.0,

    /// [taxNames] UI-only, non-persistent value (derived from tax codes)
    this.taxNames = '',
  }) : _unitPrice = unitPrice,
       super(type: LineItemType.material);

  @override
  double get unitPrice => _unitPrice;

  factory MaterialLineItem.fromMap(Map<String, dynamic> map, {String? id}) =>
      MaterialLineItem(
        id: id ?? map['id'] ?? '',
        description: map['description'] ?? '',
        quantity: '${map['quantity']}'.asDouble,
        unitPrice: '${map['unitPrice']}'.asDouble,
        unitOfMeasure: UOMUtil.fromString(map['unitOfMeasure']),
        category: ItemCategoryUtil.fromString(map['category']),
        discountPercent: '${map['discountPercent']}'.asDouble,
        taxCodes: List<String>.from(
          map['taxCodes'] ?? [],
        ).whereType<String>().toList(),
        taxAmount: '${map['taxAmount']}'.asDouble,
        taxPercent: '${map['taxPercent']}'.asDouble,
        taxNames: map['taxNames'] ?? '',
        leadTimeDays: '${map['leadTimeDays']}'.asInt,
        requiredDate: map['requiredDate'] != null
            ? toDateTimeFn(map['requiredDate'])
            : null,
        notes: map['notes'] ?? '',
      );

  @override
  Map<String, dynamic> toMap([bool isDate = false]) {
    final map = {
      ...super.toMap(isDate),
      'unitPrice': unitPrice,
      'taxCodes': taxCodes,
    };

    // Remove key-pair if value is null or empty
    return map.cleaned;
  }

  @override
  bool filterByAny(String filter) =>
      super.filterByAny(filter) ||
      taxCodes.filterAny(filter) ||
      {'$unitPrice', taxNames, '$taxAmount'}.filterAny(filter);

  @override
  MaterialLineItem copyWith({
    String? id,
    String? description,
    double? quantity,
    double? unitPrice,
    ItemCategory? category,
    UnitOfMeasure? unitOfMeasure,
    List<String>? taxCodes,
    String? notes,

    /// [discountPercent] Discount is in percentage
    double? discountPercent,

    /// [taxPercent] & [taxAmount] For UI perLineTax (per item) tax amount only
    double? taxAmount,
    double? taxPercent,

    /// [taxNames] For UI tax names calculation only
    String? taxNames,
    int? leadTimeDays,
    DateTime? requiredDate,
  }) => MaterialLineItem(
    id: id ?? this.id,
    description: description ?? this.description,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? _unitPrice,
    category: category ?? this.category,
    unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
    notes: notes ?? this.notes,

    taxCodes: taxCodes ?? this.taxCodes,
    taxNames: taxNames ?? this.taxNames,
    taxAmount: taxAmount ?? this.taxAmount,
    taxPercent: taxPercent ?? this.taxPercent,
    discountPercent: discountPercent ?? this.discountPercent,

    leadTimeDays: leadTimeDays ?? this.leadTimeDays,
    requiredDate: requiredDate ?? this.requiredDate,
  );

  /// A singleton instance representing an empty/default MaterialLineItem.
  /// Used as a fallback when no matching PR is found.
  static final MaterialLineItem empty = MaterialLineItem(
    description: '',
    quantity: 0,
    unitPrice: 0.0,
  );

  /// Returns true if this instance is the singleton [empty] PR.
  /// Use this to check if the PR is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, MaterialLineItem.empty);

  bool get isNotEmpty => !isEmpty;

  /// [grossAmount] General total for all line types [unitPrice * quantity]
  @override
  double get grossAmount => quantity * unitPrice;

  @override
  List<String> itemAsList([bool isPerLine = false]) => [
    description.toTitle,
    '$quantity',
    if (unitPrice > 0) '$unitPrice',
    getUnitOfMeasure.toTitle,
    getCategory.toTitle,
    getRequiredDate,
    if (leadTimeDays > 0) '$leadTimeDays day(s)',
    // If TaxMode is perLineTax, show line table, else show elsewhere
    if (taxNames.isNotEmpty && isPerLine) ...[taxNames.toTitle, '$taxAmount'],
    if (discountPercent > 0) '$discountPercent%',
    if (notes.isNotEmpty) notes.toSentence,
  ];

  /// For UI Header display only
  @override
  List<String> dataTableHeader([bool isPerLine = false]) => [
    'Item',
    'Qty',
    if (unitPrice > 0) 'Unit Price',
    'UOM',
    'Category',
    'Required Date',
    if (leadTimeDays > 0) 'Lead Time (Days)',
    // If TaxMode is perLineTax, show line table, else show elsewhere
    if (taxNames.isNotEmpty && isPerLine) ...{'Tax Names', 'Tax Amount'},
    if (discountPercent > 0) 'Discount %',
    if (notes.isNotEmpty) 'Notes',
  ];

  @override
  List<Object?> get props => [
    ...super.props,
    unitPrice,
    taxCodes,
    taxPercent,
    taxAmount,
    taxNames,
  ];
}

/// [ServiceLineItem] Represents a service line item (e.g., service POs)
class ServiceLineItem extends LineItem with TaxableLineItem {
  final double serviceRate;

  /// Use Case [limitAmount]:
  /// Imagine a service contract where a vendor will provide consulting services, but the total
  /// value for the service cannot exceed $10,000. In this case, the limitAmount would be set to $10,000.
  /// If the service rate is $500 per day, and the service is billed daily,
  /// you can calculate how many days can be billed before the limit is reached.
  final double? limitAmount;

  /// Use Case [limitQuantity]:
  /// A service agreement states that the vendor will provide maintenance for up to 100 hours.
  /// In this case, the limitQuantity would be set to 100 hours.
  /// If the service is billed based on the number of hours worked,
  /// once the limitQuantity is reached, no more service can be provided under that PO.
  final double? limitQuantity;

  @override
  final List<String> taxCodes;

  /// [taxNames] is a non-persistent, UI-only field derived from [taxCodes] using the tax map.
  /// This value is not saved in the database.
  @override
  final String taxNames;

  /// [taxPercent] & [taxAmount]is a non-persistent, computed value for UI display only.
  /// Calculated when [TaxMode.perLineTax] is used. Not stored in the database.
  @override
  final double taxPercent;
  @override
  final double taxAmount; // Derived from taxPercent

  ServiceLineItem({
    super.id,
    required super.description,

    /// [quantity] Represent the number of hours or days, depending on the unit of measure
    required super.quantity,
    super.unitOfMeasure,
    super.category,
    super.discountPercent,
    super.notes,
    super.leadTimeDays,
    super.requiredDate,
    this.serviceRate = 0.0,
    this.limitAmount,
    this.limitQuantity,
    this.taxCodes = const [],

    /// [taxPercent] & [taxAmount] UI-only, non-persistent value (per-line tax)
    this.taxAmount = 0.0,
    this.taxPercent = 0.0,

    /// [taxNames] UI-only, non-persistent value (derived from tax codes)
    this.taxNames = '',
  }) : super(type: LineItemType.service);

  @override
  double get unitPrice => serviceRate;

  factory ServiceLineItem.fromMap(Map<String, dynamic> map, {String? id}) =>
      ServiceLineItem(
        id: id ?? map['id'] ?? '',
        description: map['description'] ?? '',
        quantity: '${map['quantity']}'.asDouble,
        serviceRate: '${map['serviceRate']}'.asDouble,
        unitOfMeasure: UOMUtil.fromString(map['unitOfMeasure']),
        category: ItemCategoryUtil.fromString(map['category']),
        limitAmount: '${map['limitAmount']}'.asDouble,
        limitQuantity: '${map['limitQuantity']}'.asDouble,
        discountPercent: '${map['discountPercent']}'.asDouble,
        taxCodes: List<String>.from(
          map['taxCodes'] ?? [],
        ).whereType<String>().toList(),
        taxAmount: '${map['taxAmount']}'.asDouble,
        taxPercent: '${map['taxPercent']}'.asDouble,
        taxNames: map['taxNames'] ?? '',
        leadTimeDays: '${map['leadTimeDays']}'.asInt,
        requiredDate: map['requiredDate'] != null
            ? toDateTimeFn(map['requiredDate'])
            : null,
        notes: map['notes'] ?? '',
      );

  @override
  Map<String, dynamic> toMap([bool isDate = false]) {
    final map = {
      ...super.toMap(isDate),
      'serviceRate': serviceRate,
      'limitAmount': limitAmount,
      'limitQuantity': limitQuantity,
      'taxCodes': taxCodes,
    };

    // Remove key-pair if value is null or empty
    return map.cleaned;
  }

  @override
  bool filterByAny(String filter) =>
      super.filterByAny(filter) ||
      taxCodes.filterAny(filter) ||
      {
        taxCodes,
        taxNames,
        '$taxAmount',
        '$taxPercent',
        '$serviceRate',
        '$limitAmount',
        '$limitQuantity',
        '$requiredDate',
      }.filterAny(filter);

  @override
  ServiceLineItem copyWith({
    String? id,
    String? description,
    double? quantity,
    double? serviceRate,
    double? limitAmount,
    double? limitQuantity,
    ItemCategory? category,
    UnitOfMeasure? unitOfMeasure,
    List<String>? taxCodes,
    String? notes,

    /// [discountPercent] Discount is in percentage
    double? discountPercent,

    /// [taxPercent] & [taxAmount] For UI perLineTax (per item) tax amount only
    double? taxAmount,
    double? taxPercent,

    /// [taxNames] For UI tax names calculation only
    String? taxNames,
    int? leadTimeDays,
    DateTime? requiredDate,
  }) => ServiceLineItem(
    id: id ?? this.id,
    description: description ?? this.description,
    quantity: quantity ?? this.quantity,
    serviceRate: serviceRate ?? this.serviceRate,
    category: category ?? this.category,
    unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
    limitAmount: limitAmount ?? this.limitAmount,
    limitQuantity: limitQuantity ?? this.limitQuantity,
    notes: notes ?? this.notes,

    taxCodes: taxCodes ?? this.taxCodes,
    taxNames: taxNames ?? this.taxNames,
    taxAmount: taxAmount ?? this.taxAmount,
    taxPercent: taxPercent ?? this.taxPercent,
    discountPercent: discountPercent ?? this.discountPercent,

    leadTimeDays: leadTimeDays ?? this.leadTimeDays,
    requiredDate: requiredDate ?? this.requiredDate,
  );

  /// A singleton instance representing an empty/default ServiceLine.
  /// Used as a fallback when no matching service line is found.
  static final ServiceLineItem empty = ServiceLineItem(
    description: '',
    quantity: 0,
  );

  /// Returns true if this instance is the singleton [empty] ServiceLine.
  bool get isEmpty => identical(this, ServiceLineItem.empty);

  bool get isNotEmpty => !isEmpty;

  /// Calculate how many days can be billed
  int get maxDays {
    if (limitAmount == null || serviceRate == 0) return 0;
    return (limitAmount! / serviceRate).floor();
  }

  /// Calculate remaining hours
  double get remainingHours {
    if (limitQuantity == null || quantity == 0) return 0;
    return (limitQuantity! - quantity).clamp(0, double.infinity);
  }

  @override
  List<String> itemAsList([bool isPerLine = false]) => [
    description.toTitle,
    '$quantity',
    getUnitOfMeasure.toTitle,
    if (serviceRate > 0) '$serviceRate',
    if ((limitAmount ?? 0) > 0) '$limitAmount',
    if ((limitQuantity ?? 0) > 0) '$limitQuantity',
    getRequiredDate,
    if (leadTimeDays > 0) '$leadTimeDays day(s)',
    // If TaxMode is perLineTax, show line table, else show elsewhere
    if (taxNames.isNotEmpty && isPerLine) ...[taxNames.toTitle, '$taxAmount'],
    if (discountPercent > 0) '$discountPercent%',
    if (notes.isNotEmpty) notes.toSentence,
  ];

  /// For UI Header display only
  @override
  List<String> dataTableHeader([bool isPerLine = false]) => [
    'Service',
    'Qty',
    'UOM',
    if (serviceRate > 0) 'Rate',
    if ((limitAmount ?? 0) > 0) 'Limit Amount',
    if ((limitQuantity ?? 0) > 0) 'Limit Quantity',
    'Required Date',
    if (leadTimeDays > 0) 'Lead Time (Days)',
    // If TaxMode is perLineTax, show line table, else show elsewhere
    if (taxNames.isNotEmpty && isPerLine) ...{'Tax Names', 'Tax Amount'},
    if (discountPercent > 0) 'Discount %',
    if (notes.isNotEmpty) 'Notes',
  ];

  @override
  List<Object?> get props => [
    ...super.props,
    serviceRate,
    limitAmount,
    limitQuantity,
    taxCodes,
    taxPercent,
    taxAmount,
    taxNames,
  ];
}

/* Assumptions (typical ERP setup)

* Prices are **tax-exclusive**
* **Discount applies to item lines only**
* **Shipping is taxable**
* Tax is calculated **after discount**
* Tax rate = **3.5%**

---

## Given

* Unit Price = **100**
* Quantity = **3**
* Discount = **12%**
* Shipping = **90**
* Tax = **3.5%**

---------------------------
## Step-by-step calculation
---------------------------

### 1. Gross item amount
-> 100 × 3 = 300

### 2. Discount amount
-> 12% of 300 = 36

### 3. Subtotal (after discount)
-> 300 − 36 = 264

### 4. Net price (items + shipping, before tax)
-> 264 + 90 = 354

### 5. Tax amount:
-> 3.5% of 354 = 12.39

### 6. Grand total:
-> 354 + 12.39 = 366.39

## Final values summary

| Field                        | Amount     |
| ---------------------------- | ---------- |
| Gross Item Amount            | 300.00     |
| Discount Amount              | 36.00      |
| Subtotal (after discount)    | 264.00     |
| Shipping                     | 90.00      |
| **Net Total (taxable base)** | **354.00** |
| Tax Amount (3.5%)            | **12.39**  |
| **Grand Total**              | **366.39** |

---

## Extra (often stored in ERP)

* **Net unit price after discount**
-> 264 ÷ 3 = 88

## Important ERP variations (can change results)

* Shipping **non-taxable**
* Tax calculated **only on items**
* Discount applied **after tax**
* Line-level vs document-level rounding*/

/*final updatedItems = lineItems.map((item) {
      // Tax rate is in Percentage
      final taxRate = item.resolvePerItemTaxes(taxMap);
      final taxAmount = (item.netPrice * taxRate) / 100;
      final taxNames = item.getTaxName(taxMap);

      return item.copyWith(taxAmount: taxAmount, taxNames: taxNames);
    }).toList();

    return copyWith(lineItems: updatedItems);*/

/*if (taxMode == taxModeToApply.perLineTax) {
      // Calculate tax amounts for each line item (perLineTax)
      final updatedItems = lineItems.map((item) {
        // Tax rate is in Percentage
        final taxRate = item.resolvePerItemTaxes(taxMap);
        final taxAmount = (item.netPrice * taxRate) / 100;
        final taxNames = item.getTaxName(taxMap);

        return item.copyWith(taxAmount: taxAmount, taxNames: taxNames);
      }).toList();

      return copyWith(lineItems: updatedItems);
    } else {
      // Calculate total tax amount (headerTax/overall tax)
      final taxRate = resolveHeaderTaxes(taxMap);
      final totalTax = lineItems.fold(0.0, (sum, item) {
        final taxAmount = sum + ((item.netPrice * taxRate) / 100);
        return taxAmount;
      });

      return copyWith(headerTaxAmount: totalTax, taxNames: getTaxName(taxMap));
    }*/

/* Example:
class PurchaseOrder {
  final String poNumber;
  final List<PurchaseOrderLineItem> lineItems;

  const PurchaseOrder({
    required this.poNumber,
    required this.lineItems,
  });

  double get totalAmount =>
      lineItems.fold(0, (sum, item) => sum + item.total);

  double get totalTaxes {
    double sum = 0;
    for (var item in lineItems) {
      if (item is TaxableLineItem) {
        sum += item.taxAmount;
      }
    }
    return sum;
  }

  double get totalWithTaxes {
    double sum = 0;
    for (var item in lineItems) {
      if (item is CommercialLineCalculations) {
        sum += item.totalWithTaxes;
      } else {
        sum += item.total;
      }
    }
    return sum;
  }
}

void main() {
  final taxMap = {
    'VAT': ResolveTaxCode(name: 'VAT', rate: 0.15),
    'NHIL': ResolveTaxCode(name: 'NHIL', rate: 0.025),
  };

  final po = PurchaseOrder(
    poNumber: 'PO-0012',
    lineItems: [
      MaterialLineItem(
        description: "Laptop",
        quantity: 2,
        unitPrice: 1500,
        unitOfMeasure: UnitOfMeasure.pieces,
        taxCodes: ['VAT', 'NHIL'],
        discount: 10,
      ),
      ServiceLineItem(
        description: "Installation Service",
        category: ItemCategory.itEquipment,
        quantity: 1,
        serviceRate: 300,
        unitOfMeasure: UnitOfMeasure.hour,
        taxCodes: ['VAT'],
      ),
    ],
  );

  po.lineItems.map((item) {
    if (item is TaxableLineItem) {
      print('${item.description} Tax: ${item.computeTaxAmount(taxMap)}');
      print('${item.description} Discount: ${item.discountAmount}');

    }
  }

  for (var line in po.lineItems) {
    if (line is TaxableLineItem) {
      print('${line.description} Tax: ${line.computeTaxAmount(taxMap)}');
      print('${line.description} Discount: ${line.discountAmount}');
    }
  }

  print('PO Total: ${po.totalAmount}');
  print('PO Total with Taxes: ${po.totalWithTaxes}');
}*/

/*// OLD: [ProLineItem] Represents an individual line item in Procurement
class ProLineItem extends Equatable {
  final int quantity;
  final String description;
  final ItemCategory category;
  final UnitOfMeasure unitOfMeasure;
  final String notes;

  const ProLineItem({
    required this.description,
    required this.quantity,
    this.category = ItemCategory.unknown,
    this.unitOfMeasure = UnitOfMeasure.unknown,
    this.notes = '',
  });

  factory ProLineItem.fromMap(Map<String, dynamic> map) {
    return ProLineItem(
      description: map['description'] ?? '',
      quantity: int.tryParse('${map['quantity']}') ?? 0,
      category: ItemCategoryHelper.fromString(map['category']),
      unitOfMeasure: UOMHelper.fromString(map['unitOfMeasure']),
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'description': description,
    'quantity': quantity,
    'category': getCategory,
    'unitOfMeasure': getUnitOfMeasure,
    'notes': notes,
  };

  bool filterByAny(String filter) =>
      description.contains(filter) || notes.contains(filter);

  ProLineItem copyWith({
    String? description,
    int? quantity,
    String? notes,
    ItemCategory? category,
    UnitOfMeasure? unitOfMeasure,
  }) => ProLineItem(
    description: description ?? this.description,
    quantity: quantity ?? this.quantity,
    notes: notes ?? this.notes,
    category: category ?? this.category,
    unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
  );

  /// A singleton instance representing an empty/default ProLineItem.
  /// Used as a fallback when no matching PR is found.
  static final ProLineItem empty = ProLineItem(description: '', quantity: 0);

  /// Returns true if this instance is the singleton [empty] PR.
  /// Use this to check if the PR is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, ProLineItem.empty);

  bool get isNotEmpty => description.isNotEmpty;

  String get getCategory => category.getLabel;

  String get getUnitOfMeasure => unitOfMeasure.getLabel;

  List<String> get itemAsList => [
    description.toTitle,
    '$quantity',
    getCategory.toTitle,
    getUnitOfMeasure.toTitle,
    notes.toSentence,
  ];

  /// For UI Header display only
  static List<String> get dataTableHeader => const [
    'Item',
    'Qty',
    'Category',
    'Unit Of Measure',
    'Notes',
  ];

  @override
  List<Object?> get props => [
    description,
    quantity,
    category,
    unitOfMeasure,
    notes,
  ];

  /// [computeLineTaxAmount] Resolves the total tax amount for the current RFQ line item based on the provided tax rate map.
  ///
  /// This method takes a map of tax codes and their associated tax rates (`taxMap`), and calculates the total tax
  /// for this line item by summing up the tax rates corresponding to the `taxCodes` associated with the line item.
  ///
  /// The tax rate for each code is fetched from the `taxMap`. If a tax code is not found in the map, a default value
  /// of `0.0` is used (i.e., no tax is applied for that code).
  ///
  /// Example:
  /// Given the taxCodes `['VAT', 'Service']` and a taxMap that looks like:
  /// ```dart
  /// {'VAT': 0.15, 'Service': 0.02}
  /// ```
  /// The resulting tax amount would be:
  /// `0.15 + 0.02 = 0.17`.
  ///
  /// If the `taxMap` contains codes that are not in `taxCodes`, they will be ignored.
  /// If no tax codes are provided, the total tax is `0.0`.
  ///
  /// Args:
  ///   taxMap: A map of tax codes to tax rates. For example: `{'VAT': 0.15, 'Service': 0.05}`.
  ///
  /// Returns:
  ///   A double value representing the total tax amount for the line item based on the tax codes and rates.
  double computeLineTaxAmount(
    List<String> taxCodes,
    Map<String, ResolveTaxCode> taxMap,
  ) {
    if (taxCodes.isEmpty || taxMap.isEmpty) return 0.0;

    // Summing up tax rates based on tax codes.
    // If a tax code is missing from the map, a rate of 0.0 is used.
    final rate = taxCodes.fold(
      0.0,
      (sum, code) => sum + (taxMap[code]?.rate ?? 0.0),
    );
    return rate;
  }

  String buildTaxNames(
    List<String> taxCodes,
    Map<String, ResolveTaxCode> taxMap, [
    String separator = ', ',
  ]) {
    if (taxCodes.isEmpty || taxMap.isEmpty) return '';

    return taxCodes
        .map((code) => taxMap[code]?.taxLabel ?? 'N/A')
        .whereType<String>()
        .join(separator);
  }
}*/
