import 'package:assign_erp/core/network/data_sources/models/address_info_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/network/data_sources/models/total_summary_model.dart';
import 'package:assign_erp/core/util/extensions/tax_mode.dart';
import 'package:assign_erp/core/util/extensions/workflow_status.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_link_model.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:equatable/equatable.dart';

class ProPurchaseOrder extends Equatable {
  static get _today => DateTime.now();

  final String id;

  /// [rfqNumber] Foreign key referencing the Request for Quote (RFQ).
  /// Used to associate this Purchase Order (PO) with its originating RFQ.
  /// If empty, the PO is treated as a “RAW PO” and is not linked to any RFQ
  /// (i.e., it was created independently and not generated from an RFQ).
  final String rfqNumber;

  final String poNumber;
  final String storeNumber; // FK CompanyStore.storeNumber
  final SupplierLink supplierLink;
  final List<LineItem> lineItems; // A list of items in the RFQ
  final TaxMode taxMode;

  final String currencyCode;
  final String requestedBy; // Buyer's Contact: Who requested the PO

  final WorkflowStatus status;

  /// [costCenterCode] Business Unit or Department paying for the purchase
  final String costCenterCode;

  /// [paymentTerm] When the payment is due and if any discounts apply
  final String paymentTerm;

  /// [paymentMethod] How the payment is made (the financial instrument or channel)
  final String paymentMethod;
  final String buyerContactPersonId;

  final String? notes;
  final List<String> attachments;

  /// [addresses] Addresses (e.g., Billing, Shipping Address, etc)
  final List<AddressInfo>? addresses;

  // For Snapshot
  final double taxAmount;
  final double shippingAmount;
  final double shippingTaxAmount;
  final String? termsAndConditions;

  final DateTime? deliveryDate;

  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  /// [history] Audit trail: track all changes made to the PR
  final List<AuditLog> history;

  ProPurchaseOrder({
    this.id = '',
    this.rfqNumber = '',
    required this.poNumber,
    required this.currencyCode,
    required this.storeNumber,
    required this.supplierLink,
    required this.requestedBy,
    this.costCenterCode = '',
    this.status = WorkflowStatus.draft,
    required this.lineItems,
    this.taxMode = TaxMode.perLineTax,
    required this.paymentTerm,
    required this.paymentMethod,
    this.attachments = const [],
    this.notes,
    this.addresses,
    this.taxAmount = 0.0,
    this.shippingAmount = 0.0,
    this.shippingTaxAmount = 0.0,
    this.buyerContactPersonId = '',
    this.termsAndConditions,
    DateTime? deliveryDate,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) : history = history ?? [],
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today,
       deliveryDate = deliveryDate ?? _today;

  /// fromFirestore / fromJson Function [ProPurchaseOrder.fromMap]
  factory ProPurchaseOrder.fromMap(Map<String, dynamic> map, {String? docId}) {
    return ProPurchaseOrder(
      id: docId ?? map['id'] ?? '',
      poNumber: map['poNumber'] ?? '',
      rfqNumber: map['rfqNumber'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      supplierLink: SupplierLink.fromMap(map['supplierLink']),
      requestedBy: map['requestedBy'] ?? '',
      costCenterCode: map['costCenterCode'] ?? '',
      status: WorkflowStatusUtil.fromString(map['status']),
      lineItems: LineItem.lineItems(map['lineItems']),
      currencyCode: map['currencyCode'] ?? '',
      paymentTerm: map['paymentTerm'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      taxMode: TaxModeUtil.fromString(map['taxMode']),
      taxAmount: '${map['taxAmount']}'.asDouble,
      shippingAmount: '${map['shippingAmount']}'.asDouble,
      notes: map['notes'] ?? '',
      buyerContactPersonId: map['buyerContactPersonId'] ?? '',
      attachments: List<String>.from(map['attachments'] ?? []),
      addresses: AddressInfo.addresses(map['addresses']),
      termsAndConditions: map['termsAndConditions'] ?? '',
      deliveryDate: toDateTimeFn(map['deliveryDate'] ?? '$_today'),
      createdBy: map['createdBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt'] ?? '$_today'),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(map['updatedAt'] ?? '$_today'),
      history: AuditLog.auditLogs(map['history']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'storeNumber': storeNumber,
    'poNumber': poNumber,
    'rfqNumber': rfqNumber,
    'supplierLink': supplierLink.toMap(),
    'requestedBy': requestedBy,
    'status': getPOStatus,
    'currencyCode': currencyCode,
    'costCenterCode': costCenterCode,
    'lineItems': lineItems.map((i) => i.toMap()).toList(),
    'taxMode': getTaxName,
    'paymentTerm': paymentTerm,
    'paymentMethod': paymentMethod,
    'termsAndConditions': termsAndConditions,
    'deliveryDate': deliveryDate,
    'shippingAmount': shippingAmount,
    'notes': notes,
    'buyerContactPersonId': buyerContactPersonId,
    'attachments': attachments,
    'addresses': addresses?.map((i) => i.toMap()).toList(),
    'taxAmount': taxAmount,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'history': history.map((i) => i.toMap()).toList(),
  };

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['deliveryDate'] = createdAt.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['deliveryDate'] = deliveryDate.toMilliseconds;
    newMap['createdAt'] = createdAt.toMilliseconds;
    newMap['updatedAt'] = updatedAt.toMilliseconds;

    return {'id': id, 'data': newMap};
  }

  /// Get the last approved info from PO history [getApproval]
  ({String? by, String? at}) get getApproval {
    if (history.isNullOrEmpty) return (by: null, at: null);

    // Find the most recent approved PO entry
    final lastApproved = history.lastWhere(
      (h) => h.getAction.toLowerAll == AuditAction.approved.getLabel,
      orElse: () => AuditLog.empty,
    );

    // If none found, return null for both
    if (lastApproved.isEmpty) return (by: null, at: null);

    return (by: lastApproved.actionBy, at: lastApproved.getActionAt);
  }

  /// A singleton instance representing an empty/default ProPurchaseOrder.
  /// Used as a fallback when no matching PO is found.
  static final ProPurchaseOrder empty = ProPurchaseOrder(
    poNumber: '',
    storeNumber: '',
    supplierLink: SupplierLink.empty,
    currencyCode: '',
    lineItems: [],
    paymentTerm: '',
    paymentMethod: '',
    createdBy: '',
    requestedBy: '',
  );

  /// [isEmpty] Checks if the ProPurchaseOrder is empty.
  bool get isEmpty => identical(this, ProPurchaseOrder.empty);

  // The name is needed not label
  String get getTaxName => taxMode.getName;

  String get getPOStatus => status.getLabel;

  bool get isApproved => status == WorkflowStatus.approved;

  // Returns true if all authorities have approved the PO (based on history)
  bool get isFullyApproved =>
      history.isNotEmpty && history.every((a) => a.getAction == getPOStatus);

  String get getDeliveryDate => deliveryDate.dateOnly;

  String get getCreatedAt => createdAt.toStandardDT;

  String get getUpdatedAt => updatedAt.toStandardDT;

  /// Current / Today's Products/Stocks
  bool get isToday {
    var dt = createdAt.toDateTime;

    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  /// Computed TotalSummary based on current line items and shipping amount
  TotalSummary get _totalSum => TotalSummary(
    lineItems: lineItems,
    shippingAmount: shippingAmount,
    shippingTaxAmount: shippingTaxAmount,
  );

  // Calculates tax amounts for each line item and the applicable shipping tax.
  ProPurchaseOrder calculateTaxes(Map<String, ResolveTaxCode> taxMap) {
    final taxedLineItems = lineItems.applyTaxes(taxMap);

    // Apply shipping tax and get a new TotalSummary
    final updatedTotalSum = _totalSum
        .copyWith(lineItems: taxedLineItems)
        .withShippingTax(taxMap);

    return copyWith(
      lineItems: taxedLineItems,
      shippingTaxAmount: updatedTotalSum.shippingTaxAmount,
    );
  }

  /// Financial Summaries
  double get subTotal => _totalSum.subTotal;
  double get taxableAmount => _totalSum.taxableAmount;
  double get totalDiscountAmount => _totalSum.totalDiscountAmount;
  double get totalTaxPercent => _totalSum.totalTaxPercent;
  double get totalTaxAmount => _totalSum.totalTaxAmount;
  double get netTotal => _totalSum.netTotal;
  double get grandTotal => _totalSum.grandTotal;

  /// Filter
  bool filterByAny(String filter) =>
      itemAsList.filterAny(filter) ||
      {
        requestedBy,
        supplierLink,
        costCenterCode,
        currencyCode,
        paymentTerm,
        paymentMethod,
        buyerContactPersonId,
        getTaxName,
        taxAmount,
      }.filterAny(filter) ||
      lineItems.any((i) => i.filterByAny(filter));

  /// [findPOById]
  static ProPurchaseOrder findPOById(List<ProPurchaseOrder> po, String poId) =>
      po.firstWhere((o) => o.id == poId, orElse: () => ProPurchaseOrder.empty);

  /// [filterPOByDate]
  static List<ProPurchaseOrder> filterPOByDate(
    List<ProPurchaseOrder> po, {
    bool isSameDay = true,
  }) => po
      .where(
        (order) =>
            !order.isApproved && (isSameDay ? order.isToday : !order.isToday),
      )
      .toList();

  /// [filterApprovedPOs]
  static List<ProPurchaseOrder> filterApprovedPOs(List<ProPurchaseOrder> po) =>
      po.where((o) => o.isApproved).toList();

  /// Unapproved POs
  static List<ProPurchaseOrder> filterOthers(List<ProPurchaseOrder> orders) =>
      orders.where((po) => !po.isApproved).toList();

  /// copyWith method
  ProPurchaseOrder copyWith({
    String? id,
    String? storeNumber,
    String? poNumber,
    String? rfqNumber,
    String? requestedBy,
    SupplierLink? supplierLink,
    String? costCenterCode,
    WorkflowStatus? status,
    String? currencyCode,
    List<LineItem>? lineItems,
    TaxMode? taxMode,
    double? totalAmount,
    double? taxAmount,
    double? discountAmount,
    double? shippingAmount,
    double? shippingTaxAmount,
    String? paymentTerm,
    String? paymentMethod,
    String? notes,
    String? buyerContactPersonId,
    List<AddressInfo>? addresses,
    List<String>? attachments,
    String? termsAndConditions,
    DateTime? deliveryDate,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) {
    return ProPurchaseOrder(
      id: id ?? this.id,
      storeNumber: storeNumber ?? this.storeNumber,
      poNumber: poNumber ?? this.poNumber,
      rfqNumber: rfqNumber ?? this.rfqNumber,
      requestedBy: requestedBy ?? this.requestedBy,
      supplierLink: supplierLink ?? this.supplierLink,
      currencyCode: currencyCode ?? this.currencyCode,
      status: status ?? this.status,
      lineItems: lineItems ?? this.lineItems,
      taxMode: taxMode ?? this.taxMode,
      attachments: attachments ?? this.attachments,
      costCenterCode: costCenterCode ?? this.costCenterCode,
      addresses: addresses ?? this.addresses,
      taxAmount: taxAmount ?? this.taxAmount,
      shippingAmount: shippingAmount ?? this.shippingAmount,
      shippingTaxAmount: shippingTaxAmount ?? this.shippingTaxAmount,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      paymentTerm: paymentTerm ?? this.paymentTerm,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      buyerContactPersonId: buyerContactPersonId ?? this.buyerContactPersonId,
      deliveryDate: deliveryDate ?? this.deliveryDate,
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
    poNumber,
    rfqNumber,
    requestedBy,
    supplierLink,
    status,
    lineItems,
    taxMode,
    currencyCode,
    paymentTerm,
    paymentMethod,
    notes,
    buyerContactPersonId,
    attachments,
    costCenterCode,
    addresses,
    taxAmount,
    shippingAmount,
    shippingTaxAmount,
    termsAndConditions,
    deliveryDate ?? '',
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  /// ToList for ProPurchaseOrder [itemAsList]
  List<String> get itemAsList => [
    id,
    storeNumber,
    '$rfqNumber -> $poNumber',
    // supplierLink.supplierId,
    getPOStatus.toTitle,
    currencyCode.toTitle,
    paymentTerm.toTitle,
    paymentMethod.toTitle,
    getDeliveryDate,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataTableHeader => const [
    'ID',
    'Store #',
    'RFQ -> PO No.',
    // 'Supplier ID',
    'Status',
    'Currency',
    'Payment Terms',
    'Payment Method',
    'Delivery',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}

/*Message:
“PO #PO-2025-001 requires your approval”
📌 This does not approve anything — it only alerts.

Step 3: Approver opens dashboard (PULL)
The approver:
Opens Procurement → My Approvals
Sees list of pending items
Example filters:
Pending
Overdue
High value
By store / cost center

Step 4: Approver reviews and acts
From dashboard:
View PO details (this is button)
Download attachments (this is button)
Approve / Reject (this is button)
Add remarks (dialog & button)
*/
