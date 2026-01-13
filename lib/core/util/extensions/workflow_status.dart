// -------------------------------------------
// ⚙️ Purchase Requisition Status Definitions
// --------------------------------------------

import 'package:assign_erp/core/util/enum_util.dart';

/// [WorkflowStatus] Workflow status for PR, RFQ, PO & Sales Quotation(SQ).
enum WorkflowStatus {
  /// [Common in PR, RFQ & PO, SQ]
  /// --------------------------
  draft, // Created, not yet issued
  amended, // Amended, not yet issued
  pending, // Awaiting vendor responses
  submitted, // Internal review by Company's procurement team
  approved, // Evaluation completed, selected vendor approved internally
  rejected, // Rejected (no award)
  cancelled,

  /// [PR: Purchase Requisition]
  /// --------------------------
  convertedToRFQ, // PR approved and converted to a RFQ
  /// [RFQ: Request for Quotation]
  /// ----------------------------
  issued, // Sent to vendors for quoting
  underReview, // Vendor quotes received, being evaluated
  opened, // Quotes officially opened for review
  convertedToPO, // RFQ approved and awarded to a vendor, converted to a Purchase Order
  /// [PO: Purchase Order]
  /// --------------------
  sent, // Sent to vendor for acknowledgement
  acknowledged, // Acknowledgement received from vendor
  partlyFulfilled,
  fulfilled, // Purchase order fulfilled and ready for invoicing
  invoiced, // Invoice generated for the PO
  paid,

  /// [RFQ & PO]
  /// ------------------
  closed, // No more submissions accepted
  expired, // Not in use anymore, that's inactive
}

// Workflow Type
enum WorkflowType { pr, rfq, po, sq }

// Enum Extensions (Label / Value)
extension WorkflowStatusExtension on WorkflowStatus {
  /// [getName] Get the specific Enum Name (e.g. "underReview")
  String get getName => EnumUtil<WorkflowStatus>(this).getName;

  /// Returns a user-friendly label (e.g. "Under Review")
  String get getLabel => EnumUtil<WorkflowStatus>(this).getLabel;
}

// Generic statuses shared across all types
final Set<WorkflowStatus> _genericStatus = {
  WorkflowStatus.draft,
  WorkflowStatus.pending,
  WorkflowStatus.approved,
  WorkflowStatus.rejected,
  WorkflowStatus.cancelled,
};

// Full matrix for each Workflow type
final Map<WorkflowType, Set<WorkflowStatus>> _statusMatrix = {
  // PR: generic + PR-specific
  WorkflowType.pr: {..._genericStatus, WorkflowStatus.convertedToRFQ},

  // RFQ: generic + RFQ-specific
  WorkflowType.rfq: {
    ..._genericStatus,
    WorkflowStatus.issued,
    WorkflowStatus.underReview,
    WorkflowStatus.opened,
    WorkflowStatus.closed,
    WorkflowStatus.convertedToPO,
  },

  // PO: generic + PO-specific
  WorkflowType.po: {
    ..._genericStatus,
    WorkflowStatus.sent,
    WorkflowStatus.acknowledged,
    WorkflowStatus.partlyFulfilled,
    WorkflowStatus.fulfilled,
    WorkflowStatus.invoiced,
    WorkflowStatus.paid,
    WorkflowStatus.closed,
  },

  // SQ: generic + SQ-specific
  WorkflowType.sq: {
    ..._genericStatus,
    WorkflowStatus.draft,
    WorkflowStatus.amended,
    WorkflowStatus.submitted,
    WorkflowStatus.approved,
    WorkflowStatus.rejected,
    WorkflowStatus.expired,
    WorkflowStatus.cancelled,
  },
};

// Helper Class
class WorkflowStatusUtil {
  /// [fromString] Converts String/Label to enum value.
  static WorkflowStatus fromString(String? value) =>
      EnumUtil.fromString<WorkflowStatus>(WorkflowStatus.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList({
    WorkflowType? type,
    bool includeHeader = false,
  }) {
    final statuses = _statusMatrix[type] ?? WorkflowStatus.values;

    final list = statuses.map((e) => e).toList();
    return EnumUtil.toStringList<WorkflowStatus>(list, 'Status');
  }
}
