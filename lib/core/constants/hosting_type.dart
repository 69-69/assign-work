// ---------------------------
// ⚙️ Hosting Type Definitions
// ---------------------------

import 'package:assign_erp/core/util/enum_helper.dart';

enum HostingType { onPremise, cloud, hybrid }

/* USAGE:
* final type = HostingType.cloud;
* print(type.label); // Output: cloud
* */
extension HostingTypeExtension on HostingType {
  /// [getValue] Get the label for the specific enum value (e.g. "onPremise").
  String get getValue => EnumHelper<HostingType>(this).getValue;
}

class HostingTypeHelper {
  /// [fromString] Converts String/Label to enum value.
  static HostingType fromString(String? value) =>
      EnumHelper.fromString<HostingType>(HostingType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'hosting type' : '';
    return EnumHelper.toStringList<HostingType>(HostingType.values, label);
  }
}
