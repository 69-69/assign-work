import 'package:assign_erp/core/network/data_sources/models/address_info_model.dart';
import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/core/util/extensions/item_category.dart';
import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:collection/collection.dart';
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
  final String storeNumber; // FK CompanyStore.storeNumber
  final String code; // Unique warehouse code, e.g., "WH01"
  final String description; // Full warehouse description
  final WarehouseType wareType; // (Main, Store, Transit)
  final AddressInfo address; // Optional: physical address
  final bool isActive; // Active/inactive warehouse
  final bool isDefault; // is the default warehouse?
  final bool isBinManaged; // is the warehouse bin managed?
  final List<UnitOfMeasure>?
  uomRestriction; // What units are allowed in the bin
  final List<ItemCategory>?
  itemRestriction; // What items are allowed in the bin

  /// Capacity constraints
  final double? maxItems; // Max number of items warehouse can hold
  final double? maxVolume; // Max total weight warehouse can hold

  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Warehouse({
    this.id = '',
    required this.storeNumber,
    required this.code,
    required this.description,
    required this.wareType,
    required this.address,
    this.isActive = true,
    this.isDefault = false,
    this.isBinManaged = false,
    this.uomRestriction = const [],
    this.itemRestriction = const [],
    this.maxItems,
    this.maxVolume,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory Warehouse.fromMap(Map<String, dynamic> map, {String? id}) =>
      Warehouse(
        id: id ?? map['id'] ?? '',
        storeNumber: map['storeNumber'] ?? '',
        code: map['code'] ?? '',
        description: map['description'] ?? '',
        wareType: WarehouseTypeUtil.fromString(map['wareType']),
        uomRestriction: UOMUtil.fromStringList(
          List<String>.from(map['uomRestriction'] ?? []),
        ),
        itemRestriction: ItemCategoryUtil.fromStringList(
          List<String>.from(map['itemRestriction'] ?? []),
        ),
        address: AddressInfo.fromMap(Map.from(map['address'])),
        isActive: map['isActive'] ?? false,
        isDefault: map['isDefault'] ?? false,
        isBinManaged: map['isBinManaged'] ?? false,
        maxItems: '${map['maxItems']}'.asDouble,
        maxVolume: '${map['maxVolume']}'.asDouble,
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
        createdAt: toDateTimeFn(map['createdAt']),
        updatedAt: toDateTimeFn(map['updatedAt']),
      );

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'storeNumber': storeNumber,
    'code': code,
    'wareType': getType,
    'description': description,
    'isActive': isActive,
    'isDefault': isDefault,
    'isBinManaged': isBinManaged,
    'maxItems': maxItems,
    'maxVolume': maxVolume,
    'uomRestriction': uomRestriction?.map((e) => e.getName).toList() ?? [],
    'itemRestriction': itemRestriction?.map((e) => e.getName).toList() ?? [],
    'address': address.toMap(),
    'createdBy': createdBy,
    'updatedBy': updatedBy,
  };

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
    description: '',
    storeNumber: '',
    wareType: WarehouseType.main,
    address: AddressInfo.empty,
  );

  bool get isEmpty => code.isEmpty || description.isEmpty || address.isEmpty;

  bool get isNotEmpty => !isEmpty;

  String get getType => wareType.getName;

  // filter/search
  bool filterByAny(String term) =>
      props.filterAny(term) || address.filterByAny(term);

  static Warehouse? findById(List<Warehouse> warehouses, String id) =>
      warehouses.firstWhereOrNull((w) => w.id == id);

  /// Extract all codes from a list of Warehouse objects
  static List<String> getCodes(List<Warehouse> warehouses) =>
      warehouses.map((w) => w.code).toList();

  /// Returns warehouse codes filtered by [code].
  /// If [code] is empty, all codes are returned.
  static List<String> getCodesByCode(List<String> codes, [String code = '']) =>
      codes.where((c) => code.isEmpty || c.filterAny(code)).toList();

  Warehouse copyWith({
    String? id,
    String? code,
    String? description,
    String? storeNumber,
    WarehouseType? wareType,
    AddressInfo? address,
    bool? isActive,
    bool? isDefault,
    bool? isBinManaged,
    double? maxItems,
    double? maxVolume,
    List<UnitOfMeasure>? uomRestriction,
    List<ItemCategory>? itemRestriction,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Warehouse(
    id: id ?? this.id,
    storeNumber: storeNumber ?? this.storeNumber,
    code: code ?? this.code,
    description: description ?? this.description,
    wareType: wareType ?? this.wareType,
    address: address ?? this.address,
    isActive: isActive ?? this.isActive,
    isDefault: isDefault ?? this.isDefault,
    isBinManaged: isBinManaged ?? this.isBinManaged,
    maxItems: maxItems ?? this.maxItems,
    maxVolume: maxVolume ?? this.maxVolume,
    uomRestriction: uomRestriction ?? this.uomRestriction,
    itemRestriction: itemRestriction ?? this.itemRestriction,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    storeNumber,
    code,
    description,
    wareType,
    address,
    isActive,
    isDefault,
    isBinManaged,
    uomRestriction,
    itemRestriction,
    maxItems,
    maxVolume,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  ];

  List<String> get itemAsList => [
    id,
    storeNumber,
    code,
    getType.toTitle,
    description.toTitle,
    '$maxItems',
    '$maxVolume',
    isDefault ? 'Yes' : 'No',
    isActive ? 'Yes' : 'No',
    isBinManaged ? 'Yes' : 'No',
    createdBy?.toTitle ?? '',
    updatedBy?.toTitle ?? '',
  ];

  static List<String> get dataTableHeader => [
    'ID',
    'Store #',
    'Code',
    'Type',
    'name',
    'max qty',
    'max Vol.',
    'Default',
    'Active',
    'Bin Managed',
    'Created By',
    'Updated By',
  ];
}
