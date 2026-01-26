import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/extensions/wh_location_type.dart';
import 'package:assign_erp/core/util/extensions/wh_zone_type.dart';
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
  final String warehouseCode; // FK to Warehouse.code
  final String
  codeRanges; // Sub-Location code ranges (e.g, A01, A02, ...., A20)
  final String storeNumber; // FK CompanyStore.storeNumber
  /// [description] To create a custom sub-location, else fallback to type.getName
  final String? description;
  final bool isActive;
  final LocationType type;

  /// Only applicable if LocationType is 'Zone'
  final ZoneType? zoneType;

  /// Capacity constraints
  final double? maxQuantity; // Max number of items this sub-location can hold
  final double? maxVolume; // Max total volume this sub-location can hold
  final List<UnitOfMeasure>?
  uomRestriction; // What units are allowed in this sub-area

  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  WHLocation({
    required this.id,
    required this.storeNumber,
    required this.warehouseCode,
    required this.type,
    this.zoneType,
    this.uomRestriction = const [],
    this.codeRanges = '',
    this.description,
    this.isActive = true,
    this.maxQuantity,
    this.maxVolume,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory WHLocation.fromMap(Map<String, dynamic> map, {String? id}) {
    final locType = LocationTypeUtil.fromString(map['type']);

    return WHLocation(
      id: id ?? map['id'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      type: locType,
      zoneType: locType.isZoneType
          ? ZoneTypeUtil.fromString(map['zoneType'])
          : null,
      description: locType.isDefineNew ? map['description'] : locType.getName,
      uomRestriction: UOMUtil.fromStringList(
        List<String>.from(map['uomRestriction'] ?? []),
      ),
      warehouseCode: map['warehouseCode'] ?? '',
      codeRanges: map['codeRanges'] ?? '',
      isActive: map['isActive'] ?? false,
      maxQuantity: '${map['maxQuantity']}'.asDouble,
      maxVolume: '${map['maxVolume']}'.asDouble,
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      updatedAt: toDateTimeFn(map['updatedAt']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'storeNumber': storeNumber,
    'warehouseCode': warehouseCode,
    'type': getLocationType,
    'isActive': isActive,
    'zoneType': getZoneType,
    'codeRanges': codeRanges,
    'description': description,
    'uomRestriction': uomRestriction?.map((e) => e.getName).toList() ?? [],
    'maxQuantity': maxQuantity,
    'maxVolume': maxVolume,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
  };

  String get getLocationType => type.getName;
  String get getZoneType => zoneType?.getName ?? 'N/A';
  String get customType => type.isDefineNew ? 'Custom' : getLocationType;
  String get status => isActive ? 'Active' : 'Inactive';

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
    String? warehouseCode,
    String? storeNumber,
    String? codeRanges,
    LocationType? type,
    ZoneType? zoneType,
    List<UnitOfMeasure>? uomRestriction,
    String? description,
    bool? isActive,
    double? maxQuantity,
    double? maxVolume,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WHLocation(
    id: id ?? this.id,
    type: type ?? this.type,
    zoneType: zoneType ?? this.zoneType,
    uomRestriction: uomRestriction ?? this.uomRestriction,
    description: description ?? this.description,
    codeRanges: codeRanges ?? this.codeRanges,
    warehouseCode: warehouseCode ?? this.warehouseCode,
    storeNumber: storeNumber ?? this.storeNumber,
    isActive: isActive ?? this.isActive,
    maxQuantity: maxQuantity ?? this.maxQuantity,
    maxVolume: maxVolume ?? this.maxVolume,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// A singleton instance representing an empty/default WHLocation.
  /// Used as a fallback when no matching WHLocation is found
  static WHLocation get empty => WHLocation(
    id: '',
    warehouseCode: '',
    storeNumber: '',
    type: LocationType.zone,
  );
  bool get isEmpty => warehouseCode.isEmpty;

  bool get isNotEmpty => !isEmpty;

  // filter/search
  bool filterByAny(String term) => itemAsList.filterAny(term);

  static WHLocation? findById(List<WHLocation> warehouses, String id) =>
      warehouses.firstWhereOrNull((w) => w.id == id);

  /// Convert comma separated string to `List<String>`
  List<String> get getCodeRanges => codeRanges.split(',').toList();

  /// Convert `List<String>` to comma separated string
  String get codeToString => getCodeRanges.join(',');

  /// Extract all codes from a list of Location objects
  static List<String> getCodes(List<WHLocation> warehouses) =>
      warehouses.map((w) => w.codeRanges).toList();

  /// Returns Location codes filtered by [code].
  /// If [code] is empty, all codes are returned.
  static List<String> getCodesByCode(List<String> codes, [String code = '']) =>
      codes.where((c) => code.isEmpty || c.filterAny(code)).toList();

  @override
  List<Object?> get props => [
    id,
    type,
    zoneType,
    uomRestriction,
    warehouseCode,
    storeNumber,
    codeRanges,
    isActive,
    maxQuantity,
    maxVolume,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  ];

  List<String> get itemAsList => [
    id,
    storeNumber.toUpperAll,
    status,
    warehouseCode.toUpperAll,
    customType.toTitle,
    description?.toTitle ?? 'N/A',
    getZoneType.toTitle,
    codeRanges.isEmpty ? 'No' : 'Yes',
    createdBy?.toTitle ?? '',
    updatedBy?.toTitle ?? '',
  ];

  static List<String> get dataTableHeader => [
    'ID',
    'Store No.',
    'Status',
    'WH Code',
    'Type',
    'Name',
    'Zone',
    'Has Codes',
    'Created By',
    'Updated By',
  ];
}
