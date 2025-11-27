// -------------------------------------------
// ⚙️ Purchase Requisition Status Definitions
// --------------------------------------------

import 'package:assign_erp/core/util/enum_helper.dart';

/// [RequisitionStatus] Current workflow status of the Purchase Requisition
enum RequisitionStatus {
  draft,
  pending,
  approved,
  rejected,
  cancelled,
  convertedToRFQ,
}

/* USAGE:
* final status = RequisitionStatus.draft;
* print(status.label); // Output: draft
* */
extension RequisitionStatusExtension on RequisitionStatus {
  /// [getValue] Get the label for the specific enum value (e.g. "convertedToRFQ")
  String get getValue => EnumHelper<RequisitionStatus>(this).getValue;

  /// Returns a user-friendly label (e.g. "converted To RFQ")
  String get getLabel => EnumHelper<RequisitionStatus>(this).getLabel;
}

class PRStatusHelper {
  /// [fromString] Converts String/Label to enum value.
  static RequisitionStatus fromString(String? value) =>
      EnumHelper.fromString<RequisitionStatus>(RequisitionStatus.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final list = EnumHelper.toStringList<RequisitionStatus>(
      RequisitionStatus.values,
    );
    return includeHeader ? ['PR status', ...list] : list;
  }
}
