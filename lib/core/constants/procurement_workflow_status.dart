// -------------------------------------------
// ⚙️ Purchase Requisition Status Definitions
// --------------------------------------------

import 'package:assign_erp/core/util/enum_helper.dart';

/// [ProcurementWorkflowStatus] Procurement workflow status for PR, RFQ & PO.

enum ProcurementWorkflowStatus {
  /// [Common in PR, RFQ & PO]
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
  inactive, // Not in use anymore
}

// Procurement Type
enum ProcurementType { pr, rfq, po }

// Enum Extensions (Label / Value)
extension ProcurementWorkflowStatusX on ProcurementWorkflowStatus {
  /// [getName] Get the specific Enum Name (e.g. "underReview")
  String get getName => EnumHelper<ProcurementWorkflowStatus>(this).getName;

  /// Returns a user-friendly label (e.g. "Under Review")
  String get getLabel => EnumHelper<ProcurementWorkflowStatus>(this).getLabel;
}

// Generic statuses shared across all types
final Set<ProcurementWorkflowStatus> _genericStatus = {
  ProcurementWorkflowStatus.draft,
  ProcurementWorkflowStatus.pending,
  ProcurementWorkflowStatus.approved,
  ProcurementWorkflowStatus.rejected,
  ProcurementWorkflowStatus.cancelled,
};

// Full matrix for each procurement type
final Map<ProcurementType, Set<ProcurementWorkflowStatus>> _proStatusMatrix = {
  // PR: generic + PR-specific
  ProcurementType.pr: {
    ..._genericStatus,
    ProcurementWorkflowStatus.convertedToRFQ,
  },

  // RFQ: generic + RFQ-specific
  ProcurementType.rfq: {
    ..._genericStatus,
    ProcurementWorkflowStatus.issued,
    ProcurementWorkflowStatus.underReview,
    ProcurementWorkflowStatus.opened,
    ProcurementWorkflowStatus.closed,
    ProcurementWorkflowStatus.convertedToPO,
  },

  // PO: generic + PO-specific
  ProcurementType.po: {
    ..._genericStatus,
    ProcurementWorkflowStatus.sent,
    ProcurementWorkflowStatus.acknowledged,
    ProcurementWorkflowStatus.partlyFulfilled,
    ProcurementWorkflowStatus.fulfilled,
    ProcurementWorkflowStatus.invoiced,
    ProcurementWorkflowStatus.paid,
    ProcurementWorkflowStatus.closed,
  },
};

// Helper Class
class ProcurementStatusHelper {
  /// [fromString] Converts String/Label to enum value.
  static ProcurementWorkflowStatus fromString(String? value) =>
      EnumHelper.fromString<ProcurementWorkflowStatus>(
        ProcurementWorkflowStatus.values,
        value,
      );

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList({
    ProcurementType? type,
    bool includeHeader = false,
  }) {
    final statuses = _proStatusMatrix[type] ?? ProcurementWorkflowStatus.values;

    final list = statuses.map((e) => e).toList();
    return EnumHelper.toStringList<ProcurementWorkflowStatus>(list, 'Status');
  }

  /*/// Convert enum values to dropdown labels
  static List<String> toStringList2({
    ProcurementType? type,
    bool includeHeader = false,
  }) {
    final statuses = type == null
        ? ProcurementWorkflowStatus.values
        : _proStatusMatrix[type]!;

    final list = statuses.map((e) => e.getLabel).toList();

    return includeHeader ? ['Status', ...list] : list;
  }*/
}
