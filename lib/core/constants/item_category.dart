// ---------------------------------------------
// 🧩 Item Category (Label-Driven Enum)
// ---------------------------------------------

import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/core/util/str_util.dart';

/// [ItemCategory] Item Categories for Purchase Requisition
enum ItemCategory {
  unknown,
  officeSupplies,
  itEquipment,
  electrical,
  furniture,
  stationery,
  maintenance,
  cleaning,
  safety,
  rawMaterials,
  finishedGoods,
  spareParts,
  marketing,
  uniform,
  vehicle,
  foodAndBeverage,
  service,
}

/* USAGE:
* final category = ItemCategory.officeSupplies;
* print(category.label); // Output: officeSupplies
* */
extension ItemCategoryExtension on ItemCategory {
  /// [getValue] Get the label for the specific enum value (e.g. "officeSupplies").
  String get getValue => EnumHelper<ItemCategory>(this).getValue;

  /// Returns a user-friendly label (e.g. "Office Supplies")
  String get getLabel => EnumHelper<ItemCategory>(this).getLabel;
}

class ItemCategoryHelper {
  /// [fromString] Converts String/Label to enum value.
  static ItemCategory fromString(String? value) =>
      EnumHelper.fromString<ItemCategory>(ItemCategory.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final list = EnumHelper.toStringList<ItemCategory>(ItemCategory.values);
    return [
      if (includeHeader) 'Item Category',
      ...list.map((a) => a.separateWord),
    ];
  }
}
