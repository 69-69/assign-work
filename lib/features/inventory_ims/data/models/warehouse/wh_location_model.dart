import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

/// [WHLocation] Functional/Logical Area
class WHLocation extends Equatable {
  static final DateTime _today = DateTime.now();

  final String id; // PK
  final String warehouseId; // FK to Warehouse.id
  final String code; // Unique Location code, e.g., "A1", "B2"
  final String description; // Optional descriptive name
  final bool isActive; // Active/inactive
  final LocationType type;

  /// Capacity constraints
  final double? maxItems; // Max number of items warehouse can hold
  final double? maxWeight; // Max total weight warehouse can hold

  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  WHLocation({
    required this.id,
    required this.warehouseId,
    required this.type,
    required this.code,
    this.description = '',
    this.isActive = true,
    this.maxItems,
    this.maxWeight,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory WHLocation.fromMap(Map<String, dynamic> map, {String? id}) =>
      WHLocation(
        id: id ?? map['id'] ?? '',
        type: fromString(map['type']),
        warehouseId: map['warehouseId'],
        code: map['code'],
        description: map['description'],
        isActive: map['isActive'],
        maxItems: '${map['maxItems']}'.asDouble,
        maxWeight: '${map['maxWeight']}'.asDouble,
        createdBy: map['createdBy'],
        updatedBy: map['updatedBy'],
        createdAt: toDateTimeFn(map['createdAt']),
        updatedAt: toDateTimeFn(map['updatedAt']),
      );

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'type': getType,
    'warehouseId': warehouseId,
    'code': code,
    'description': description,
    'isActive': isActive,
    'maxItems': maxItems,
    'maxWeight': maxWeight,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
  };

  String get getType => type.getName;

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

  WHLocation copyWith({
    String? id,
    String? warehouseId,
    String? code,
    String? description,
    LocationType? type,
    bool? isActive,
    double? maxItems,
    double? maxWeight,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WHLocation(
    id: id ?? this.id,
    type: type ?? this.type,
    warehouseId: warehouseId ?? this.warehouseId,
    code: code ?? this.code,
    description: description ?? this.description,
    isActive: isActive ?? this.isActive,
    maxItems: maxItems ?? this.maxItems,
    maxWeight: maxWeight ?? this.maxWeight,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    warehouseId,
    code,
    description,
    isActive,
    maxItems,
    maxWeight,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  ];

  List<String> get itemAsList => [
    getType,
    warehouseId,
    code,
    description,
    isActive ? 'Yes' : 'No',
    createdBy ?? '',
    updatedBy ?? '',
  ];

  List<String> get dataTableHeader => [
    'Type',
    'Warehouse ID',
    'Code',
    'description',
    'Active',
    'Created By',
    'Updated By',
  ];

  /// [fromString] Converts String/Label to enum value.
  static LocationType fromString(String? value) =>
      EnumUtil.fromString<LocationType>(LocationType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Location type' : '';
    return EnumUtil.toStringList<LocationType>(LocationType.values, label);
  }
}

/// Functional type of a warehouse location
enum LocationType {
  receiving, // REC: Locations where goods are received (Inbound)
  storage, // STO: Standard storage locations
  picking, // PICK: Picking areas for outbound orders
  shipping, // SHIP: Shipping / staging areas
  qc, // Quality Control
}

extension LocationTypeExtension on LocationType {
  // Get Name
  String get getName => EnumUtil<LocationType>(this).getName;

  // Get Short Location Code
  String get locationCode {
    return switch (this) {
      LocationType.receiving => 'REC',
      LocationType.storage => 'STO',
      LocationType.picking => 'PICK',
      LocationType.shipping => 'SHIP',
      LocationType.qc => 'QC',
    };
  }
}
