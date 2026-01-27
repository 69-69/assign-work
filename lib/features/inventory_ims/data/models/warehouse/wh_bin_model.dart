import 'package:assign_erp/core/util/extensions/item_category.dart';
import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

/*Zone (Receiving / Cold Storage / Hazardous)
 └── Aisle
      └── Rack
           └── Level
                └── Shelf / Bin*/
/// [WHBin] Physical slot inside a location (rack, shelf, cabinet, etc.)
/// Bin Location Storage = WH-Code -> Location-Code -> Bin-Code
class WHBin extends Equatable {
  static final DateTime _today = DateTime.now();

  final String id;
  final String warehouseCode; // FK to Warehouse.id
  final String storeNumber; // FK CompanyStore.storeNumber
  final String binLocationCode; // Single bin location code
  final String fullBinLocations; // List of all bin locations
  final String description;
  final bool isActive;

  /// Capacity constraints
  final double? maxQuantity; // Max units bin can hold
  final double? maxVolume; // Max weight/volume the bin can hold
  final List<UnitOfMeasure>?
  uomRestriction; // What units are allowed in the bin
  final List<ItemCategory>?
  itemRestriction; // What item categories are allowed in the bin
  final double? minQuantity; // Trigger replenishment alert if below this

  final int? sequence; // For picking order or physical arrangement

  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  WHBin({
    required this.id,
    required this.binLocationCode,
    this.fullBinLocations = '',
    required this.warehouseCode,
    required this.storeNumber,
    this.description = '',
    this.isActive = true,
    this.maxQuantity,
    this.maxVolume,
    this.uomRestriction = const [],
    this.itemRestriction = const [],
    this.minQuantity,
    this.sequence,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory WHBin.fromMap(Map<String, dynamic> map, {String? id}) {
    return WHBin(
      id: id ?? map['id'] ?? '',
      binLocationCode: map['binLocationCode'] ?? '',
      fullBinLocations: map['fullBinLocations'] ?? '',
      warehouseCode: map['warehouseCode'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? false,
      maxQuantity: '${map['maxQuantity']}'.asDouble,
      maxVolume: '${map['maxVolume']}'.asDouble,
      uomRestriction: UOMUtil.fromStringList(
        List<String>.from(map['uomRestriction'] ?? []),
      ),
      itemRestriction: ItemCategoryUtil.fromStringList(
        List<String>.from(map['itemRestriction'] ?? []),
      ),
      minQuantity: '${map['minQuantity']}'.asDouble,
      sequence: '${map['sequence']}'.asInt,
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      updatedAt: toDateTimeFn(map['updatedAt']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'warehouseCode': warehouseCode,
    'storeNumber': storeNumber,
    'binLocationCode': binLocationCode,
    'fullBinLocations': fullBinLocations,
    'description': description,
    'maxQuantity': maxQuantity,
    'maxVolume': maxVolume,
    'minQuantity': minQuantity,
    'uomRestriction': uomRestriction?.map((e) => e.getName).toList() ?? [],
    'itemRestriction': itemRestriction?.map((e) => e.getName).toList() ?? [],
    'sequence': sequence,
    'isActive': isActive,
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

  /// A singleton instance representing an empty/default WHBin.
  /// Used as a fallback when no matching WHBin is found
  static WHBin get empty => WHBin(
    id: '',
    binLocationCode: '',
    warehouseCode: '',
    storeNumber: '',
    description: '',
  );

  bool get isEmpty => warehouseCode.isEmpty || binLocationCode.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Convert comma separated string to `List<String>`
  List<String> get getFullBinLocations => fullBinLocations.split(',').toList();

  // filter/search
  bool filterByAny(String term) => itemAsList.filterAny(term);

  static WHBin? findById(List<WHBin> warehouses, String id) =>
      warehouses.firstWhereOrNull((w) => w.id == id);

  /// Extract all codes from a list of Location objects
  static List<String> getCodes(List<WHBin> warehouses) =>
      warehouses.map((w) => w.binLocationCode).toList();

  /// Returns Location codes filtered by [code].
  /// If [code] is empty, all codes are returned.
  static List<String> getCodesByCode(List<String> codes, [String code = '']) =>
      codes.where((c) => code.isEmpty || c.filterAny(code)).toList();

  WHBin copyWith({
    String? id,
    String? warehouseCode,
    String? storeNumber,
    String? binLocationCode,
    String? fullBinLocations,
    String? description,
    bool? isActive,
    double? maxQuantity,
    double? maxVolume,
    List<UnitOfMeasure>? uomRestriction,
    List<ItemCategory>? itemRestriction,
    double? minQuantity,
    int? sequence,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WHBin(
    id: id ?? this.id,
    warehouseCode: warehouseCode ?? this.warehouseCode,
    storeNumber: storeNumber ?? this.storeNumber,
    binLocationCode: binLocationCode ?? this.binLocationCode,
    fullBinLocations: fullBinLocations ?? this.fullBinLocations,
    description: description ?? this.description,
    isActive: isActive ?? this.isActive,
    maxQuantity: maxQuantity ?? this.maxQuantity,
    maxVolume: maxVolume ?? this.maxVolume,
    uomRestriction: uomRestriction ?? this.uomRestriction,
    itemRestriction: itemRestriction ?? this.itemRestriction,
    minQuantity: minQuantity ?? this.minQuantity,
    sequence: sequence ?? this.sequence,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    warehouseCode,
    storeNumber,
    binLocationCode,
    fullBinLocations,
    description,
    isActive,
    maxQuantity,
    maxVolume,
    uomRestriction,
    itemRestriction,
    minQuantity,
    sequence,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  ];

  List<String> get itemAsList => [
    id,
    storeNumber,
    warehouseCode,
    description,
    isActive ? 'Active' : 'Inactive',
    binLocationCode.isEmpty ? 'No' : 'Yes',
    fullBinLocations.isEmpty ? 'No' : 'Yes',
    maxQuantity.toString(),
    sequence.toString(),
    createdBy?.toTitle ?? '',
    updatedBy?.toTitle ?? '',
  ];

  static List<String> get dataTableHeader => [
    'ID',
    'Store #',
    'Warehouse',
    'Description',
    'Status',
    'Bin Code',
    'Bin Locations',
    'Max Qty',
    'Sequence',
    'Created By',
    'Updated By',
  ];
}
