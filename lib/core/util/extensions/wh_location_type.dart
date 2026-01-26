import 'package:assign_erp/core/util/enum_util.dart';

enum LocationType {
  zone,
  aisle,
  rack,
  shelf,
  cabinet,
  level,
  defineNew, // Create a new/custom type if not exist
}

extension LocationTypeExt on LocationType {
  // Get Name
  String get getName => EnumUtil<LocationType>(this).getName;

  // Get Label
  String get getLabel => EnumUtil<LocationType>(this).getLabel;

  // Is Zone Type
  bool get isZoneType => this == LocationType.zone;

  // Is define new
  bool get isDefineNew => this == LocationType.defineNew;
}

// Location Type
class LocationTypeUtil {
  /// [fromString] Converts String/Label to enum value.
  static LocationType fromString(String? value) =>
      EnumUtil.fromString<LocationType>(LocationType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Sub-Location Type' : '';
    return EnumUtil.toStringList<LocationType>(LocationType.values, label);
  }
}
