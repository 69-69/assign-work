// ---------------------------
// ⚙️ Hosting Type Definitions
// ---------------------------

import 'package:assign_erp/core/util/str_util.dart';

enum HostingType { cloud, onPremise, hybrid }

/* USAGE:
* final type = HostingType.cloud;
* print(type.label); // Output: cloud
* */
extension HostingTypeExtension on HostingType {
  String get getValue => getEnumName<HostingType>(this);
}

class HostingTypeHelper {
  static HostingType fromString(String value) {
    return HostingType.values.firstWhere(
      (e) => e.getValue == value,
      orElse: () => HostingType.onPremise,
    );
  }

  /// [toStringList] Convert enum list to a list of strings
  static List<String> toStringList([bool includeLabel = true]) {
    final list = HostingType.values.map((e) => e.getValue).toList();
    return includeLabel ? ['hosting type', ...list] : list;
  }
}
