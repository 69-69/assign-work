/*Example of a WorkFlow:
Draft: User creates the requisition.
Submitted: User submits the requisition for approval.
Under-Review: After submission, the requisition goes through a review.
Approved: If the requisition is approved, it triggers the creation of an RFQ or PO.
Fulfilled: The order is fulfilled and the requisition is considered completed.
Cancelled: If it’s canceled at any point before approval or fulfillment.*/
import 'package:assign_erp/core/constants/erp_priority_enum.dart';
import 'package:assign_erp/core/constants/requisition_status.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';

/// [PurchaseRequisition] Workflow Example ([Purchase Requisition] → RFQ → PO):
/// 1. User creates the requisition.
/// 2. User submits the requisition for approval.
/// 3. After submission, the requisition goes through a review.
/// 4. If the requisition is approved, it triggers the creation of an RFQ or PO.
/// 5. The order is fulfilled and the requisition is considered completed.
/// 6. If it’s canceled at any point before approval or fulfillment.
///
var _today = DateTime.now();

class PurchaseRequisition {
  final String id;
  final String storeNumber;
  final String prNumber; // Purchase Requisition number
  final String departCode;
  final ERPPriority priority;
  final List<RequisitionLineItem> lineItems;
  final List<String> attachments;
  final RequisitionStatus status;

  /// [requestDate] Business date when the requisition was initiated or intended
  final DateTime? requestDate;

  /// [neededByDate] Target date by which the requested items/services are required
  final DateTime? neededByDate;

  /// [createdAt] System timestamp when the PR was recorded in the system (audit trail)
  final DateTime createdAt;
  final String createdBy;
  final String updatedBy;
  final DateTime updatedAt;

  PurchaseRequisition({
    this.id = '',
    required this.prNumber,
    required this.storeNumber,
    this.priority = ERPPriority.normal,
    this.status = RequisitionStatus.pending,
    required this.lineItems,
    required this.attachments,
    required this.departCode,
    DateTime? requestDate,
    DateTime? neededByDate,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       requestDate = createdAt ?? _today,
       neededByDate = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  // Optional: add fromJson / toJson for serialization
  factory PurchaseRequisition.fromJson(
    Map<String, dynamic> map, {
    String? docId,
  }) {
    return PurchaseRequisition(
      id: docId ?? map['id'] ?? '',
      prNumber: map['prNumber'],
      departCode: map['departCode'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      priority: PriorityHelper.fromString(map['priority']),
      status: PRStatusHelper.fromString(map['status']),
      lineItems: (map['lineItems'] as List)
          .map((item) => RequisitionLineItem.fromJson(item))
          .toList(),
      attachments: List<String>.from(map['attachments'] ?? []),
      requestDate: toDateTimeFn(map['requestDate']),
      neededByDate: toDateTimeFn(map['neededByDate']),
      createdBy: map['createdBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt'] ?? '$_today'),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(map['updatedAt'] ?? '$_today'),
    );
  }

  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'prNumber': prNumber,
    'storeNumber': storeNumber,
    'departCode': departCode,
    'priority': priority,
    'lineItems': lineItems.map((item) => item.toMap()).toList(),
    'attachments': attachments,
    'status': status,
    'requestDate': requestDate,
    'neededByDate': neededByDate,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt,
  };

  Map<String, dynamic> toMap() {
    final newMap = _mapTemp();
    newMap['requestDate'] = requestDate?.toISOString;
    newMap['neededByDate'] = neededByDate?.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  Map<String, dynamic> toCache() {
    final newMap = _mapTemp();
    newMap['requestDate'] = requestDate?.millisecondsSinceEpoch;
    newMap['neededByDate'] = neededByDate?.millisecondsSinceEpoch;
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
    departCode: '',
    createdBy: '',
  );

  String get getPriority => priority.name;
  String get getRequisitionStatus => status.name;
  String get getRequestDate => requestDate.dateOnly;
  String get getNeededByDate => neededByDate.dateOnly;

  /// Returns true if this instance is the singleton [empty] PR.
  /// Use this to check if the PR is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, PurchaseRequisition.empty);
  bool get isNotEmpty => lineItems.isNotEmpty;

  PurchaseRequisition copyWith({
    String? id,
    String? prNumber,
    String? storeNumber,
    String? departCode,
    ERPPriority? priority,
    List<RequisitionLineItem>? lineItems,
    List<String>? attachments,
    RequisitionStatus? status,
    DateTime? requestDate,
    DateTime? neededByDate,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return PurchaseRequisition(
      id: id ?? this.id,
      prNumber: prNumber ?? this.prNumber,
      storeNumber: storeNumber ?? this.storeNumber,
      departCode: departCode ?? this.departCode,
      priority: priority ?? this.priority,
      lineItems: lineItems ?? this.lineItems,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      neededByDate: neededByDate ?? this.neededByDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RequisitionLineItem {
  final String itemName;
  final int quantity;
  final String reason;

  RequisitionLineItem({
    required this.itemName,
    required this.quantity,
    required this.reason,
  });

  factory RequisitionLineItem.fromJson(Map<String, dynamic> json) {
    return RequisitionLineItem(
      itemName: json['itemName'],
      quantity: json['quantity'],
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'itemName': itemName, 'quantity': quantity, 'reason': reason};
  }

  RequisitionLineItem copyWith({
    String? itemName,
    int? quantity,
    String? reason,
  }) {
    return RequisitionLineItem(
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
    );
  }
}

/*final requisition = PurchaseRequisition(
  prNumber: 'REQ-2025-001',
  createdBy: 'Steve Tony',
  requestDate: DateTime.now(),
  priority: 'urgent',
  neededByDate: DateTime.now().add(Duration(days: 7)),
  lineItems: [
    RequisitionLineItem(
      itemName: 'Laptop - Dell XPS 13',
      quantity: 5,
      reason: 'For onboarding new employees',
    ),
    RequisitionLineItem(
      itemName: 'USB-C Docking Station',
      quantity: 5,
      reason: 'To support multiple monitors',
    ),
  ],
  attachments: ['specs.pdf', 'memo_it_request.docx'],
  status: 'pending',
);*/
