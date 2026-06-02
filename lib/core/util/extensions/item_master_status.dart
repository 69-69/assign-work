// ---------------------------
// ⚙️ Account Status Definitions
// ---------------------------

import 'package:assign_erp/core/util/enum_util.dart';

enum ItemMasterStatus { active, unactive, obsolete, draft }

/* USAGE:
* final status = ItemMasterStatus.active;
* print(status.label); // Output: active
* */
extension ItemMasterStatusExtension on ItemMasterStatus {
  /// [getName] Get the specific Enum Name
  String get getName => EnumUtil<ItemMasterStatus>(this).getName;
}

class ItemMasterStatusUtil {
  /// [fromString] Converts String/Label to enum value.
  static ItemMasterStatus fromString(String? value) =>
      EnumUtil.fromString<ItemMasterStatus>(ItemMasterStatus.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
final label = includeHeader ? 'Status' : '';
return EnumUtil.toStringList<ItemMasterStatus>(ItemMasterStatus.values, label);}
}
