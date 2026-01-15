// ---------------------------------------------
// 🧩 Item Category (Label-Driven Enum)
// ---------------------------------------------

import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/core/util/str_util.dart';

/// [ItemCategory] Item Categories for Purchase Requisition
enum ItemCategory {
  // Common / Unknown
  unknown,

  /// Materials / Products
  materialCategories, // an identifier purposes only
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

  /// Services / Professional Work
  serviceCategories, // an identifier purposes only
  consulting,
  maintenanceService,
  repairService,
  installation,
  cleaningService,
  securityService,
  training,
  transportation,
  itSupport,
  cloudService,
  logistics,
  cateringService,
  subscriptionService,
  labor,
}

/* USAGE:
* final category = ItemCategory.officeSupplies;
* print(category.label); // Output: officeSupplies
* */
extension ItemCategoryExtension on ItemCategory {
  /// [getName] Get the specific Enum Name (e.g. "officeSupplies")
  String get getName => EnumUtil<ItemCategory>(this).getName;

  /// Returns a user-friendly label (e.g. "Office Supplies")
  String get getLabel => EnumUtil<ItemCategory>(this).getLabel;
}

class ItemCategoryUtil {
  /// [fromString] Converts String/Label to enum value.
  static ItemCategory fromString(String? value) =>
      EnumUtil.fromString<ItemCategory>(ItemCategory.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList({
    bool isService = false,
    bool includeHeader = true,
  }) {
    List<ItemCategory> categories = _filterByType(isService);
    final list = EnumUtil.toStringList<ItemCategory>(categories);

    return [
      if (includeHeader)
        '${isService ? 'Service:' : 'Material: Product'} Category',
      ...list.map((a) => a.separateWord),
    ];
  }

  static List<ItemCategory> _filterByType(bool isService) {
    final categories = <ItemCategory>[];

    bool add = false;
    for (final cat in ItemCategory.values) {
      if (cat == ItemCategory.materialCategories) {
        add = !isService; // start adding material categories if isService=false
        continue; // skip the identifier itself
      }
      if (cat == ItemCategory.serviceCategories) {
        add = isService; // start adding service categories if isService=true
        continue; // skip the identifier itself
      }

      if (add) {
        categories.add(cat);
      }
    }
    return categories;
  }
}
