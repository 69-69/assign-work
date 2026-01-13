import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:equatable/equatable.dart';

/// [Location] Purpose: Represents a physical storage place (Main, Store, Transit, etc.)
class Location extends Equatable {
  static final DateTime _today = DateTime.now();

  final String id; // PK
  final String warehouseId; // FK to Warehouse.id
  final String code; // Location code, e.g., "A1", "B2"
  final String name; // Optional descriptive name
  final bool isActive; // Active/inactive
  final String type; // Type of location e.g. (Zone | Aisle | Rack | Bin)
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Location({
    required this.id,
    required this.warehouseId,
    required this.type,
    required this.code,
    this.name = '',
    this.isActive = true,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory Location.fromJson(Map<String, dynamic> map, {String? id}) => Location(
    id: id ?? map['id'] ?? '',
    type: map['type'],
    warehouseId: map['warehouseId'],
    code: map['code'],
    name: map['name'],
    isActive: map['isActive'],
    createdBy: map['createdBy'],
    updatedBy: map['updatedBy'],
    createdAt: toDateTimeFn(map['createdAt']),
    updatedAt: toDateTimeFn(map['updatedAt']),
  );

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'type': type,
    'warehouseId': warehouseId,
    'code': code,
    'name': name,
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

  Location copyWith({
    String? id,
    String? type,
    String? warehouseId,
    String? code,
    String? name,
    bool? isActive,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Location(
    id: id ?? this.id,
    type: type ?? this.type,
    warehouseId: warehouseId ?? this.warehouseId,
    code: code ?? this.code,
    name: name ?? this.name,
    isActive: isActive ?? this.isActive,
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
    name,
    isActive,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  ];
}
