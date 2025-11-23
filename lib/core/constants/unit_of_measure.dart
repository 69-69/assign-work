// ---------------------------------------------
// 📏 Unit of Measure (Label-Driven Enum)
// ---------------------------------------------

import 'package:assign_erp/core/util/enum_helper.dart';

/// [UnitOfMeasure] Unit of Measure for Products/Services
enum UnitOfMeasure {
  unknown,
  pieces,
  box,
  pack,
  set,
  kilogram,
  gram,
  liter,
  milliliter,
  meter,
  centimeter,
  foot,
  roll,
  sheet,
  bottle,
  can,
  hour,
  day,
  service,
}

/* USAGE:
* final status = UnitOfMeasure.box;
* print(status.label); // Output: box
* */
extension UOMExtension on UnitOfMeasure {
  /// [getValue] Get the label for the specific enum value (e.g. "packOfBox")
  String get getValue => EnumHelper<UnitOfMeasure>(this).getValue;

  /// Returns a user-friendly label (e.g. "pack of box")
  String get getLabel => EnumHelper<UnitOfMeasure>(this).getLabel;
}

class UOMHelper {
  /// Converts String/Label to enum value [fromString].
  static UnitOfMeasure fromString(String? value) =>
      EnumHelper.fromString<UnitOfMeasure>(UnitOfMeasure.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final list = EnumHelper.toStringList<UnitOfMeasure>(UnitOfMeasure.values);
    return includeHeader ? ['Unit of Measure', ...list] : list;
  }
}
