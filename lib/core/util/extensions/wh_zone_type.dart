import 'package:assign_erp/core/util/enum_util.dart';

enum ZoneType {
  storage, // STO: Standard storage locations
  receiving, // REC: Locations where goods are received (Inbound)
  picking, // PICK: Picking areas for outbound orders
  shipping, // SHIP: Shipping / staging areas
  hazardous,
  coldStorage,
  qc, // Quality Control
  defineNew, // Other
}

extension ZoneTypeExtension on ZoneType {
  // Get Name
  String get getName => EnumUtil<ZoneType>(this).getName;
  String get getLabel => EnumUtil<ZoneType>(this).getLabel;

  // Get Short Location Code
  String get locCode {
    return switch (this) {
      ZoneType.receiving => 'REC',
      ZoneType.storage => 'STO',
      ZoneType.picking => 'PICK',
      ZoneType.shipping => 'SHIP',
      ZoneType.qc => 'QC',
      _ => 'OTHER',
    };
  }
}

class ZoneTypeUtil {
  /// [fromString] Converts String/Label to enum value.
  static ZoneType fromString(String? value) =>
      EnumUtil.fromString<ZoneType>(ZoneType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Zone type' : '';
    return EnumUtil.toStringList<ZoneType>(ZoneType.values, label);
  }
}
