import 'package:assign_erp/core/network/data_sources/models/address_info_model.dart';
import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

enum WarehouseType {
  main,
  store,
  transit, // Transit represents stock that has physically left one warehouse/location but has NOT yet arrived at the destination.
}

extension WarehouseTypeExtension on WarehouseType {
  String get getName => EnumUtil<WarehouseType>(this).getName;
}

/// [Warehouse] Purpose: Represents a physical storage place (Main, Store, Transit, etc.)
class Warehouse extends Equatable {
  static final DateTime _today = DateTime.now();

  final String id; // PK
  final String code; // Unique warehouse code, e.g., "WH01"
  final String name; // Full warehouse name
  final WarehouseType type; // (Main, Store, Transit)
  final AddressInfo address; // Optional: physical address
  final bool isActive; // Active/inactive warehouse
  final bool isDefault; // is the default warehouse?
  final bool isBinManaged; // is the warehouse bin managed?

  /// Capacity constraints
  final double? maxItems; // Max number of items warehouse can hold
  final double? maxWeight; // Max total weight warehouse can hold

  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Warehouse({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.address,
    this.isActive = true,
    this.isDefault = false,
    this.isBinManaged = false,
    this.maxItems,
    this.maxWeight,
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
        type: fromString(map['type']),
        address: map['address'],
        isActive: map['isActive'],
        isDefault: map['isDefault'],
        isBinManaged: map['isBinManaged'],
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
    'code': code,
    'name': name,
    'type': getType,
    'address': address,
    'isActive': isActive,
    'isDefault': isDefault,
    'isBinManaged': isBinManaged,
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

  /// A singleton instance representing an empty/default Warehouse.
  /// Used as a fallback when no matching Warehouse is found
  static Warehouse get empty => Warehouse(
    id: '',
    code: '',
    name: '',
    type: WarehouseType.main,
    address: AddressInfo.empty,
  );

  /// Check if the Warehouse is empty.
  bool get isEmpty => identical(this, Warehouse.empty);

  Warehouse copyWith({
    String? id,
    String? code,
    String? name,
    WarehouseType? type,
    AddressInfo? address,
    bool? isActive,
    bool? isDefault,
    bool? isBinManaged,
    double? maxItems,
    double? maxWeight,
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
    isBinManaged: isBinManaged ?? this.isBinManaged,
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
    code,
    name,
    type,
    address,
    isActive,
    isDefault,
    isBinManaged,
    maxItems,
    maxWeight,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  ];

  List<String> get itemAsList => [
    code,
    name,
    getType,
    isDefault ? 'Yes' : 'No',
    isActive ? 'Yes' : 'No',
    isBinManaged ? 'Yes' : 'No',
    createdBy ?? '',
    updatedBy ?? '',
  ];

  List<String> get dataTableHeader => [
    'WH Code',
    'Name',
    'Type',
    'Default',
    'Active',
    'Bin Managed',
    'Created By',
    'Updated By',
  ];

  /// [fromString] Converts String/Label to enum value.
  static WarehouseType fromString(String? value) =>
      EnumUtil.fromString<WarehouseType>(WarehouseType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Warehouse type' : '';
    return EnumUtil.toStringList<WarehouseType>(WarehouseType.values, label);
  }
}
