import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/address_info_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/network/data_sources/models/total_summary_model.dart';
import 'package:assign_erp/core/util/extensions/sales_channel.dart';
import 'package:assign_erp/core/util/extensions/tax_mode.dart';
import 'package:assign_erp/core/util/extensions/workflow_status.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/tax_model.dart';
import 'package:equatable/equatable.dart';

class SalesOrder extends Equatable {
  static get _today => DateTime.now();

  /// 1. Identification & Status
  final String id;
  // Specific Store Sales happened
  final String storeNumber; // FK CompanyStore.storeNumber
  // Sales Quote Number: If only SO was generated from Sales Quotation
  final String sqNumber;
  final String orderNumber;
  final WorkflowStatus status;

  /// 2. Customer & Sales Context
  final String customerId;
  final String salesRepId; // Who generated the Sales Quotation
  final SalesChannel salesChannel;
  final List<AddressInfo> addresses;

  /// 3. Currency & Pricing Control
  final String currencyCode;
  final double
  exchangeRate; // The rate used for currency conversion (if applicable).

  /// 4. Line Items & Shipping
  final List<LineItem> lineItems;
  final double shippingAmount;
  final TaxMode taxMode;

  // final List<String> taxCodes; (This is already in lineItems)

  /// 5. Terms & Conditions
  final String paymentTerms;
  final String warrantyTerms;
  final String returnPolicy;
  final List<String> attachments;

  /// Dates & Validity
  final DateTime? expectedDate; // Delivery date for the entire order
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  final List<AuditLog> history; // History / Audit log

  SalesOrder({
    this.id = '',
    required this.storeNumber,
    this.sqNumber = '',
    required this.orderNumber,
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
    this.taxMode = TaxMode.perLineTax,

    this.paymentTerms = '',
    this.warrantyTerms = '',
    this.returnPolicy = '',
    this.attachments = const [],

    this.expectedDate,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) : history = history ?? [],
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory SalesOrder.fromMap(Map<String, dynamic> map, {String? docId}) {
    return SalesOrder(
      id: docId ?? map['id'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      sqNumber: map['sqNumber'] ?? '',
      salesRepId: map['salesRepId'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      status: WorkflowStatusUtil.fromString(map['status']),
      salesChannel: SalesChannelUtil.fromString(map['SalesChannel']),
      lineItems: LineItem.lineItems(map['lineItems']),
      taxMode: TaxModeUtil.fromString(map['taxMode']),
      // taxCodes: List<String>.from(data['taxCodes'] ?? []),
      currencyCode: map['currencyCode'] ?? '',
      exchangeRate: double.tryParse('${map['exchangeRate']}') ?? 0.0,
      shippingAmount: (map['shippingAmount'] ?? 0).toDouble(),
      addresses: AddressInfo.addresses(map['addresses']),
      attachments: List<String>.from(map['attachments'] ?? []),
      returnPolicy: map['returnPolicy'] ?? '',
      paymentTerms: map['paymentTerms'] ?? '',
      warrantyTerms: map['warrantyTerms'] ?? '',
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
    'orderNumber': orderNumber,
    'sqNumber': sqNumber,
    'customerId': customerId,
    'status': getSOStatus,
    'SalesChannel': salesChannel,
    'salesRepId': salesRepId,
    'lineItems': lineItems.map((i) => i.toMap()).toList(),
    // 'taxCodes': taxCodes,
    'taxMode': getTaxMode,
    'currencyCode': currencyCode,
    'exchangeRate': exchangeRate,
    'shippingAmount': shippingAmount,
    'returnPolicy': returnPolicy,
    'paymentTerms': paymentTerms,
    'warrantyTerms': warrantyTerms,
    'attachments': attachments,
    'addresses': addresses.map((i) => i.toMap()).toList(),
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'history': history.map((i) => i.toMap()).toList(),
  };

  Map<String, dynamic> toMap() {
    final newMap = _mapTemp();
    newMap['expectedDate'] = expectedDate?.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  Map<String, dynamic> toCache() {
    final newMap = _mapTemp();
    newMap['expectedDate'] = expectedDate?.toMilliseconds;
    newMap['createdAt'] = createdAt.toMilliseconds;
    newMap['updatedAt'] = updatedAt.toMilliseconds;

    return {'id': id, 'data': newMap};
  }

  /// Computed TotalSummary based on current line items
  TotalSummary get _totalSum => TotalSummary(lineItems: lineItems);

  // Calculates tax amounts for each line item and the applicable shipping tax.
  SalesOrder calculateTaxes(Map<String, ResolveTaxCode> taxMap) =>
      copyWith(lineItems: lineItems.applyTaxes(taxMap));

  /// Financial Summaries
  double get subTotal => _totalSum.subTotal;
  double get taxableAmount => _totalSum.taxableAmount;
  double get totalDiscountAmount => _totalSum.totalDiscountAmount;
  double get totalTaxPercent => _totalSum.totalTaxPercent;
  double get totalTaxAmount => _totalSum.totalTaxAmount;
  double get netTotal => _totalSum.netTotal;
  double get grandTotal => _totalSum.grandTotal;

  // Singleton instance for fallback (empty SalesOrder)
  static final empty = SalesOrder(
    orderNumber: '',
    storeNumber: '',
    customerId: '',
    salesRepId: '',
    shippingAmount: 0.0,
    lineItems: const [],
    addresses: const [],
    createdBy: '',
  );

  // Returns true if this instance is the singleton [empty] SalesOrder
  bool get isEmpty => identical(this, SalesOrder.empty);

  bool get isNotEmpty => lineItems.isNotEmpty;

  String get getSOStatus => status.getLabel;

  String get getSalesChannel => salesChannel.getLabel;

  String get getTaxMode => taxMode.getName;

  // Returns true if all authorities have approved the Sales Quotation (based on history)
  bool get isFullyApproved =>
      history.isNotEmpty && history.every((a) => a.getAction == getSOStatus);

  String get getExpectedDate => expectedDate.dateOnly;

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
        getExpectedDate,
      }.filterAny(filter) ||
      addresses.filterAny(filter) ||
      itemAsList.contains(filter) ||
      lineItems.any((i) => i.filterByAny(filter));

  static SalesOrder findSOById(List<SalesOrder> rfqs, String rfqId) =>
      rfqs.firstWhere((rfq) => rfq.id == rfqId, orElse: () => SalesOrder.empty);

  static List<SalesOrder> filterSOByDate(
    List<SalesOrder> rfqs, {
    bool isSameDay = true,
  }) => rfqs.where((q) => isSameDay ? q.isToday : !q.isToday).toList();

  @override
  String toString() => 'SO: $orderNumber - $getSOStatus';

  SalesOrder copyWith({
    String? id,
    SalesChannel? salesChannel,
    double? shippingAmount,
    String? storeNumber,
    String? sqNumber,
    String? salesRepId,
    String? orderNumber,
    String? customerId,
    List<LineItem>? lineItems,
    WorkflowStatus? status,
    List<AddressInfo>? addresses,
    TaxMode? taxMode,
    List<String>? attachments,
    DateTime? expectedDate,
    String? currencyCode,
    String? paymentTerms,
    String? warrantyTerms,
    String? returnPolicy,
    double? exchangeRate,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) {
    return SalesOrder(
      id: id ?? this.id,
      status: status ?? this.status,
      salesChannel: salesChannel ?? this.salesChannel,
      salesRepId: salesRepId ?? this.salesRepId,
      storeNumber: storeNumber ?? this.storeNumber,
      sqNumber: sqNumber ?? this.sqNumber,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      lineItems: lineItems ?? this.lineItems,
      shippingAmount: shippingAmount ?? this.shippingAmount,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      warrantyTerms: warrantyTerms ?? this.warrantyTerms,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      addresses: addresses ?? this.addresses,
      // taxCodes: taxCodes ?? this.taxCodes,
      taxMode: taxMode ?? this.taxMode,
      attachments: attachments ?? this.attachments,
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
    orderNumber,
    customerId,
    '$ghanaCedis$shippingAmount',
    returnPolicy,
    status,
    lineItems,
    salesChannel,
    paymentTerms,
    warrantyTerms,
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
    '$sqNumber -> $orderNumber',
    getSOStatus.toTitle,
    getSalesChannel.toTitle,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  /// For UI Header display only
  static List<String> get dataTableHeader => const [
    'ID',
    'Store #',
    'SQ -> SO Number',
    'Status',
    'Sales Channel',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}
