import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/sales_channel.dart';
import 'package:assign_erp/core/constants/tax_mode.dart';
import 'package:assign_erp/core/constants/workflow_status.dart';
import 'package:assign_erp/core/network/data_sources/models/address_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:equatable/equatable.dart';

class SalesQuotation extends Equatable {
  static get _today => DateTime.now();

  /// 1. Identification & Status
  final String id;
  // Specific Store issuing the Sales Quote to the Customer
  final String storeNumber;
  final String quoteNumber; // Request for Quotation number
  final WorkflowStatus status;
  // If true, system is allowed to auto-convert this SQ to Sales order once customer
  // acceptance is confirmed AND a conversion action is explicitly invoked.
  final bool autoCreateSq;

  /// 2. Customer & Sales Context
  final String customerId;
  final String salesRepId; // Who generated the Sales Quotation
  final SalesChannel salesChannel;
  final List<AddressInfo> addresses;

  /// 3. Currency & Pricing Control
  final String currencyCode;
  // The rate used for currency conversion (if applicable).
  final double exchangeRate;

  /// 4. Line Items & Shipping
  final List<LineItem> lineItems;
  final double shippingAmount;
  final int leadTimeDays; //The number of days required to fulfill the order.
  final TaxMode taxMode;

  // final List<String> taxCodes; (This is already in lineItems)

  /// 5. Terms & Conditions
  final String paymentTerms;
  final String warrantyTerms;
  final String returnPolicy;
  final String? notes;
  final List<String> attachments;

  /// Dates & Validity
  final DateTime? expectedDate; // Delivery date for the entire order
  final DateTime? validFrom; // When Sales Quotation validity start
  final DateTime? validUntil; // When Sales Quotation expires
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  final List<AuditLog> history; // History / Audit log

  SalesQuotation({
    this.id = '',
    required this.storeNumber,
    required this.quoteNumber,
    this.autoCreateSq = false,
    this.status = WorkflowStatus.draft,

    required this.customerId,
    required this.salesRepId,
    this.salesChannel = SalesChannel.inStore,
    required this.addresses,

    this.currencyCode = ghanaCedis,
    this.exchangeRate = 0.0,

    // this.taxCodes = const [],
    required this.lineItems,
    this.shippingAmount = 0.0,
    this.leadTimeDays = 0,
    this.taxMode = TaxMode.perLineTax,

    this.paymentTerms = '',
    this.warrantyTerms = '',
    this.returnPolicy = '',
    this.notes,
    this.attachments = const [],

    this.expectedDate,
    this.validFrom,
    this.validUntil,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) : history = history ?? [],
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory SalesQuotation.fromMap(Map<String, dynamic> map, {String? docId}) {
    return SalesQuotation(
      id: docId ?? map['id'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      salesRepId: map['salesRepId'] ?? '',
      quoteNumber: map['quoteNumber'] ?? '',
      autoCreateSq: map['autoCreateSo'] ?? false,
      customerId: map['customerId'] ?? '',
      status: WorkflowStatusHelper.fromString(map['status']),
      salesChannel: SalesChannelHelper.fromString(map['SalesChannel']),
      lineItems: LineItem.lineItems(map['lineItems']),
      notes: map['notes'],
      taxMode: TaxModeHelper.fromString(map['taxMode']),
      // taxCodes: List<String>.from(data['taxCodes'] ?? []),
      currencyCode: map['currencyCode'] ?? '',
      exchangeRate: double.tryParse('${map['exchangeRate']}') ?? 0.0,
      shippingAmount: (map['shippingAmount'] ?? 0).toDouble(),
      addresses: AddressInfo.addresses(map['addresses']),
      attachments: List<String>.from(map['attachments'] ?? []),
      returnPolicy: map['returnPolicy'] ?? '',
      paymentTerms: map['paymentTerms'] ?? '',
      warrantyTerms: map['warrantyTerms'] ?? '',
      leadTimeDays: int.tryParse('${map['leadTimeDays']}') ?? 0,
      validFrom: toDateTimeFn(map['validFrom']),
      validUntil: toDateTimeFn(map['validUntil']),
      expectedDate: toDateTimeFn(map['expectedDate']),
      createdBy: map['createdBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt'] ?? '$_today'),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(map['updatedAt'] ?? '$_today'),
      history: AuditLog.auditLogs(map['history']),
    );
  }

  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'storeNumber': storeNumber,
    'quoteNumber': quoteNumber,
    'autoCreateSo': autoCreateSq,
    'customerId': customerId,
    'status': getSQStatus,
    'SalesChannel': salesChannel,
    'salesRepId': salesRepId,
    'lineItems': lineItems.map((i) => i.toMap()).toList(),
    // 'taxCodes': taxCodes,
    'taxMode': getTaxMode,
    'currencyCode': currencyCode,
    'exchangeRate': exchangeRate,
    'shippingAmount': shippingAmount,
    'notes': notes,
    'returnPolicy': returnPolicy,
    'paymentTerms': paymentTerms,
    'warrantyTerms': warrantyTerms,
    'leadTimeDays': leadTimeDays,
    'attachments': attachments,
    'addresses': addresses.map((i) => i.toMap()).toList(),
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'history': history.map((i) => i.toMap()).toList(),
  };

  Map<String, dynamic> toMap() {
    final newMap = _mapTemp();
    newMap['validFrom'] = validFrom?.toISOString;
    newMap['validUntil'] = validUntil?.toISOString;
    newMap['expectedDate'] = expectedDate?.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  Map<String, dynamic> toCache() {
    final newMap = _mapTemp();
    newMap['validFrom'] = validFrom?.millisecondsSinceEpoch;
    newMap['validUntil'] = validUntil?.millisecondsSinceEpoch;
    newMap['expectedDate'] = expectedDate?.millisecondsSinceEpoch;
    newMap['createdAt'] = createdAt.millisecondsSinceEpoch;
    newMap['updatedAt'] = updatedAt.millisecondsSinceEpoch;

    return {'id': id, 'data': newMap};
  }

  // Computed fields for Financial Summary calculations
  double get subTotalAmount =>
      lineItems.fold(0.0, (sum, item) => sum + item.subTotal);

  double get discountAmount =>
      lineItems.fold(0.0, (sum, item) => sum + item.discountAmount);

  double get taxAmount =>
      lineItems.fold(0.0, (sum, item) => sum + item.taxAmount);

  // subTotal - discountAmount;
  double get netTotalAmount => (subTotalAmount - discountAmount) + taxAmount;

  double get totalAmount => netTotalAmount + shippingAmount;

  // Singleton instance for fallback (empty SalesQuotation)
  static final empty = SalesQuotation(
    quoteNumber: '',
    storeNumber: '',
    customerId: '',
    salesRepId: '',
    shippingAmount: 0.0,
    lineItems: const [],
    addresses: const [],
    createdBy: '',
  );

  // Returns true if this instance is the singleton [empty] SalesQuotation
  bool get isEmpty => identical(this, SalesQuotation.empty);

  bool get isNotEmpty => lineItems.isNotEmpty;

  String get getSQStatus => status.getLabel;

  String get getSalesChannel => salesChannel.getLabel;

  String get getTaxMode => taxMode.getName;

  bool get isApproved => status == WorkflowStatus.approved;

  bool get isExpired => validUntil != null && validUntil!.isBefore(_today);

  bool get canConvertToSO =>
      status == WorkflowStatus.approved && !isExpired && lineItems.isNotEmpty;

  // Returns true if all authorities have approved the Sales Quotation (based on history)
  bool get isFullyApproved =>
      history.isNotEmpty && history.every((a) => a.getAction == getSQStatus);

  String get getExpectedDate => expectedDate.dateOnly;

  String get getValidFromDate => validFrom.dateOnly;

  String get getCreatedAt => createdAt.toStandardDT;

  String get getUpdatedAt => updatedAt.toStandardDT;

  bool get isToday {
    final dt = createdAt.toDateTime;
    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  bool filterByAny(String filter) =>
      {
        salesRepId,
        customerId,
        currencyCode,
        returnPolicy,
        notes ?? '',
        getExpectedDate,
      }.contains(filter) ||
      addresses.any((a) => a.filterByAny(filter)) ||
      itemAsList.any((a) => a.contains(filter)) ||
      lineItems.any((a) => a.filterByAny(filter));

  static SalesQuotation findSQById(
    List<SalesQuotation> quotes,
    String quoteId,
  ) => quotes.firstWhere(
    (quote) => quote.id == quoteId,
    orElse: () => SalesQuotation.empty,
  );

  static List<SalesQuotation> filterApprovedSQ(List<SalesQuotation> quotes) =>
      quotes.where((q) => q.isApproved).toList();

  static List<SalesQuotation> filterSQByDate(
    List<SalesQuotation> quotes, {
    bool isSameDay = true,
  }) => quotes.where((q) => isSameDay ? q.isToday : !q.isToday).toList();

  SalesQuotation computeTaxAmounts(Map<String, ResolveTaxCode> taxMap) {
    // Calculate tax amounts for each line item (perLineTax)
    List<LineItem> updatedItems = lineItems.map((item) {
      if (item is! TaxableLineItem) return item;

      final taxAmount = item.computeTaxAmount(taxMap);
      final taxNames = item.buildTaxNames(taxMap);

      return item.updateTax(taxAmount: taxAmount, taxNames: taxNames);
    }).toList();

    return copyWith(lineItems: updatedItems);
  }

  @override
  String toString() => 'SQ: $quoteNumber - $getSQStatus';

  SalesQuotation copyWith({
    String? id,
    SalesChannel? salesChannel,
    double? shippingAmount,
    String? storeNumber,
    bool? autoCreateSq,
    String? salesRepId,
    String? quoteNumber,
    String? customerId,
    List<LineItem>? lineItems,
    WorkflowStatus? status,
    List<AddressInfo>? addresses,
    TaxMode? taxMode,
    List<String>? attachments,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? expectedDate,
    String? currencyCode,
    String? paymentTerms,
    String? warrantyTerms,
    String? returnPolicy,
    int? leadTimeDays,
    double? exchangeRate,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) {
    return SalesQuotation(
      id: id ?? this.id,
      status: status ?? this.status,
      salesChannel: salesChannel ?? this.salesChannel,
      salesRepId: salesRepId ?? this.salesRepId,
      storeNumber: storeNumber ?? this.storeNumber,
      autoCreateSq: autoCreateSq ?? this.autoCreateSq,
      quoteNumber: quoteNumber ?? this.quoteNumber,
      customerId: customerId ?? this.customerId,
      lineItems: lineItems ?? this.lineItems,
      shippingAmount: shippingAmount ?? this.shippingAmount,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      warrantyTerms: warrantyTerms ?? this.warrantyTerms,
      leadTimeDays: leadTimeDays ?? this.leadTimeDays,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      notes: notes ?? this.notes,
      addresses: addresses ?? this.addresses,
      // taxCodes: taxCodes ?? this.taxCodes,
      taxMode: taxMode ?? this.taxMode,
      attachments: attachments ?? this.attachments,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      expectedDate: expectedDate ?? this.expectedDate,
      currencyCode: currencyCode ?? this.currencyCode,
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
    storeNumber,
    salesRepId,
    quoteNumber,
    customerId,
    '$ghanaCedis$shippingAmount',
    returnPolicy,
    status,
    lineItems,
    notes,
    salesChannel,
    validUntil,
    leadTimeDays,
    paymentTerms,
    warrantyTerms,
    validFrom,
    validUntil,
    expectedDate,
    // taxCodes,
    taxMode,
    currencyCode,
    addresses,
    attachments,
    createdBy,
    createdAt,
    updatedBy,
    // headerTaxAmount,
    updatedAt,
    history,
  ];

  /// For UI display only
  List<String> get itemAsList => [
    id,
    storeNumber,
    quoteNumber,
    getSQStatus.toTitle,
    getSalesChannel.toTitle,
    getValidFromDate,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  /// For UI Header display only
  static List<String> get dataTableHeader => const [
    'ID',
    'Store No.',
    'Quote Number',
    'Status',
    'Sales Channel',
    'validFrom',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}

/*final updatedItems = lineItems.map((item) {
      // Tax rate is in Percentage
      final taxRate = item.resolvePerItemTaxes(taxMap);
      final taxAmount = (item.netPrice * taxRate) / 100;
      final taxNames = item.getTaxName(taxMap);

      return item.copyWith(taxAmount: taxAmount, taxNames: taxNames);
    }).toList();

    return copyWith(lineItems: updatedItems);

===============
if (taxMode == taxModeToApply.perLineTax) {
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

/* /// [headerTaxAmount] is a non-persistent, computed value used for UI display only
  /// when [TaxMode.headerTax] is applied. This value is not stored in the database.
  final double headerTaxAmount;

  /// [taxNames] is a non-persistent, computed field used solely for UI display.
  /// It is derived from [taxCodes] and the tax map. Not stored in the database.
  final String taxNames;

  double resolveHeaderTaxes(Map<String, ResolveTaxCode> taxMap) =>
      _resolveTaxes(taxCodes, taxMap);

  String getTaxName(Map<String, ResolveTaxCode> taxMap) =>
      _getTaxName(taxCodes, taxMap);

  taxMode.isHeaderTax ? headerTaxAmount : lineItems.fold(0.0, (sum, item) => sum + item.taxAmount);
  // [headerTaxAmount] For UI header/overall tax amount only (RFQ)
    // double? headerTaxAmount,

    // [taxNames] For UI tax names only (RFQ)
    // String? taxNames,
      // [headerTaxAmount] For UI header tax amount calculation only (RFQ)
      // headerTaxAmount: headerTaxAmount ?? this.headerTaxAmount,

      // [taxNames] For UI tax names calculation only (RFQ)
      // taxNames: taxNames ?? this.taxNames,
  */

/*// RFQ Line Items
 Second Implementation:
class RFQLineItem extends ProLineItem {
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
    /// Inherited from [ProLineItem]
    required super.description,
    required super.quantity,
    required super.category,
    required super.unitOfMeasure,
    required super.notes,

    // Internal members
    this.taxCodes = const [],
    this.unitPrice = 0.0,

    /// [discount] Discount is in percentage
    this.discount = 0.0,

    /// [taxAmount] UI-only, non-persistent value (per-line tax)
    this.taxAmount = 0.0,

    /// [taxNames] UI-only, non-persistent value (derived from tax codes)
    this.taxNames = '',
  });

  factory RFQLineItem.fromMap(Map<String, dynamic> map) {
    return RFQLineItem(
      /// Inherited from [ProLineItem]
      description: map['description'] ?? '',
      quantity: int.tryParse('${map['quantity']}') ?? 0,
      category: ItemCategoryHelper.fromString(map['category']),
      unitOfMeasure: UOMHelper.fromString(map['unitOfMeasure']),
      notes: map['notes'] ?? '',

      /// Internal members
      unitPrice: double.tryParse('${map['unitPrice']}') ?? 0.0,
      discount: double.tryParse('${map['discount']}') ?? 0.0,
      taxCodes: List<String>.from(
        map['taxCodes'] ?? [],
      ).whereType<String>().toList(),
      taxAmount: double.tryParse('${map['taxAmount']}') ?? 0.0,
      taxNames: map['taxNames'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'taxCodes': taxCodes,
    'discount': discount,
    'unitPrice': unitPrice,
  };

  /// [taxCodesList] Get list of tax codes from [taxCodes]
  List<String> get taxCodesList =>
      List<String>.from(taxCodes).whereType<String>().toList();

  /// [subTotal] Calculated sub-total for a line item `[subTotal = quantity * unitPrice]`
  double get subTotal => super.quantity * unitPrice;
  double get discountAmount => (subTotal * discount) / 100;

  /// [perLineTotal] Calculated total for a line item including tax and after discount.
  /// It is derived as: `[perLineTotal = subTotal - discountAmount + taxAmount]`.
  double get perLineTotal => subTotal - discountAmount + taxAmount;

  /// The amount after applying Discounts BUT before Taxes `[netPrice = subTotal - discountAmount]`
  double get netPrice => subTotal - discountAmount;

  // Get tax amount by tax codes
  double resolvePerItemTaxes(Map<String, ResolveTaxCode> taxMap) =>
      computeLineTaxAmount(taxCodes, taxMap);

  // Get tax names by tax codes
  String getTaxName(Map<String, ResolveTaxCode> taxMap) =>
      buildTaxNames(taxCodes, taxMap, '\n');

  @override
  bool filterByAny(String filter) =>
      super.filterByAny(filter) ||
      discount.toString().contains(filter) ||
      unitPrice.toString().contains(filter) ||
      netPrice.toString().contains(filter);

  @override
  RFQLineItem copyWith({
    /// Inherited from [ProLineItem]
    String? description,
    int? quantity,
    ItemCategory? category,
    UnitOfMeasure? unitOfMeasure,
    String? notes,

    // Internal members
    double? unitPrice,
    List<String>? taxCodes,

    /// [discount] Discount is in percentage
    double? discount,

    /// [taxAmount] For UI perLineTax (per item) tax amount only
    double? taxAmount,

    /// [taxNames] For UI tax names calculation only
    String? taxNames,
  }) => RFQLineItem(
    /// Inherited from [ProLineItem]
    description: description ?? this.description,
    quantity: quantity ?? this.quantity,
    category: category ?? this.category,
    unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
    notes: notes ?? this.notes,

    // Internal members
    taxCodes: taxCodes ?? this.taxCodes,
    discount: discount ?? this.discount,
    unitPrice: unitPrice ?? this.unitPrice,

    taxAmount: taxAmount ?? this.taxAmount,
    taxNames: taxNames ?? this.taxNames,
  );

  @override
  List<Object?> get props => [
    ...super.props,
    taxCodes,
    unitPrice,
    discount,
    taxAmount,
    taxNames,
  ];

  static List<String> get dataTableHeader => const [
    'Item Name',
    'Unit Price',
    'Quantity',
    'Discount',
    'Net Price',
  ];

  @override
  List<String> get itemAsList => [
    description.toTitle,
    '$ghanaCedis$unitPrice',
    '$quantity',
    '$discount% = $ghanaCedis$discountAmount',
    '$ghanaCedis$netPrice',
  ];
}*/

/* First Implementation:
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

  factory RFQLineItem.fromMap(Map<String, dynamic> map) {
    return RFQLineItem(
      itemName: map['itemName'] ?? '',
      quantity: int.tryParse('${map['quantity']}') ?? 0,
      unitPrice: double.tryParse('${map['unitPrice']}') ?? 0.0,
      discount: double.tryParse('${map['discount']}') ?? 0.0,
      taxCodes: List<String>.from(
        map['taxCodes'] ?? [],
      ).whereType<String>().toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'itemName': itemName,
    'taxCodes': taxCodes,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'discount': discount,
    // 'unitOfMeasure': getUnitOfMeasure,
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
}*/
