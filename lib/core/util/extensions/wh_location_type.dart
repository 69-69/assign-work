import 'package:assign_erp/core/util/enum_util.dart';

enum LocationType { zone, aisle, rack, shelf, cabinet, level, defineNew }

extension LocationTypeExt on LocationType {
  // Get Name
  String get getName => EnumUtil<LocationType>(this).getName;

  // Is Zone Type
  bool get isZoneType => this == LocationType.zone;
}

// Location Type
class LocationTypeUtil {
  /// [fromString] Converts String/Label to enum value.
  static LocationType fromString(String? value) =>
      EnumUtil.fromString<LocationType>(LocationType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Location Type' : '';
    return EnumUtil.toStringList<LocationType>(LocationType.values, label);
  }
}
