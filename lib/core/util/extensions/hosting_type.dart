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
  /// [getName] Get the specific Enum Name
  String get getName => EnumHelper<HostingType>(this).getName;
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
