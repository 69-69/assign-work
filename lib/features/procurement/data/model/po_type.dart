// ---------------------------------------------
// 📏 Unit of Measure (Label-Driven Enum)
// ---------------------------------------------

import 'package:assign_erp/core/util/enum_helper.dart';

/// [POType]
/// Product PO (Goods PO):
///  - PO Type: Standard, Subcontracting, Consignment (for product procurement).
/// Service PO (Services):
///  - PO Type: Services (or sometimes, Service Order or Service Procurement).
enum POType { standard, subcontracting, consignment, services }

/* USAGE:
* final status = POType.box;
* print(status.label); // Output: box
* */
extension POTypeExtension on POType {
  /// [getValue] Get the label for the specific enum value (e.g. "standard")
  String get getValue => EnumHelper<POType>(this).getValue;

  /// Returns a user-friendly label (e.g. "standard")
  String get getLabel => EnumHelper<POType>(this).getLabel;
}

class POTypeHelper {
  /// Converts String/Label to enum value [fromString].
  static POType fromString(String? value) =>
      EnumHelper.fromString<POType>(POType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final list = EnumHelper.toStringList<POType>(POType.values);
    return includeHeader ? ['PO Type', ...list] : list;
  }
}
