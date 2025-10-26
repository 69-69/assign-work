/*Example of a WorkFlow:
Draft: User creates the requisition.
Submitted: User submits the requisition for approval.
Under-Review: After submission, the requisition goes through a review.
Approved: If the requisition is approved, it triggers the creation of an RFQ or PO.
Fulfilled: The order is fulfilled and the requisition is considered completed.
Cancelled: If it’s canceled at any point before approval or fulfillment.*/
/// [PurchaseRequisition] Workflow Example ([Purchase Requisition] → RFQ → PO):
/// 1. User creates the requisition.
/// 2. User submits the requisition for approval.
/// 3. After submission, the requisition goes through a review.
/// 4. If the requisition is approved, it triggers the creation of an RFQ or PO.
/// 5. The order is fulfilled and the requisition is considered completed.
/// 6. If it’s canceled at any point before approval or fulfillment.
///
class PurchaseRequisition {
  final String prNumber; // Purchase Requisition number
  final String requestedBy; // Employee or department name/ID
  final DateTime requestDate;
  final String priority; // 'urgent' or 'normal'
  final DateTime neededByDate;
  final String purpose;
  final List<RequisitionLineItem> lineItems;
  final List<String> attachments; // File paths or URLs
  final String status; // e.g., 'pending', 'approved', 'rejected'

  PurchaseRequisition({
    required this.prNumber,
    required this.requestedBy,
    required this.requestDate,
    required this.priority,
    required this.neededByDate,
    required this.purpose,
    required this.lineItems,
    required this.attachments,
    required this.status,
  });

  // Optional: add fromJson / toJson for serialization
  factory PurchaseRequisition.fromJson(Map<String, dynamic> json) {
    return PurchaseRequisition(
      prNumber: json['prNumber'],
      requestedBy: json['requestedBy'],
      requestDate: DateTime.parse(json['requestDate']),
      priority: json['priority'],
      neededByDate: DateTime.parse(json['neededByDate']),
      purpose: json['purpose'],
      lineItems: (json['lineItems'] as List)
          .map((item) => RequisitionLineItem.fromJson(item))
          .toList(),
      attachments: List<String>.from(json['attachments'] ?? []),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'prNumber': prNumber,
    'requestedBy': requestedBy,
    'requestDate': requestDate.toIso8601String(),
    'priority': priority,
    'neededByDate': neededByDate.toIso8601String(),
    'purpose': purpose,
    'lineItems': lineItems.map((item) => item.toJson()).toList(),
    'attachments': attachments,
    'status': status,
  };
}

class RequisitionLineItem {
  final String itemNameOrCategory;
  final int estimatedQuantity;
  final String reason;

  RequisitionLineItem({
    required this.itemNameOrCategory,
    required this.estimatedQuantity,
    required this.reason,
  });

  factory RequisitionLineItem.fromJson(Map<String, dynamic> json) {
    return RequisitionLineItem(
      itemNameOrCategory: json['itemNameOrCategory'],
      estimatedQuantity: json['estimatedQuantity'],
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemNameOrCategory': itemNameOrCategory,
      'estimatedQuantity': estimatedQuantity,
      'reason': reason,
    };
  }
}

final requisition = PurchaseRequisition(
  prNumber: 'REQ-2025-001',
  requestedBy: 'IT Department',
  requestDate: DateTime.now(),
  priority: 'urgent',
  neededByDate: DateTime.now().add(Duration(days: 7)),
  purpose: 'Replace old laptops for new hires',
  lineItems: [
    RequisitionLineItem(
      itemNameOrCategory: 'Laptop - Dell XPS 13',
      estimatedQuantity: 5,
      reason: 'For onboarding new employees',
    ),
    RequisitionLineItem(
      itemNameOrCategory: 'USB-C Docking Station',
      estimatedQuantity: 5,
      reason: 'To support multiple monitors',
    ),
  ],
  attachments: ['specs.pdf', 'memo_it_request.docx'],
  status: 'pending',
);
