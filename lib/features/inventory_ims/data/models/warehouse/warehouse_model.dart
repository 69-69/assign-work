import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:equatable/equatable.dart';

enum WarehouseType {
  main,
  store,
  transit, // Transit represents stock that has physically left one warehouse/location but has NOT yet arrived at the destination.
}

extension WarehouseTypeExtension on WarehouseType {
  String get getName => EnumUtil<WarehouseType>(this).getName;
}

class WarehouseTypeUtil {
  /// [fromString] Converts String/Label to enum value.
  static WarehouseType fromString(String? value) =>
      EnumUtil.fromString<WarehouseType>(WarehouseType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Warehouse type' : '';
    return EnumUtil.toStringList<WarehouseType>(WarehouseType.values, label);
  }
}

/// [Warehouse] Purpose: Represents a physical storage place (Main, Store, Transit, etc.)
class Warehouse extends Equatable {
  static final DateTime _today = DateTime.now();

  final String id; // PK
  final String code; // Unique warehouse code, e.g., "WH01"
  final String name; // Full warehouse name
  final WarehouseType type;
  final String address; // Optional: physical address
  final bool isActive; // Active/inactive warehouse
  final bool isDefault; // is the default warehouse?
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Warehouse({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.address = '',
    this.isActive = true,
    this.isDefault = false,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  /// Create a new warehouse from a map.
  factory Warehouse.fromMap(Map<String, dynamic> map, {String? id}) =>
      Warehouse(
        id: id ?? map['id'] ?? '',
        code: map['code'],
        name: map['name'],
        type: WarehouseTypeUtil.fromString(map['type']),
        address: map['address'],
        isActive: map['isActive'],
        isDefault: map['isDefault'],
        createdBy: map['createdBy'],
        updatedBy: map['updatedBy'],
        createdAt: toDateTimeFn(map['createdAt']),
        updatedAt: toDateTimeFn(map['updatedAt']),
      );

  // map template
  Map<String, dynamic> _mapTemp() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'type': type.getName,
      'address': address,
      'isActive': isActive,
      'isDefault': isDefault,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.toMilliseconds;
    newMap['updatedAt'] = updatedAt.toMilliseconds;

    return {'id': id, 'data': newMap};
  }

  Warehouse copyWith({
    String? id,
    String? code,
    String? name,
    WarehouseType? type,
    String? address,
    bool? isActive,
    bool? isDefault,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Warehouse(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    type: type ?? this.type,
    address: address ?? this.address,
    isActive: isActive ?? this.isActive,
    isDefault: isDefault ?? this.isDefault,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    type,
    address,
    isActive,
    isDefault,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  ];
}
