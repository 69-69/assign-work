// ---------------------------
// ⚙️ Hosting Type Definitions
// ---------------------------

import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/core/util/str_util.dart';

enum LineItemType { material, service }

extension LineItemTypeExtension on LineItemType {
  /// [getName] Get the specific Enum Name (e.g. "material")
  String get getName => EnumHelper<LineItemType>(this).getName;

  /// Returns a user-friendly label (e.g. "material")
  String get getLabel => EnumHelper<LineItemType>(this).getLabel;
}

class LineItemTypeHelper {
  /// Check if type is valid.
  static bool isExist(String type) =>
      EnumHelper.isValid<LineItemType>(LineItemType.values, type, false);

  /// Check if type is material.
  static bool isMaterial(String type) =>
      LineItemType.material.getLabel.toLowerAll.contains(type.toLowerAll);

  /// [fromString] Converts String/Label to enum value.
  static LineItemType fromString(String? value) =>
      EnumHelper.fromString<LineItemType>(LineItemType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'line item type' : '';
    return EnumHelper.toStringList<LineItemType>(LineItemType.values, label);
  }
}
