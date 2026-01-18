import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

enum LocationType { zone, aisle, rack }

/// [WHBin] Physical slot inside a location (rack, shelf, cabinet, etc.)
/// Bin Location Storage = WH-Code -> Location-Code -> Bin-Code
class WHBin extends Equatable {
  static final DateTime _today = DateTime.now();

  final String id;
  final String locationId;
  final String code;
  final String description;
  final bool isActive;

  /// Capacity constraints
  final double? maxItems; // Max units bin can hold
  final double? maxWeight; // Max weight the bin can hold
  final String? uomRestriction; // What units are allowed in the bin
  final double? minQty; // Trigger replenishment alert if below this

  final int? sequence; // For picking order or physical arrangement

  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  WHBin({
    required this.id,
    required this.locationId,
    required this.code,
    this.description = '',
    this.isActive = true,
    this.maxItems,
    this.maxWeight,
    this.uomRestriction,
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
      locationId: map['locationId'],
      code: map['code'],
      description: map['description'],
      isActive: map['isActive'],
      maxItems: '${map['maxItems']}'.asDouble,
      maxWeight: '${map['maxWeight']}'.asDouble,
      uomRestriction: map['uomRestriction'],
      minQty: map['minQty'],
      sequence: map['sequence'],
      createdBy: map['createdBy'],
      updatedBy: map['updatedBy'],
      createdAt: toDateTimeFn(map['createdAt']),
      updatedAt: toDateTimeFn(map['updatedAt']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'locationId': locationId,
    'code': code,
    'description': description,
    'maxItems': maxItems,
    'maxWeight': maxWeight,
    'uomRestriction': uomRestriction,
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

  WHBin copyWith({
    String? id,
    String? locationId,
    String? code,
    String? description,
    bool? isActive,
    double? maxItems,
    double? maxWeight,
    String? uomRestriction,
    double? minQty,
    int? sequence,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WHBin(
    id: id ?? this.id,
    locationId: locationId ?? this.locationId,
    code: code ?? this.code,
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
    locationId,
    code,
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
    locationId,
    code,
    description,
    isActive ? 'Yes' : 'No',
    maxItems.toString(),
    sequence.toString(),
    createdBy ?? '',
    updatedBy ?? '',
  ];

  List<String> get dataTableHeader => [
    'Location ID',
    'Code',
    'description',
    'Is Active',
    'Capacity',
  ];
}
