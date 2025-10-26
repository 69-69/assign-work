import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/tax_mode.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:equatable/equatable.dart';

var _today = DateTime.now(); /*.millisecondsSinceEpoch.toString()*/

/// @TODO request for quotation fields
// * Terms & conditions
// * List of invited suppliers
// * Attachments (drawings/specs)
// * Responses (linked or stored in sub-table)

class RequestForQuote extends Equatable {
  final String id;

  /// [prId] FOREIGN KEY: Purchase Requisition ID - Used to link RFQ to PR
  final String prId;

  final String storeNumber;
  final String rfqNumber;
  final String supplierId;

  /// Supplier representative (Contact Person) ID
  final String supplierRepId;
  final String status;

  final String title;
  final String currency;
  final String department;

  final List<RFQLineItem> lineItems;
  final TaxMode taxMode;
  // final List<String> taxCodes;
  final String paymentTerm;
  final String? deliveryAddress;
  final String? notes;
  final String validityDate;
  final DateTime? deadline;
  final DateTime? deliveryDate;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  /// [headerTaxAmount] is a non-persistent, computed value used for UI display only
  /// when [TaxMode.headerTax] is applied. This value is not stored in the database.
  // final double headerTaxAmount;

  /// [taxNames] is a non-persistent, computed field used solely for UI display.
  /// It is derived from [taxCodes] and the tax map. Not stored in the database.
  // final String taxNames;

  RequestForQuote({
    this.id = '',
    this.prId = '',
    required this.title,
    this.rfqNumber = '',
    required this.storeNumber,
    required this.supplierId,
    required this.supplierRepId,
    required this.status,
    this.taxMode = TaxMode.perLineTax,
    // this.taxCodes = const [],
    required this.lineItems,
    this.paymentTerm = '',
    required this.department,
    this.notes,
    this.validityDate = '',
    this.currency = ghanaCedis,
    this.deliveryAddress = '',
    DateTime? deadline,
    DateTime? deliveryDate,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : deadline = deadline ?? _today,
       deliveryDate = deliveryDate ?? _today,
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory RequestForQuote.fromMap(Map<String, dynamic> map, {String? docId}) {
    return RequestForQuote(
      id: docId ?? map['id'] ?? '',
      prId: map['prId'] ?? '', // Foreign key
      title: map['title'] ?? '',
      department: map['department'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      rfqNumber: map['rfqNumber'] ?? '',
      supplierId: map['supplierId'] ?? '',
      supplierRepId: map['supplierRepId'] ?? '',
      status: map['status'] ?? '',
      lineItems:
          (map['lineItems'] as List<dynamic>?)
              ?.map((i) => RFQLineItem.fromMap(Map<String, dynamic>.from(i)))
              .toList() ??
          [],
      notes: map['notes'],
      taxMode: TaxModeHelper.fromString(map['taxMode'] ?? TaxMode.perLineTax),
      paymentTerm: map['paymentTerm'] ?? '',
      // taxCodes: List<String>.from(data['taxCodes'] ?? []),
      deadline: toDateTimeFn(map['deadline']),
      deliveryDate: toDateTimeFn(map['deliveryDate']),
      validityDate: map['validityDate'] ?? '',
      currency: map['currency'] ?? '',
      deliveryAddress: map['deliveryAddress'],
      createdBy: map['createdBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt'] ?? '$_today'),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(map['updatedAt'] ?? '$_today'),
    );
  }

  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'prId': prId,
    'title': title,
    'department': department,
    'storeNumber': storeNumber,
    'rfqNumber': rfqNumber,
    'supplierId': supplierId,
    'lineItems': lineItems.map((item) => item.toMap()).toList(),
    'status': status,
    'notes': notes,
    // 'taxCodes': taxCodes,
    'taxMode': taxMode.getValue,
    'paymentTerm': paymentTerm,
    'deadline': deadline,
    'deliveryDate': deliveryDate,
    'validityDate': validityDate,
    'currency': currency,
    'deliveryAddress': deliveryAddress,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt,
  };

  Map<String, dynamic> toMap() {
    final newMap = _mapTemp();
    newMap['deadline'] = deadline?.toISOString;
    newMap['deliveryDate'] = deliveryDate?.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;
    return newMap;
  }

  Map<String, dynamic> toCache() {
    final newMap = _mapTemp();
    newMap['deadline'] = deadline?.millisecondsSinceEpoch;
    newMap['deliveryDate'] = deliveryDate?.millisecondsSinceEpoch;
    newMap['createdAt'] = createdAt.millisecondsSinceEpoch;
    newMap['updatedAt'] = updatedAt.millisecondsSinceEpoch;
    return {'id': id, 'data': newMap};
  }

  /*double resolveHeaderTaxes(Map<String, ResolveTaxCode> taxMap) =>
      _resolveTaxes(taxCodes, taxMap);

  String getTaxName(Map<String, ResolveTaxCode> taxMap) =>
      _getTaxName(taxCodes, taxMap);*/

  double get subTotal =>
      lineItems.fold(0.0, (sum, item) => sum + item.subTotal);

  double get discountAmount =>
      lineItems.fold(0.0, (sum, item) => sum + item.discountAmount);

  double get taxAmount =>
      lineItems.fold(0.0, (sum, item) => sum + item.taxAmount);
  // taxMode.isHeaderTax ? headerTaxAmount : lineItems.fold(0.0, (sum, item) => sum + item.taxAmount);

  // subTotal - discountAmount;
  double get netTotal => subTotal - discountAmount + taxAmount;

  /// A singleton instance representing an empty/default RequestForQuote.
  /// Used as a fallback when no matching RFQ is found.
  static final empty = RequestForQuote(
    id: '',
    prId: '',
    title: '',
    storeNumber: '',
    supplierId: '',
    supplierRepId: '',
    status: '',
    department: '',
    createdBy: '',
    lineItems: const [],
  );

  /// Returns true if this instance is the singleton [empty] RFQ.
  /// Use this to check if the RFQ is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, RequestForQuote.empty);

  bool get isNotEmpty => lineItems.isNotEmpty;
  bool get isAwarded => status == 'awarded';

  String get getDeliveryDate => deliveryDate.dateOnly;
  String get getValidityDate =>
      (int.tryParse(validityDate.split(' ').first)?.toDate).dateOnly;
  String get getDeadlineDate => deadline.dateOnly;
  String get getCreatedAt => createdAt.toStandardDT;
  String get getUpdatedAt => updatedAt.toStandardDT;

  bool get isToday {
    final dt = createdAt.toDateTime;
    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  bool filterByAny(String filter) =>
      prId.contains(filter) ||
      storeNumber.contains(filter) ||
      rfqNumber.contains(filter) ||
      title.contains(filter) ||
      status.contains(filter) ||
      supplierId.contains(filter) ||
      department.contains(filter) ||
      currency.contains(filter) ||
      paymentTerm.contains(filter) ||
      (notes ?? '').contains(filter) ||
      validityDate.contains(filter) ||
      (deliveryAddress ?? '').contains(filter) ||
      // taxCodes.any((e) => e.contains(filter)) ||
      getDeadlineDate.contains(filter) ||
      getDeliveryDate.contains(filter) ||
      lineItems.any((e) => e.filterByAny(filter));

  static RequestForQuote findRFQById(
    List<RequestForQuote> quotes,
    String quoteId,
  ) => quotes.firstWhere(
    (quote) => quote.id == quoteId,
    orElse: () => RequestForQuote.empty,
  );

  static List<RequestForQuote> filterRFQByDate(
    List<RequestForQuote> quotes, {
    bool isSameDay = true,
  }) => quotes
      .where((q) => !q.isAwarded && (isSameDay ? q.isToday : !q.isToday))
      .toList();

  static List<RequestForQuote> filterAwardedRFQ(List<RequestForQuote> quotes) =>
      quotes.where((q) => q.isAwarded).toList();

  RequestForQuote computeTaxAmounts(Map<String, ResolveTaxCode> taxMap) {
    // Calculate tax amounts for each line item (perLineTax)
    final updatedItems = lineItems.map((item) {
      // Tax rate is in Percentage
      final taxRate = item.resolvePerItemTaxes(taxMap);
      final taxAmount = (item.netPrice * taxRate) / 100;
      final taxNames = item.getTaxName(taxMap);

      return item.copyWith(taxAmount: taxAmount, taxNames: taxNames);
    }).toList();

    return copyWith(lineItems: updatedItems);
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
  }

  @override
  String toString() => 'RFQ: $rfqNumber - $supplierId';

  RequestForQuote copyWith({
    String? id,
    String? prId,
    String? title,
    String? department,
    String? storeNumber,
    String? rfqNumber,
    String? supplierId,
    String? supplierRepId,
    List<RFQLineItem>? lineItems,
    String? status,
    String? notes,
    TaxMode? taxMode,
    // List<String>? taxCodes,
    DateTime? deadline,
    DateTime? deliveryDate,
    String? validityDate,
    String? currency,
    String? paymentTerm,
    String? deliveryAddress,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,

    /// [headerTaxAmount] For UI header/overall tax amount only (RFQ)
    // double? headerTaxAmount,

    /// [taxNames] For UI tax names only (RFQ)
    // String? taxNames,
  }) {
    return RequestForQuote(
      id: id ?? this.id,
      prId: prId ?? this.prId,
      title: title ?? this.title,
      department: department ?? this.department,
      storeNumber: storeNumber ?? this.storeNumber,
      rfqNumber: rfqNumber ?? this.rfqNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierRepId: supplierRepId ?? this.supplierRepId,
      lineItems: lineItems ?? this.lineItems,
      paymentTerm: paymentTerm ?? this.paymentTerm,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      deadline: deadline ?? this.deadline,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      // taxCodes: taxCodes ?? this.taxCodes,
      taxMode: taxMode ?? this.taxMode,
      validityDate: validityDate ?? this.validityDate,
      currency: currency ?? this.currency,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,

      /// [headerTaxAmount] For UI header tax amount calculation only (RFQ)
      // headerTaxAmount: headerTaxAmount ?? this.headerTaxAmount,

      /// [taxNames] For UI tax names calculation only (RFQ)
      // taxNames: taxNames ?? this.taxNames,
    );
  }

  @override
  List<Object?> get props => [
    id,
    prId,
    title,
    storeNumber,
    rfqNumber,
    supplierId,
    supplierRepId,
    department,
    paymentTerm,
    status,
    lineItems,
    notes,
    deadline,
    deliveryDate,
    taxMode,
    // taxCodes,
    taxMode,
    validityDate,
    currency,
    deliveryAddress,
    createdBy,
    createdAt,
    updatedBy,
    // headerTaxAmount,
    updatedAt,
  ];

  List<String> get itemAsList => [
    id,
    storeNumber,
    rfqNumber,
    status.toTitle,
    department.toTitle,
    getDeadlineDate,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataTableHeader => const [
    'ID',
    'Store No.',
    'RFQ Number',
    'Status',
    'Department',
    'Deadline',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}

/// RFQ Line Items
class RFQLineItem extends Equatable {
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double discount;
  final List<String> taxCodes;

  /// [taxAmount] is a non-persistent, computed value for UI display only.
  /// Calculated when [TaxMode.perLineTax] is used. Not stored in the database.
  final double taxAmount;

  /// [taxNames] is a non-persistent, UI-only field derived from [taxCodes] using the tax map.
  /// This value is not saved in the database.
  final String taxNames;

  const RFQLineItem({
    required this.itemName,
    required this.quantity,
    this.taxCodes = const [],
    this.unitPrice = 0.0,

    /// [discount] Discount is in percentage
    this.discount = 0.0,

    /// [taxAmount] UI-only, non-persistent value (per-line tax)
    this.taxAmount = 0.0,

    /// [taxNames] UI-only, non-persistent value (derived from tax codes)
    this.taxNames = '',
  });

  // get list of tax codes
  List<String> get taxCodesList =>
      List<String>.from(taxCodes).whereType<String>().toList();

  /// [subTotal] Calculated sub-total for a line item `[subTotal = quantity * unitPrice]`
  double get subTotal => quantity * unitPrice;
  double get discountAmount => (subTotal * discount) / 100;

  /// [perLineTotal] Calculated total for a line item including tax and after discount.
  /// It is derived as: `[perLineTotal = subTotal - discountAmount + taxAmount]`.
  double get perLineTotal => subTotal - discountAmount + taxAmount;

  /// The amount after applying Discounts BUT before Taxes `[netPrice = subTotal - discountAmount]`
  double get netPrice => subTotal - discountAmount;

  // Get tax amount by tax codes
  double resolvePerItemTaxes(Map<String, ResolveTaxCode> taxMap) =>
      _resolveTaxes(taxCodes, taxMap);

  // Get tax names by tax codes
  String getTaxName(Map<String, ResolveTaxCode> taxMap) =>
      _getTaxName(taxCodes, taxMap, '\n');

  bool get isEmpty => itemName.isEmpty;
  bool get isNotEmpty => !isEmpty;

  factory RFQLineItem.fromMap(Map<String, dynamic> data) {
    return RFQLineItem(
      itemName: data['itemName'] ?? '',
      quantity: int.tryParse('${data['quantity']}') ?? 0,
      unitPrice: double.tryParse('${data['unitPrice']}') ?? 0.0,
      discount: double.tryParse('${data['discount']}') ?? 0.0,
      taxCodes: List<String>.from(
        data['taxCodes'] ?? [],
      ).whereType<String>().toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'itemName': itemName,
    'taxCodes': taxCodes,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'discount': discount,
  };

  bool filterByAny(String filter) =>
      itemName.contains(filter) ||
      quantity.toString().contains(filter) ||
      discount.toString().contains(filter) ||
      unitPrice.toString().contains(filter) ||
      netPrice.toString().contains(filter);

  RFQLineItem copyWith({
    String? itemName,
    double? unitPrice,
    int? quantity,
    List<String>? taxCodes,

    /// [discount] Discount is in percentage
    double? discount,

    /// [taxAmount] For UI perLineTax (per item) tax amount only
    double? taxAmount,

    /// [taxNames] For UI tax names calculation only
    String? taxNames,
  }) => RFQLineItem(
    itemName: itemName ?? this.itemName,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    taxCodes: taxCodes ?? this.taxCodes,
    discount: discount ?? this.discount,

    taxAmount: taxAmount ?? this.taxAmount,
    taxNames: taxNames ?? this.taxNames,
  );

  @override
  List<Object?> get props => [
    itemName,
    taxCodes,
    unitPrice,
    quantity,
    discount,
  ];

  static List<String> get dataTableHeader => const [
    'Item Name',
    'Unit Price',
    'Quantity',
    'Discount',
    'Net Price',
  ];

  List<String> get itemAsList => [
    itemName.toTitle,
    '$ghanaCedis$unitPrice',
    '$quantity',
    '$discount% = $ghanaCedis$discountAmount',
    '$ghanaCedis$netPrice',
  ];
}

/// [_resolveTaxes] Resolves the total tax amount for the current RFQ line item based on the provided tax rate map.
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
double _resolveTaxes(
  List<String> taxCodes,
  Map<String, ResolveTaxCode> taxMap,
) {
  if (taxCodes.isEmpty || taxMap.isEmpty) return 0.0;

  // Summing up tax rates based on tax codes.
  // If a tax code is missing from the map, a rate of 0.0 is used.
  return taxCodes.fold(0.0, (sum, code) => sum + (taxMap[code]?.rate ?? 0.0));
}

String _getTaxName(
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
