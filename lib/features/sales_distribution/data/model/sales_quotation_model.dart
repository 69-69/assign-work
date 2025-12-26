import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/procurement_workflow_status.dart';
import 'package:assign_erp/core/constants/sales_channel.dart';
import 'package:assign_erp/core/constants/tax_mode.dart';
import 'package:assign_erp/core/network/data_sources/models/address_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/procurement/data/model/pro_line_item_model.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:equatable/equatable.dart';

// * Responses (linked or stored in sub-table)

class SalesQuotation extends Equatable {
  static get _today => DateTime.now();

  /// 1. Identification & Status
  final String id;
  // Specific Store issuing the Sales Quote to the Customer
  final String storeNumber;
  final String quoteNumber; // Request for Quotation number
  final ProcurementWorkflowStatus status;

  /// 2. Customer & Sales Context
  final String customerId;
  final List<AddressInfo> addresses;
  final String salesRepId; // Who generated the Sales Quotation
  final SalesChannel salesChannel;

  /// 3. Currency & Pricing Control
  final String currencyCode;
  final String exchangeRate;

  /// 4. Financial Summary Fields
  final double shippingAmount;
  /*final double subtotalAmount;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;*/
  final List<ProLineItem> lineItems;
  final TaxMode taxMode;

  // final List<String> taxCodes;
  final String buyerContactPersonId;
  final String? notes;

  /// [expectedDate] Target/delivery date by which the entire items/services are needed
  final DateTime? expectedDate;
  final DateTime? validFrom; // When Sales Quotation validity start
  final DateTime? validUntil; // When Sales Quotation expires
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  /// [history] Audit trail: track all changes made to the PR
  final List<AuditLog> history;
  final List<String> attachments;

  /*/// [headerTaxAmount] is a non-persistent, computed value used for UI display only
  /// when [TaxMode.headerTax] is applied. This value is not stored in the database.
  final double headerTaxAmount;

  /// [taxNames] is a non-persistent, computed field used solely for UI display.
  /// It is derived from [taxCodes] and the tax map. Not stored in the database.
  final String taxNames;*/

  SalesQuotation({
    this.id = '',
    required this.quoteNumber,
    required this.storeNumber,
    required this.customerId,
    this.status = ProcurementWorkflowStatus.draft,
    required this.lineItems,
    required this.salesRepId,
    this.salesChannel = SalesChannel.inStore,
    this.shippingAmount = 0.0,
    // this.taxCodes = const [],
    this.taxMode = TaxMode.perLineTax,
    this.currencyCode = ghanaCedis,
    this.exchangeRate = '',
    this.buyerContactPersonId = '',
    required this.addresses,
    this.notes,
    this.attachments = const [],
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? expectedDate,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) : history = history ?? [],
       validFrom = validFrom ?? _today,
       validUntil = validUntil ?? _today,
       expectedDate = expectedDate ?? _today,
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory SalesQuotation.fromMap(Map<String, dynamic> map, {String? docId}) {
    return SalesQuotation(
      id: docId ?? map['id'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      salesRepId: map['salesRepId'] ?? '',
      quoteNumber: map['quoteNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      status: ProcurementStatusHelper.fromString(map['status']),
      salesChannel: SalesChannelHelper.fromString(map['SalesChannel']),
      lineItems: ProLineItem.lineItems(map['lineItems']),
      notes: map['notes'],
      taxMode: TaxModeHelper.fromString(map['taxMode']),
      // taxCodes: List<String>.from(data['taxCodes'] ?? []),
      currencyCode: map['currency'] ?? '',
      exchangeRate: map['exchangeRate'] ?? '',
      addresses: AddressInfo.addresses(map['addresses']),
      attachments: List<String>.from(map['attachments'] ?? []),
      buyerContactPersonId: map['buyerContactPersonId'] ?? '',
      shippingAmount: map['shippingAmount'] ?? '',
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
    'customerId': customerId,
    'status': getRFQStatus,
    'SalesChannel': salesChannel,
    'shippingAmount': shippingAmount,
    'salesRepId': salesRepId,
    'lineItems': lineItems.map((i) => i.toMap()).toList(),
    'notes': notes,
    // 'taxCodes': taxCodes,
    'taxMode': getTaxMode,
    'currency': currencyCode,
    'buyerContactPersonId': buyerContactPersonId,
    'attachments': attachments,
    'addresses': addresses.map((i) => i.toMap()).toList(),
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'history': history.map((i) => i.toMap()).toList(),
  };

  Map<String, dynamic> toMap() {
    final newMap = _mapTemp();
    newMap['validFrom'] = validFrom?.toISOString;
    newMap['expectedDate'] = expectedDate?.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  Map<String, dynamic> toCache() {
    final newMap = _mapTemp();
    newMap['validFrom'] = validFrom?.millisecondsSinceEpoch;
    newMap['expectedDate'] = expectedDate?.millisecondsSinceEpoch;
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

  /// A singleton instance representing an empty/default SalesQuotation.
  /// Used as a fallback when no matching RFQ is found.
  static final empty = SalesQuotation(
    quoteNumber: '',
    storeNumber: '',
    customerId: '',
    shippingAmount: 0.0,
    lineItems: const [],
    createdBy: '',
    salesRepId: '',
    addresses: const [],
  );

  /// Returns true if this instance is the singleton [empty] RFQ.
  /// Use this to check if the RFQ is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, SalesQuotation.empty);

  bool get isNotEmpty => lineItems.isNotEmpty;

  bool get isAwarded => status == ProcurementWorkflowStatus.convertedToPO;

  String get getRFQStatus => status.getLabel;

  String get getSalesChannel => salesChannel.getLabel;

  String get getTaxMode => taxMode.getName;

  bool get isApproved => status == ProcurementWorkflowStatus.approved;

  /// [isFullyApproved] Have all required authorities (managers, finance, procurement, etc.) approved the RFQ?
  bool get isFullyApproved =>
      history.isNotEmpty && history.every((a) => a.getAction == getRFQStatus);

  String get getExpectedDate => expectedDate.dateOnly;

  // String get getValidityDate => (int.tryParse(validityDate.split(' ').first)?.toDate).dateOnly;

  String get getvalidFromDate => validFrom.dateOnly;

  String get getCreatedAt => createdAt.toStandardDT;

  String get getUpdatedAt => updatedAt.toStandardDT;

  bool get isToday {
    final dt = createdAt.toDateTime;
    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  bool filterByAny(String filter) =>
      itemAsList.any((item) => item.contains(filter)) ||
      salesRepId.contains(filter) ||
      customerId.contains(filter) ||
      currencyCode.contains(filter) ||
      buyerContactPersonId.contains(filter) ||
      (notes ?? '').contains(filter) ||
      addresses.any((a) => a.filterByAny(filter)) ||
      getExpectedDate.contains(filter) ||
      lineItems.any((e) => e.filterByAny(filter));

  static SalesQuotation findRFQById(List<SalesQuotation> rfqs, String rfqId) =>
      rfqs.firstWhere(
        (rfq) => rfq.id == rfqId,
        orElse: () => SalesQuotation.empty,
      );

  static List<SalesQuotation> filterRFQByDate(
    List<SalesQuotation> rfqs, {
    bool isSameDay = true,
  }) => rfqs
      .where((q) => !q.isAwarded && (isSameDay ? q.isToday : !q.isToday))
      .toList();

  static List<SalesQuotation> filterAwardedRFQ(List<SalesQuotation> rfqs) =>
      rfqs.where((q) => q.isAwarded).toList();

  SalesQuotation computeTaxAmounts(Map<String, ResolveTaxCode> taxMap) {
    // Calculate tax amounts for each line item (perLineTax)
    List<ProLineItem> updatedItems = lineItems.map((item) {
      if (item is! TaxableLineItem) return item;

      final taxAmount = item.computeTaxAmount(taxMap);
      final taxNames = item.buildTaxNames(taxMap);

      return item.updateTax(taxAmount: taxAmount, taxNames: taxNames);
    }).toList();

    return copyWith(lineItems: updatedItems);

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
  }

  @override
  String toString() => 'RFQ: $quoteNumber - $getRFQStatus';

  SalesQuotation copyWith({
    String? id,
    String? prNumber,
    bool? autoCreatePo,
    String? title,
    SalesChannel? salesChannel,
    double? shippingAmount,
    String? storeNumber,
    String? salesRepId,
    String? quoteNumber,
    String? customerId,
    List<ProLineItem>? lineItems,
    ProcurementWorkflowStatus? status,
    String? notes,
    TaxMode? taxMode,
    List<String>? attachments,
    String? termsAndConditions,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? expectedDate,
    String? currencyCode,
    String? buyerContactPersonId,
    List<AddressInfo>? addresses,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    List<AuditLog>? history,

    // [headerTaxAmount] For UI header/overall tax amount only (RFQ)
    // double? headerTaxAmount,

    // [taxNames] For UI tax names only (RFQ)
    // String? taxNames,
  }) {
    return SalesQuotation(
      id: id ?? this.id,
      status: status ?? this.status,
      salesChannel: salesChannel ?? this.salesChannel,
      salesRepId: salesRepId ?? this.salesRepId,
      storeNumber: storeNumber ?? this.storeNumber,
      quoteNumber: quoteNumber ?? this.quoteNumber,
      customerId: customerId ?? this.customerId,
      lineItems: lineItems ?? this.lineItems,
      shippingAmount: shippingAmount ?? this.shippingAmount,
      buyerContactPersonId: buyerContactPersonId ?? this.buyerContactPersonId,
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

      // [headerTaxAmount] For UI header tax amount calculation only (RFQ)
      // headerTaxAmount: headerTaxAmount ?? this.headerTaxAmount,

      // [taxNames] For UI tax names calculation only (RFQ)
      // taxNames: taxNames ?? this.taxNames,
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
    buyerContactPersonId,
    status,
    lineItems,
    notes,
    validFrom,
    expectedDate,
    taxMode,
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
    getRFQStatus.toTitle,
    getSalesChannel.toTitle,
    getvalidFromDate,
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
