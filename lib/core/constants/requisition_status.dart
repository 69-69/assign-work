// ---------------------------
// ⚙️ Account Status Definitions
// ---------------------------

import 'package:assign_erp/core/util/str_util.dart';

// Purchase Requisition
enum RequisitionStatus { pending, approved, rejected, cancelled }

/* USAGE:
* final status = RequisitionStatus.pending;
* print(status.label); // Output: pending
* */
extension PriorityExtension on RequisitionStatus {
  String get getValue => getEnumName<RequisitionStatus>(this);
}

class PRStatusHelper {
  /// Get Account Status from String value [fromString].
  static RequisitionStatus fromString(String? value) =>
      RequisitionStatus.values.firstWhere(
        (e) => e.getValue == value,
        orElse: () => RequisitionStatus.pending,
      );

  /// [toStringList] Convert enum list to a list of strings
  static List<String> toStringList([bool includeLabel = true]) {
    final list = RequisitionStatus.values.map((e) => e.getValue).toList();
    return includeLabel ? ['pending', ...list] : list;
  }
}
