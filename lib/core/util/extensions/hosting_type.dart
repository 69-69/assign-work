// ---------------------------
// ⚙️ Hosting Type Definitions
// ---------------------------

import 'package:assign_erp/core/util/enum_util.dart';

enum HostingType { onPremise, cloud, hybrid }

/* USAGE:
* final type = HostingType.cloud;
* print(type.label); // Output: cloud
* */
extension HostingTypeExtension on HostingType {
  /// [getName] Get the specific Enum Name
  String get getName => EnumUtil<HostingType>(this).getName;
}

class HostingTypeUtil {
  /// [fromString] Converts String/Label to enum value.
  static HostingType fromString(String? value) =>
      EnumUtil.fromString<HostingType>(HostingType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'hosting type' : '';
    return EnumUtil.toStringList<HostingType>(HostingType.values, label);
  }
}
