import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

/*Zone
- id
- warehouseId
- code
- type (RECEIVING, PICKING, BULK, QA)

Aisle
- id
- zoneId
- code

Rack
- id
- aisleId
- code

Level
- id
- rackId
- code

Each of these is a location level (or location attributes), not necessarily a bin:
Zone → high-level location (e.g., Picking, Bulk, Cold Storage)
Aisle → physical passage within a zone
Rack → storage structure within an aisle
Shelf / Level → vertical position on a rack

ZONE-A01-R03-L02
Full Bin Location = ZONE-AISLE-RACK-LEVEL-BIN

2️⃣ Who creates them?
During WMS setup (master data phase)
Admin / Warehouse setup screens create:
  Zone
  “Picking”, “Bulk”, “Receiving”
  Aisles
  Created inside a Zone
  Racks
  Created inside an Aisle
  Levels
  Created inside a Rack
  Bins
  Created inside a Level
  📌 This is done once, not during transactions.
*/
/// [WHLocation] Functional/Logical Area
class WHLocation extends Equatable {
  static final DateTime _today = DateTime.now();

  final String id; // PK
  final String warehouseId; // FK to Warehouse.id
  final String code; // Unique Location code, e.g., "A1", "B2"
  final String storeNumber; // FK CompanyStore.storeNumber
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
    required this.storeNumber,
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
        type: LocTypeUtil.fromString(map['type']),
        warehouseId: map['warehouseId'] ?? '',
        storeNumber: map['storeNumber'] ?? '',
        code: map['code'] ?? '',
        description: map['description'] ?? '',
        isActive: map['isActive'] ?? false,
        maxItems: '${map['maxItems']}'.asDouble,
        maxWeight: '${map['maxWeight']}'.asDouble,
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
        createdAt: toDateTimeFn(map['createdAt']),
        updatedAt: toDateTimeFn(map['updatedAt']),
      );

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'code': code,
    'type': getType,
    'storeNumber': storeNumber,
    'warehouseId': warehouseId,
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
    String? storeNumber,
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
    code: code ?? this.code,
    warehouseId: warehouseId ?? this.warehouseId,
    storeNumber: storeNumber ?? this.storeNumber,
    description: description ?? this.description,
    isActive: isActive ?? this.isActive,
    maxItems: maxItems ?? this.maxItems,
    maxWeight: maxWeight ?? this.maxWeight,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// A singleton instance representing an empty/default WHLocation.
  /// Used as a fallback when no matching WHLocation is found
  static WHLocation get empty => WHLocation(
    id: '',
    code: '',
    type: LocationType.other,
    warehouseId: '',
    storeNumber: '',
    description: '',
  );

  // Check if the WHLocation is empty.
  bool get isEmpty => identical(this, WHLocation.empty);
  bool get isNotEmpty => !isEmpty;

  // filter/search
  bool filterByAny(String term) => itemAsList.filterAny(term);

  static WHLocation? findById(List<WHLocation> warehouses, String id) =>
      warehouses.firstWhereOrNull((w) => w.id == id);

  /// Extract all codes from a list of Location objects
  static List<String> getCodes(List<WHLocation> warehouses) =>
      warehouses.map((w) => w.code).toList();

  /// Returns Location codes filtered by [code].
  /// If [code] is empty, all codes are returned.
  static List<String> getCodesByCode(List<String> codes, [String code = '']) =>
      codes.where((c) => code.isEmpty || c.filterAny(code)).toList();

  @override
  List<Object?> get props => [
    id,
    type,
    warehouseId,
    storeNumber,
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
    id,
    storeNumber,
    getType,
    warehouseId,
    code,
    description,
    isActive ? 'Yes' : 'No',
    createdBy ?? '',
    updatedBy ?? '',
  ];

  static List<String> get dataTableHeader => [
    'ID',
    'Store Number',
    'Type',
    'Warehouse ID',
    'Code',
    'description',
    'Active',
    'Created By',
    'Updated By',
  ];
}

/// Functional type of a warehouse location
enum LocationType {
  receiving, // REC: Locations where goods are received (Inbound)
  storage, // STO: Standard storage locations
  picking, // PICK: Picking areas for outbound orders
  shipping, // SHIP: Shipping / staging areas
  qc, // Quality Control
  other, // Other
}

extension LocationTypeExtension on LocationType {
  // Get Name
  String get getName => EnumUtil<LocationType>(this).getName;

  // Get Short Location Code
  String get locCode {
    return switch (this) {
      LocationType.receiving => 'REC',
      LocationType.storage => 'STO',
      LocationType.picking => 'PICK',
      LocationType.shipping => 'SHIP',
      LocationType.qc => 'QC',
      _ => 'OTHER',
    };
  }
}

class LocTypeUtil {
  /// [fromString] Converts String/Label to enum value.
  static LocationType fromString(String? value) =>
      EnumUtil.fromString<LocationType>(LocationType.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Location type' : '';
    return EnumUtil.toStringList<LocationType>(LocationType.values, label);
  }
}
