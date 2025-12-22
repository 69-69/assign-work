// ---------------------------
// ⚙️ Account Status Definitions
// ---------------------------

import 'package:assign_erp/core/util/enum_helper.dart';

/// [ERPPriority] Priority levels for PR, RFQ, PO, SO, etc.
enum ERPPriority {
  // Standard approval and fulfillment timeline.
  normal,
  // Fast-track approval, procurement might prioritize it.
  urgent,
  // Immediate attention, possibly overrides normal approval hierarchy.
  critical,
}

/* USAGE:
* final priority = ERPPriority.urgent;
* print(priority.label); // Output: urgent
* */
extension ERPPriorityExtension on ERPPriority {
  /// [getName] Get the specific Enum Name
  String get getName => EnumHelper<ERPPriority>(this).getName;

  /// Returns a user-friendly label
  String get getLabel => EnumHelper<ERPPriority>(this).getLabel;
}

class PriorityHelper {
  /// [fromString] Converts String/Label to enum value.
  static ERPPriority fromString(String? value) =>
      EnumHelper.fromString<ERPPriority>(ERPPriority.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final list = EnumHelper.toStringList<ERPPriority>(ERPPriority.values);
    return includeHeader ? ['Priority', ...list] : list;
  }
}
