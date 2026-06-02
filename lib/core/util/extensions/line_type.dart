// ---------------------------
// ⚙️ Hosting Type Definitions
// ---------------------------

import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/core/util/str_util.dart';

enum LineType { material, service }

extension LineTypeExtension on LineType {
  /// [getName] Get the specific Enum Name (e.g. "material")
  String get getName => EnumUtil<LineType>(this).getName;

  /// Returns a user-friendly label (e.g. "material")
  String get getLabel => EnumUtil<LineType>(this).getLabel;

  /// Check if type is material.
  bool get isMaterial =>
      getLabel.toLowerAll.contains(LineType.material.getLabel.toLowerAll);

  bool get isService =>
      getLabel.toLowerAll.contains(LineType.service.getLabel.toLowerAll);
}

class LineTypeUtil {
  /// Check if type is valid.
  static bool isExist(String type) =>
      EnumUtil.isValid<LineType>(LineType.values, type, false);

  /// Check if type is material.
  static bool isMaterial(String type) =>
      LineType.material.getLabel.toLowerAll.contains(type.toLowerAll);

  /// [fromString] Converts String/Label to enum value.
  static LineType fromString(String? value) =>
      EnumUtil.fromString<LineType>(LineType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'line type' : '';
    return EnumUtil.toStringList<LineType>(LineType.values, label);
  }
}
