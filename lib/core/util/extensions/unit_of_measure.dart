// ---------------------------------------------
// 📏 Unit of Measure (Label-Driven Enum)
// ---------------------------------------------

import 'package:assign_erp/core/util/enum_util.dart';

/// [UnitOfMeasure] Unit of Measure for Products/Services
enum UnitOfMeasure {
  // General
  unknown,
  unit,

  // Goods UOMs
  pieces,
  each,
  carton,
  box,
  pack,
  set,
  pair,
  dozen,
  bundle,
  pallet,
  bag,
  bottle,
  can,
  tube,
  roll,
  sheet,

  // Weight
  gram,
  kilogram,
  ton,
  metricTon,

  // Volume
  liter,
  milliliter,
  gallon,
  quart,
  pint,

  // Length & Area & Volume
  meter,
  centimeter,
  foot,
  yard,
  squareMeter,
  cubicMeter,

  // Services UOMs
  hour,
  day,
  week,
  month,
  shift,
  visit,
  job,
  milestone,
  task,
  service,
  percent,
  defineNew, // For User to create new UOMs
}

/* USAGE:
* final status = UnitOfMeasure.box;
* print(status.label); // Output: box
* */
extension UOMExtension on UnitOfMeasure {
  /// [getName] Get the specific Enum Name (e.g. "metricTon")
  String get getName => EnumUtil<UnitOfMeasure>(this).getName;

  /// Returns a user-friendly label (e.g. "pack of box")
  String get getLabel => EnumUtil<UnitOfMeasure>(this).getLabel;
}

class UOMUtil {
  /// Converts String/Label to enum value [fromString].
  static UnitOfMeasure fromString(String? value) =>
      EnumUtil.fromString<UnitOfMeasure>(UnitOfMeasure.values, value);

  /// Converts List of String/Label to enum values [fromStringList].
  static List<UnitOfMeasure> fromStringList(List<String>? values) =>
      values?.map(fromString).toList() ?? [];

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final list = EnumUtil.toStringList<UnitOfMeasure>(UnitOfMeasure.values);
    return includeHeader ? ['Unit of Measure', ...list] : list;
  }
}
