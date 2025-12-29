import 'package:assign_erp/core/constants/item_category.dart';
import 'package:assign_erp/core/constants/line_item_type.dart';
import 'package:assign_erp/core/constants/unit_of_measure.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';

/// Taxable Line Item
mixin TaxableLineItem on LineItem {
  /*List<String> get taxCodes;
  double get taxAmount;*/

  double computeTaxAmount(Map<String, ResolveTaxCode> taxMap) {
    if (taxCodes.isEmpty || taxMap.isEmpty) return 0.0;

    final rate = taxCodes.fold(
      0.0,
      (sum, code) => sum + (taxMap[code]?.rate ?? 0.0),
    );
    return rate;
  }

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

  /// [PerLineTotal] Calculated total for a line item including tax and after discount.
  /// Derived as: `[perLineTotal = subTotal (subTotal - discountAmount) - discountAmount + taxAmount]`.
  @override
  double get totalWithTaxes => netBeforeTax + taxAmount;

  double totalWithTaxesUsing(Map<String, ResolveTaxCode> taxMap) =>
      netBeforeTax + computeTaxAmount(taxMap);
}

/// [LineItem] Represents a line item (e.g., product or service)
abstract class LineItem {
  static get _today => DateTime.now();

  final String id;
  final String notes;

  /// [discount] Discount is in percentage
  final double discount;
  final double quantity;
  final LineItemType type;
  final String description;

  /// [leadTimeDays] How long it take to get this line item?
  /// Used in PR, SO, SQ
  final double leadTimeDays;
  final ItemCategory category;

  /// [requiredDate] When do I need this line item?
  /// Used in PR, PO, SO, SQ
  final DateTime? requiredDate;
  final UnitOfMeasure unitOfMeasure;

  LineItem({
    this.id = '',
    this.notes = '',
    required this.type,
    this.discount = 0.0,
    this.leadTimeDays = 0.0,
    required this.quantity,
    required this.description,
    this.category = ItemCategory.unknown,
    this.unitOfMeasure = UnitOfMeasure.unknown,
    DateTime? requiredDate,
  }) : requiredDate = requiredDate ?? _today;

  /// Polymorphic getter — subclasses define actual unitPrice
  double get unitPrice;

  /// [subTotal] General total for all line types [unitPrice * quantity]
  double get subTotal => quantity * unitPrice;

  double get discountAmount => (subTotal * discount) / 100;

  /// [netBeforeTax] The amount after applying Discounts BUT before Taxes
  /// `[netBeforeTax/netPrice = subTotal - discountAmount]`
  double get netBeforeTax => subTotal - discountAmount;

  /// These are overridden in the subClass: MaterialLineItem & ServiceLineItem
  String get taxNames => '';

  double get taxAmount => 0.0;

  List<String> get taxCodes => const [];

  List<String> get itemAsList;

  List<String> get dataTableHeader;

  double get totalWithTaxes => netBeforeTax + taxAmount;

  String get getTypeLabel => type.getLabel.toTitle;

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

    final type = LineItemTypeHelper.fromString(typeStr.toLowerCase());

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
    'type': getTypeLabel,
    'description': description,
    'quantity': quantity,
    'category': getCategory,
    'unitOfMeasure': getUnitOfMeasure,
    'discount': discount,
    'notes': notes,
    'leadTimeDays': leadTimeDays,
    'requiredDate': isDate
        ? getRequiredDate
        : requiredDate?.millisecondsSinceEpoch,
  };

  /// Polymorphic cloning
  LineItem copyWith({
    List<String>? taxCodes,
    double? taxAmount,
    String? taxNames,
  });

  bool containsIgnoreCase(String a, String b) =>
      a.toLowerAll.contains(b.toLowerAll);

  bool filterByAny(String filter) =>
      {
        '$quantity',
        '$discount',
        '$quantity',
        '$leadTimeDays',
        getRequiredDate,
      }.contains(filter) ||
      containsIgnoreCase(description, filter) ||
      containsIgnoreCase(notes, filter) ||
      containsIgnoreCase(getCategory, filter) ||
      containsIgnoreCase(getUnitOfMeasure, filter) ||
      containsIgnoreCase(getTypeLabel, filter);

  /// [updateTax] Returns a new instance with updated tax info if applicable
  LineItem updateTax({required double taxAmount, required String taxNames}) {
    if (this is! TaxableLineItem) return this;

    return switch (this) {
      MaterialLineItem m => m.copyWith(
        taxAmount: taxAmount,
        taxNames: taxNames,
      ),
      ServiceLineItem s => s.copyWith(taxAmount: taxAmount, taxNames: taxNames),
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
    discount,
    notes,
    leadTimeDays,
    requiredDate,
  ];
}

/// [MaterialLineItem] Represents a material line item (e.g., product POs)
class MaterialLineItem extends LineItem with TaxableLineItem {
  final double _unitPrice;

  @override
  double get unitPrice => _unitPrice;

  @override
  final List<String> taxCodes;

  /// [taxNames] is a non-persistent, UI-only field derived from [taxCodes] using the tax map.
  /// This value is not saved in the database.
  @override
  final String taxNames;

  /// [taxAmount] is a non-persistent, computed value for UI display only.
  /// Calculated when [TaxMode.perLineTax] is used. Not stored in the database.
  @override
  final double taxAmount;

  MaterialLineItem({
    super.id,
    required super.description,

    /// [quantity] Represent the number of units of the material(Products)
    required super.quantity,
    super.category = ItemCategory.unknown,
    super.unitOfMeasure = UnitOfMeasure.unknown,
    super.discount,
    super.notes,
    double unitPrice = 0.0,
    this.taxCodes = const [],

    /// [taxAmount] UI-only, non-persistent value (per-line tax)
    this.taxAmount = 0.0,

    /// [taxNames] UI-only, non-persistent value (derived from tax codes)
    this.taxNames = '',
    super.leadTimeDays,
    super.requiredDate,
  }) : _unitPrice = unitPrice,
       super(type: LineItemType.material);

  factory MaterialLineItem.fromMap(Map<String, dynamic> map, {String? id}) =>
      MaterialLineItem(
        id: id ?? map['id'] ?? '',
        description: map['description'] ?? '',
        quantity: double.tryParse('${map['quantity']}') ?? 0,
        unitPrice: double.tryParse('${map['unitPrice']}') ?? 0.0,
        category: ItemCategoryHelper.fromString(map['category']),
        unitOfMeasure: UOMHelper.fromString(map['unitOfMeasure']),
        notes: map['notes'] ?? '',
        discount: double.tryParse('${map['discount']}') ?? 0.0,
        taxCodes: List<String>.from(
          map['taxCodes'] ?? [],
        ).whereType<String>().toList(),
        taxAmount: double.tryParse('${map['taxAmount']}') ?? 0.0,
        taxNames: map['taxNames'] ?? '',
        leadTimeDays: double.tryParse('${map['leadTimeDays']}') ?? 0.0,
        requiredDate: toDateTimeFn(map['requiredDate']),
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
      containsIgnoreCase(taxNames, filter) ||
      containsIgnoreCase('$taxAmount', filter) ||
      taxCodes.contains(filter);

  @override
  MaterialLineItem copyWith({
    String? id,
    String? description,
    double? quantity,
    ItemCategory? category,
    UnitOfMeasure? unitOfMeasure,
    double? unitPrice,
    String? notes,
    List<String>? taxCodes,

    /// [discount] Discount is in percentage
    double? discount,

    /// [taxAmount] For UI perLineTax (per item) tax amount only
    double? taxAmount,

    /// [taxNames] For UI tax names calculation only
    String? taxNames,
    double? leadTimeDays,
    DateTime? requiredDate,
  }) => MaterialLineItem(
    id: id ?? this.id,
    description: description ?? this.description,
    quantity: quantity ?? this.quantity,
    category: category ?? this.category,
    unitPrice: unitPrice ?? _unitPrice,
    unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
    notes: notes ?? this.notes,

    taxCodes: taxCodes ?? this.taxCodes,
    discount: discount ?? this.discount,

    taxAmount: taxAmount ?? this.taxAmount,
    taxNames: taxNames ?? this.taxNames,
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

  /// [subTotal] General total for all line types [unitPrice * quantity]
  @override
  double get subTotal => quantity * unitPrice;

  @override
  List<String> get itemAsList => [
    description.toTitle,
    '$quantity',
    getCategory.toTitle,
    getUnitOfMeasure.toTitle,
    getRequiredDate,
    notes.toSentence,
  ];

  /// For UI Header display only
  @override
  List<String> get dataTableHeader => [
    'Item',
    'Qty',
    'Category',
    'UOM',
    'Required Date',
    'Notes',
  ];

  @override
  List<Object?> get props => [
    ...super.props,
    unitPrice,
    taxCodes,
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

  /// [taxAmount] is a non-persistent, computed value for UI display only.
  /// Calculated when [TaxMode.perLineTax] is used. Not stored in the database.
  @override
  final double taxAmount;

  ServiceLineItem({
    super.id,
    required super.description,

    /// [quantity] Represent the number of hours or days, depending on the unit of measure
    required super.quantity,
    super.unitOfMeasure,
    super.category,
    super.discount,
    super.notes,
    this.serviceRate = 0.0,
    this.limitAmount,
    this.limitQuantity,
    this.taxCodes = const [],

    /// [taxAmount] UI-only, non-persistent value (per-line tax)
    this.taxAmount = 0.0,

    /// [taxNames] UI-only, non-persistent value (derived from tax codes)
    this.taxNames = '',
    super.leadTimeDays,
    super.requiredDate,
  }) : super(type: LineItemType.service);

  @override
  double get unitPrice => serviceRate;

  factory ServiceLineItem.fromMap(Map<String, dynamic> map, {String? id}) =>
      ServiceLineItem(
        id: id ?? map['id'] ?? '',
        description: map['description'] ?? '',
        quantity: double.tryParse('${map['quantity']}') ?? 0,
        unitOfMeasure: UOMHelper.fromString(map['unitOfMeasure']),
        category: ItemCategoryHelper.fromString(map['category']),
        serviceRate: double.tryParse('${map['serviceRate']}') ?? 0.0,
        limitAmount: double.tryParse('${map['limitAmount']}') ?? 0.0,
        limitQuantity: double.tryParse('${map['limitQuantity']}') ?? 0.0,
        notes: map['notes'] ?? '',
        discount: double.tryParse('${map['discount']}') ?? 0.0,
        taxCodes: List<String>.from(
          map['taxCodes'] ?? [],
        ).whereType<String>().toList(),
        taxAmount: double.tryParse('${map['taxAmount']}') ?? 0.0,
        taxNames: map['taxNames'] ?? '',
        leadTimeDays: double.tryParse('${map['leadTimeDays']}') ?? 0.0,
        requiredDate: toDateTimeFn(map['requiredDate']),
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
      containsIgnoreCase(taxNames, filter) ||
      {
        taxCodes,
        '$taxAmount',
        '$serviceRate',
        '$limitAmount',
        '$limitQuantity',
        '$requiredDate',
      }.contains(filter);

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

    /// [discount] Discount is in percentage
    double? discount,

    /// [taxAmount] For UI perLineTax (per item) tax amount only
    double? taxAmount,

    /// [taxNames] For UI tax names calculation only
    String? taxNames,
    double? leadTimeDays,
    DateTime? requiredDate,
  }) => ServiceLineItem(
    id: id ?? this.id,
    description: description ?? this.description,
    quantity: quantity ?? this.quantity,
    serviceRate: serviceRate ?? this.serviceRate,
    unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
    category: category ?? this.category,
    limitAmount: limitAmount ?? this.limitAmount,
    limitQuantity: limitQuantity ?? this.limitQuantity,
    taxCodes: taxCodes ?? this.taxCodes,
    discount: discount ?? this.discount,

    taxAmount: taxAmount ?? this.taxAmount,
    taxNames: taxNames ?? this.taxNames,
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
    if (limitQuantity == null) return 0;
    return (limitQuantity! - quantity).clamp(0, double.infinity);
  }

  @override
  List<String> get itemAsList => [
    description.toTitle,
    '$quantity',
    getUnitOfMeasure.toTitle,
    '$serviceRate',
    limitAmount != null ? 'Limit: $limitAmount' : '',
    limitQuantity != null ? 'Limit: $limitQuantity' : '',
    getRequiredDate,
    notes.toSentence,
  ];

  /// For UI Header display only
  @override
  List<String> get dataTableHeader => const [
    'Service',
    'Qty',
    'UOM',
    'Rate',
    'Limit Amount',
    'Limit Quantity',
    'Required Date',
    'Notes',
  ];

  @override
  List<Object?> get props => [
    ...super.props,
    serviceRate,
    limitAmount,
    limitQuantity,
    taxCodes,
    taxAmount,
    taxNames,
  ];
}

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
