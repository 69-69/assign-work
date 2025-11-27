/*Example of a WorkFlow:
Draft: User creates the requisition.
Submitted: User submits the requisition for approval.
Under-Review: After submission, the requisition goes through a review.
Approved: If the requisition is approved, it triggers the creation of an RFQ or PO.
Fulfilled: The order is fulfilled and the requisition is considered completed.
Cancelled: If it’s canceled at any point before approval or fulfillment.*/
import 'package:assign_erp/core/constants/erp_priority_enum.dart';
import 'package:assign_erp/core/constants/item_category.dart';
import 'package:assign_erp/core/constants/requisition_status.dart';
import 'package:assign_erp/core/constants/unit_of_measure.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/procurement/data/model/pro_line_item_model.dart';
import 'package:equatable/equatable.dart';

/// [PurchaseRequisition] Workflow Example ([Purchase Requisition] → RFQ → PO):
/// 1. User creates the requisition.
/// 2. User submits the requisition for approval.
/// 3. After submission, the requisition goes through a review.
/// 4. If the requisition is approved, it triggers the creation of an RFQ or PO.
/// 5. The order is fulfilled and the requisition is considered completed.
/// 6. If it’s canceled at any point before approval or fulfillment.
///

class PurchaseRequisition extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String storeNumber;
  final String prNumber; // Purchase Requisition number
  final String departmentCode; // Department that requested the PR
  final String requestedBy; // Who requested the PR
  final String purpose; // Purpose / Justification (main reason for the PR)
  final ERPPriority priority;
  final RequisitionStatus status;
  final List<String> attachments;
  final List<PRLineItem> lineItems;

  /// [requestDate] Business date when the requisition was initiated or intended
  final DateTime? requestDate;

  /// [expectedDate] Target date by which the requested items/services are required
  final DateTime? expectedDate;

  /// [createdAt] System timestamp when the PR was recorded in the system (audit trail)
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;

  /// [history] Audit trail: track all changes made to the PR
  final List<AuditLog> history;

  PurchaseRequisition({
    this.id = '',
    required this.prNumber,
    required this.storeNumber,
    this.priority = ERPPriority.normal,
    this.status = RequisitionStatus.draft,
    required this.purpose,
    required this.lineItems,
    this.attachments = const [],
    required this.departmentCode,
    required this.requestedBy,
    DateTime?
    requestDate, // Business date when the requisition was initiated or intended
    DateTime? expectedDate,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) : history = history ?? [],
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today,
       requestDate = requestDate ?? _today,
       expectedDate = expectedDate ?? _today;

  // Optional: add fromJson / toJson for serialization
  factory PurchaseRequisition.fromMap(Map<String, dynamic> map, {String? id}) {
    return PurchaseRequisition(
      id: id ?? map['id'] ?? '',
      prNumber: map['prNumber'],
      departmentCode: map['departmentCode'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      status: PRStatusHelper.fromString(map['status']),
      priority: PriorityHelper.fromString(map['priority']),
      purpose: map['purpose'] ?? '',
      lineItems: (map['lineItems'] as List? ?? [])
          .map((i) => PRLineItem.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
      attachments: List<String>.from(map['attachments'] ?? []),
      requestedBy: map['requestedBy'] ?? '',
      requestDate: toDateTimeFn(map['requestDate']),
      expectedDate: toDateTimeFn(map['expectedDate']),
      createdBy: map['createdBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt'] ?? '$_today'),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(map['updatedAt'] ?? '$_today'),
      history: (map['history'] as List? ?? [])
          .map((i) => AuditLog.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
    );
  }

  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'storeNumber': storeNumber,
    'prNumber': prNumber,
    'departmentCode': departmentCode,
    'status': getPRStatus,
    'priority': getPriority,
    'purpose': purpose,
    'lineItems': lineItems.map((i) => i.toMap()).toList(),
    'attachments': attachments,
    'requestedBy': requestedBy,
    'requestDate': requestDate,
    'expectedDate': expectedDate,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt,
    'history': history.map((i) => i.toMap()).toList(),
  };

  Map<String, dynamic> toMap() {
    final newMap = _mapTemp();
    newMap['requestDate'] = requestDate?.toISOString;
    newMap['expectedDate'] = expectedDate?.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  Map<String, dynamic> toCache() {
    final newMap = _mapTemp();
    newMap['requestDate'] = requestDate?.millisecondsSinceEpoch;
    newMap['expectedDate'] = expectedDate?.millisecondsSinceEpoch;
    newMap['createdAt'] = createdAt.millisecondsSinceEpoch;
    newMap['updatedAt'] = updatedAt.millisecondsSinceEpoch;

    return {'id': id, 'data': newMap};
  }

  /// A singleton instance representing an empty/default PurchaseRequisition.
  /// Used as a fallback when no matching PR is found.
  static final PurchaseRequisition empty = PurchaseRequisition(
    prNumber: '',
    storeNumber: '',
    lineItems: const [],
    attachments: const [],
    departmentCode: '',
    createdBy: '',
    requestedBy: '',
    purpose: '',
  );

  /// Returns true if this instance is the singleton [empty] PR.
  /// Use this to check if the PR is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, PurchaseRequisition.empty);

  bool get isNotEmpty => lineItems.isNotEmpty;

  String get getPriority => priority.getLabel;

  String get getPRStatus => status.getLabel;

  bool get isApproved => getPRStatus == 'approved';

  String get getRequestDate => requestDate.dateOnly;

  String get getExpectedDate => expectedDate.dateOnly;

  String get getCreatedAt => createdAt.toStandardDT;

  String get getUpdatedAt => updatedAt.toStandardDT;

  bool get isReadyForApproval =>
      lineItems.isNotEmpty && departmentCode.isNotEmpty;

  bool get isOverdue => expectedDate != null && expectedDate!.isBefore(_today);

  bool filterByAny(String filter) => itemAsList.any(
    (item) =>
        item.contains(filter) ||
        purpose.contains(filter) ||
        lineItems.any((e) => e.filterByAny(filter)),
  );

  /// Approved PRs
  static List<PurchaseRequisition> filterApprovedPR(
    List<PurchaseRequisition> prs,
  ) => prs.where((pr) => pr.isApproved).toList();

  /// Unapproved PRs
  static List<PurchaseRequisition> filterOthers(
    List<PurchaseRequisition> prs,
  ) => prs.where((pr) => !pr.isApproved).toList();

  static PurchaseRequisition findPRById(
    List<PurchaseRequisition> prs,
    String prId,
  ) => prs.firstWhere(
    (pr) => pr.id == prId,
    orElse: () => PurchaseRequisition.empty,
  );

  PurchaseRequisition copyWith({
    String? id,
    String? prNumber,
    String? storeNumber,
    String? departmentCode,
    String? requestedBy,
    String? purpose,
    ERPPriority? priority,
    List<PRLineItem>? lineItems,
    List<String>? attachments,
    RequisitionStatus? status,
    DateTime? requestDate,
    DateTime? expectedDate,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) => PurchaseRequisition(
    id: id ?? this.id,
    prNumber: prNumber ?? this.prNumber,
    storeNumber: storeNumber ?? this.storeNumber,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    purpose: purpose ?? this.purpose,
    departmentCode: departmentCode ?? this.departmentCode,
    requestedBy: requestedBy ?? this.requestedBy,
    lineItems: lineItems ?? this.lineItems,
    attachments: attachments ?? this.attachments,
    requestDate: requestDate ?? this.requestDate,
    expectedDate: expectedDate ?? this.expectedDate,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedBy: updatedBy ?? this.updatedBy,
    updatedAt: updatedAt ?? this.updatedAt,
    history: history ?? this.history,
  );

  @override
  List<Object?> get props => [
    id,
    storeNumber,
    prNumber,
    departmentCode,
    priority,
    status,
    lineItems,
    attachments,
    expectedDate,
    requestedBy,
    requestDate,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
    history,
  ];

  /// For UI display only
  List<String> get itemAsList => [
    id,
    storeNumber,
    prNumber,
    getPriority.toTitle,
    getPRStatus.toTitle,
    departmentCode,
    requestedBy.toTitle,
    getRequestDate,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  /// For UI Header display only
  static List<String> get dataTableHeader => const [
    'ID',
    'Store No.',
    'PR Number',
    'Priority',
    'Status',
    'Department',
    'Request By',
    'Request At',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}

/// [PRLineItem] Represents an individual line item in a purchase requisition Model
class PRLineItem extends ProLineItem {
  const PRLineItem({
    /// Inherited from [ProLineItem]
    required super.itemName,
    required super.quantity,
    required super.category,
    required super.unitOfMeasure,
    required super.notes,
  });

  factory PRLineItem.fromMap(Map<String, dynamic> map) {
    return PRLineItem(
      itemName: map['itemName'] ?? '',
      quantity: int.tryParse('${map['quantity']}') ?? 0,
      category: ItemCategoryHelper.fromString(map['category']),
      unitOfMeasure: UOMHelper.fromString(map['unitOfMeasure']),
      notes: map['notes'] ?? '',
    );
  }

  /// For UI Header display only
  static List<String> get dataTableHeader => ProLineItem.dataTableHeader;
}
