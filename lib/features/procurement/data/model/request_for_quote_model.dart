import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/procurement_workflow_status.dart';
import 'package:assign_erp/core/constants/tax_mode.dart';
import 'package:assign_erp/core/network/data_sources/models/address_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/procurement/data/model/pro_line_item_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_link_model.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:equatable/equatable.dart';

// * Responses (linked or stored in sub-table)

class RequestForQuote extends Equatable {
  static get _today => DateTime.now();

  final String id;

  /// [prNumber] Foreign key referencing the Purchase Requisition (PR).
  /// Used to associate this Request for Quote (RFQ) with its originating PR.
  /// If empty, the RFQ is treated as a “RAW RFQ” and is not linked to any PR
  /// (i.e., it was created independently and not generated from an PR).
  final String prNumber;

  final String rfqNumber; // Request for Quote number
  /// Auto-Generate PO when RFQ is Accepted
  final bool autoCreatePo;
  final String storeNumber;
  final List<SupplierLink>
  supplierLinks; // List of invited suppliers for this RFQ
  final String requestedBy; // Who requested the RFQ
  final ProcurementWorkflowStatus status;
  final String title;
  final String currency;

  /// [costCenterCode] Business Unit or Department paying for the purchase
  final String costCenterCode;

  final String departmentCode;
  final List<ProLineItem> lineItems;
  final TaxMode taxMode;

  // final List<String> taxCodes;
  final String buyerContactPersonId;
  final AddressInfo? shippingAddress;
  final String? notes;

  /// [expectedDate] Target/delivery date by which the entire items/services are needed
  final DateTime? expectedDate;
  final DateTime? deadline; // RFQ deadline date
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

  RequestForQuote({
    this.id = '',
    this.prNumber = '',
    this.autoCreatePo = false,
    required this.title,
    required this.rfqNumber,
    required this.storeNumber,
    required this.supplierLinks,
    this.status = ProcurementWorkflowStatus.draft,
    required this.lineItems,
    required this.requestedBy,
    required this.costCenterCode,
    required this.departmentCode,
    // this.taxCodes = const [],
    this.taxMode = TaxMode.perLineTax,
    this.currency = ghanaCedis,
    this.buyerContactPersonId = '',
    this.shippingAddress,
    this.notes,
    this.attachments = const [],
    DateTime? deadline,
    DateTime? expectedDate,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) : history = history ?? [],
       deadline = deadline ?? _today,
       expectedDate = expectedDate ?? _today,
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory RequestForQuote.fromMap(Map<String, dynamic> map, {String? docId}) {
    return RequestForQuote(
      id: docId ?? map['id'] ?? '',
      prNumber: map['prNumber'] ?? '',
      autoCreatePo: map['autoCreatePo'] ?? false,
      title: map['title'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      requestedBy: map['requestedBy'] ?? '',
      rfqNumber: map['rfqNumber'] ?? '',
      supplierLinks: SupplierLink.suppliers(map['supplierLinks']),
      status: ProcurementStatusHelper.fromString(map['status']),
      costCenterCode: map['costCenterCode'] ?? '',
      departmentCode: map['departmentCode'] ?? '',
      lineItems: ProLineItem.lineItems(map['lineItems']),
      notes: map['notes'],
      taxMode: TaxModeHelper.fromString(map['taxMode']),
      buyerContactPersonId: map['buyerContactPersonId'] ?? '',
      // taxCodes: List<String>.from(data['taxCodes'] ?? []),
      currency: map['currency'] ?? '',
      shippingAddress: map['shippingAddress'] != null
          ? AddressInfo.fromMap(
              Map<String, dynamic>.from(map['shippingAddress']),
            )
          : null,
      attachments: List<String>.from(map['attachments'] ?? []),
      deadline: toDateTimeFn(map['deadline']),
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
    'prNumber': prNumber,
    'autoCreatePo': autoCreatePo,
    'title': title,
    'storeNumber': storeNumber,
    'rfqNumber': rfqNumber,
    'supplierLinks': supplierLinks.map((i) => i.toMap()).toList(),
    'status': getRFQStatus,
    'costCenterCode': costCenterCode,
    'departmentCode': departmentCode,
    'requestedBy': requestedBy,
    'lineItems': lineItems.map((i) => i.toMap()).toList(),
    'notes': notes,
    // 'taxCodes': taxCodes,
    'taxMode': getTaxMode,
    'currency': currency,
    'buyerContactPersonId': buyerContactPersonId,
    'attachments': attachments,
    'shippingAddress': shippingAddress?.toMap(),
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'history': history.map((i) => i.toMap()).toList(),
  };

  Map<String, dynamic> toMap() {
    final newMap = _mapTemp();
    newMap['deadline'] = deadline?.toISOString;
    newMap['expectedDate'] = expectedDate?.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  Map<String, dynamic> toCache() {
    final newMap = _mapTemp();
    newMap['deadline'] = deadline?.millisecondsSinceEpoch;
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

  /// A singleton instance representing an empty/default RequestForQuote.
  /// Used as a fallback when no matching RFQ is found.
  static final empty = RequestForQuote(
    rfqNumber: '',
    title: '',
    storeNumber: '',
    supplierLinks: const [],
    costCenterCode: '',
    departmentCode: '',
    lineItems: const [],
    createdBy: '',
    requestedBy: '',
    shippingAddress: null,
  );

  /// Returns true if this instance is the singleton [empty] RFQ.
  /// Use this to check if the RFQ is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, RequestForQuote.empty);

  bool get isNotEmpty => lineItems.isNotEmpty;

  bool get isAwarded => status == ProcurementWorkflowStatus.convertedToPO;

  String get getRFQStatus => status.getLabel;

  String get getTaxMode => taxMode.getName;

  bool get isApproved => status == ProcurementWorkflowStatus.approved;

  /// [isFullyApproved] Have all required authorities (managers, finance, procurement, etc.) approved the RFQ?
  bool get isFullyApproved =>
      history.isNotEmpty && history.every((a) => a.getAction == getRFQStatus);

  String get getAutoCreatePo => autoCreatePo ? 'Yes' : 'No';

  String get getExpectedDate => expectedDate.dateOnly;

  // String get getValidityDate => (int.tryParse(validityDate.split(' ').first)?.toDate).dateOnly;

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
      itemAsList.any((item) => item.contains(filter)) ||
      prNumber.contains(filter) ||
      requestedBy.contains(filter) ||
      title.contains(filter) ||
      supplierLinks.any((e) => e.filterByAny(filter)) ||
      currency.contains(filter) ||
      buyerContactPersonId.contains(filter) ||
      (notes ?? '').contains(filter) ||
      (shippingAddress?.filterByAny(filter) ?? false) ||
      getExpectedDate.contains(filter) ||
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
  String toString() => 'RFQ: $rfqNumber - $getRFQStatus';

  RequestForQuote copyWith({
    String? id,
    String? prNumber,
    bool? autoCreatePo,
    String? title,
    String? costCenterCode,
    String? departmentCode,
    String? storeNumber,
    String? requestedBy,
    String? rfqNumber,
    List<SupplierLink>? supplierLinks,
    List<ProLineItem>? lineItems,
    ProcurementWorkflowStatus? status,
    String? notes,
    TaxMode? taxMode,
    List<String>? attachments,
    String? termsAndConditions,
    DateTime? deadline,
    DateTime? expectedDate,
    String? currency,
    String? buyerContactPersonId,
    AddressInfo? shippingAddress,
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
    return RequestForQuote(
      id: id ?? this.id,
      prNumber: prNumber ?? this.prNumber,
      autoCreatePo: autoCreatePo ?? this.autoCreatePo,
      title: title ?? this.title,
      costCenterCode: costCenterCode ?? this.costCenterCode,
      departmentCode: departmentCode ?? this.departmentCode,
      requestedBy: requestedBy ?? this.requestedBy,
      storeNumber: storeNumber ?? this.storeNumber,
      rfqNumber: rfqNumber ?? this.rfqNumber,
      supplierLinks: supplierLinks ?? this.supplierLinks,
      lineItems: lineItems ?? this.lineItems,
      buyerContactPersonId: buyerContactPersonId ?? this.buyerContactPersonId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      deadline: deadline ?? this.deadline,
      expectedDate: expectedDate ?? this.expectedDate,
      // taxCodes: taxCodes ?? this.taxCodes,
      taxMode: taxMode ?? this.taxMode,
      attachments: attachments ?? this.attachments,
      currency: currency ?? this.currency,
      shippingAddress: shippingAddress ?? this.shippingAddress,
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
    prNumber,
    autoCreatePo,
    title,
    storeNumber,
    requestedBy,
    rfqNumber,
    supplierLinks,
    departmentCode,
    buyerContactPersonId,
    status,
    lineItems,
    notes,
    deadline,
    expectedDate,
    taxMode,
    // taxCodes,
    taxMode,
    currency,
    shippingAddress,
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
    getAutoCreatePo,
    '$prNumber -> $rfqNumber',
    getRFQStatus.toTitle,
    costCenterCode,
    departmentCode.toTitle,
    getDeadlineDate,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  /// For UI Header display only
  static List<String> get dataTableHeader => const [
    'ID',
    'Store No.',
    'Auto PO',
    'PR -> RFQ Number',
    'Status',
    'Cost Center',
    'Department',
    'Deadline',
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
