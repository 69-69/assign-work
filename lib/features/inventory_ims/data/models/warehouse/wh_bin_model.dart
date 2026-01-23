import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

/// [WHBin] Physical slot inside a location (rack, shelf, cabinet, etc.)
/// Bin Location Storage = WH-Code -> Location-Code -> Bin-Code
class WHBin extends Equatable {
  static final DateTime _today = DateTime.now();

  final String id;
  final LocationHierarchy type;
  final String locationId; // FK to WHBin.id
  final String storeNumber; // FK CompanyStore.storeNumber
  final String code;
  final String description;
  final bool isActive;

  /// Capacity constraints
  final double? maxItems; // Max units bin can hold
  final double? maxWeight; // Max weight the bin can hold
  final List<String>? uomRestriction; // What units are allowed in the bin
  final double? minQty; // Trigger replenishment alert if below this

  final int? sequence; // For picking order or physical arrangement

  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  WHBin({
    required this.id,
    required this.type,
    required this.code,
    required this.locationId,
    required this.storeNumber,
    this.description = '',
    this.isActive = true,
    this.maxItems,
    this.maxWeight,
    this.uomRestriction = const [],
    this.minQty,
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
      type: LocationHierarchyUtil.fromString(map['type']),
      code: map['code'] ?? '',
      locationId: map['locationId'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? false,
      maxItems: '${map['maxItems']}'.asDouble,
      maxWeight: '${map['maxWeight']}'.asDouble,
      uomRestriction: List.from(map['uomRestriction'] ?? []).cast<String>(),
      minQty: '${map['minQty']}'.asDouble,
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
    'code': code,
    'type': getType,
    'locationId': locationId,
    'storeNumber': storeNumber,
    'description': description,
    'maxItems': maxItems,
    'maxWeight': maxWeight,
    'uomRestriction': List.from(uomRestriction ?? []).cast<String>(),
    'minQty': minQty,
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
    code: '',
    locationId: '',
    storeNumber: '',
    description: '',
    type: LocationHierarchy.zone,
  );

  // Get Name
  String get getType => type.getName;

  // Check if the WHBin is empty.
  bool get isEmpty => identical(this, WHBin.empty);
  bool get isNotEmpty => !isEmpty;

  // filter/search
  bool filterByAny(String term) => itemAsList.filterAny(term);

  static WHBin? findById(List<WHBin> warehouses, String id) =>
      warehouses.firstWhereOrNull((w) => w.id == id);

  /// Extract all codes from a list of Location objects
  static List<String> getCodes(List<WHBin> warehouses) =>
      warehouses.map((w) => w.code).toList();

  /// Returns Location codes filtered by [code].
  /// If [code] is empty, all codes are returned.
  static List<String> getCodesByCode(List<String> codes, [String code = '']) =>
      codes.where((c) => code.isEmpty || c.filterAny(code)).toList();

  WHBin copyWith({
    String? id,
    String? code,
    LocationHierarchy? type,
    String? locationId,
    String? storeNumber,
    String? description,
    bool? isActive,
    double? maxItems,
    double? maxWeight,
    List<String>? uomRestriction,
    double? minQty,
    int? sequence,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WHBin(
    id: id ?? this.id,
    code: code ?? this.code,
    type: type ?? this.type,
    locationId: locationId ?? this.locationId,
    storeNumber: storeNumber ?? this.storeNumber,
    description: description ?? this.description,
    isActive: isActive ?? this.isActive,
    maxItems: maxItems ?? this.maxItems,
    maxWeight: maxWeight ?? this.maxWeight,
    uomRestriction: uomRestriction ?? this.uomRestriction,
    minQty: minQty ?? this.minQty,
    sequence: sequence ?? this.sequence,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    code,
    type,
    locationId,
    storeNumber,
    description,
    isActive,
    maxItems,
    maxWeight,
    uomRestriction,
    minQty,
    sequence,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  ];

  List<String> get itemAsList => [
    id,
    storeNumber,
    getType,
    locationId,
    code,
    description,
    isActive ? 'Yes' : 'No',
    maxItems.toString(),
    sequence.toString(),
    createdBy ?? '',
    updatedBy ?? '',
  ];

  static List<String> get dataTableHeader => [
    'ID',
    'Store Number',
    'Type',
    'Location ID',
    'Code',
    'description',
    'Is Active',
    'Capacity',
    'Sequence',
    'Created By',
    'Updated By',
  ];
}

/*Zone (Receiving / Cold Storage / Hazardous)
 └── Aisle
      └── Rack
           └── Level
                └── Shelf / Bin*/
enum LocationHierarchy { zone, aisle, rack, shelf, cabinet, level, defineNew }

extension LocationHierarchyExt on LocationHierarchy {
  // Get Name
  String get getName => EnumUtil<LocationHierarchy>(this).getName;
}

// Location Hierarchy
class LocationHierarchyUtil {
  /// [fromString] Converts String/Label to enum value.
  static LocationHierarchy fromString(String? value) =>
      EnumUtil.fromString<LocationHierarchy>(LocationHierarchy.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Location Hierarchy' : '';
    return EnumUtil.toStringList<LocationHierarchy>(
      LocationHierarchy.values,
      label,
    );
  }
}
