// ---------------------------
// ⚙️ Account Status Definitions
// ---------------------------

import 'package:assign_erp/core/util/str_util.dart';

// Priority
enum ERPPriority { urgent, normal }

/* USAGE:
* final priority = ERPPriority.urgent;
* print(priority.label); // Output: urgent
* */
extension PriorityExtension on ERPPriority {
  String get getValue => getEnumName<ERPPriority>(this);
}

class PriorityHelper {
  /// Get Account Status from String value [fromString].
  static ERPPriority fromString(String? value) => ERPPriority.values.firstWhere(
    (e) => e.getValue == value,
    orElse: () => ERPPriority.normal,
  );

  /// [toStringList] Convert enum list to a list of strings
  static List<String> toStringList([bool includeLabel = true]) {
    final list = ERPPriority.values.map((e) => e.getValue).toList();
    return includeLabel ? ['priority', ...list] : list;
  }
}
