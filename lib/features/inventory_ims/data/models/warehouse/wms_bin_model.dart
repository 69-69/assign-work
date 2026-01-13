import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:equatable/equatable.dart';

/// [Bin] A precise slot inside the location (Rack A → Bin 01)
class Bin extends Equatable {
  static final DateTime _today = DateTime.now();

  final String id; // PK
  final String locationId; // FK to Location.id
  final String code; // Bin code, e.g., "Shelf-01"
  final String name; // Optional
  final bool isActive;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bin({
    required this.id,
    required this.locationId,
    required this.code,
    this.name = '',
    this.isActive = true,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory Bin.fromJson(Map<String, dynamic> map, {String? id}) {
    return Bin(
      id: id ?? map['id'] ?? '',
      locationId: map['locationId'],
      code: map['code'],
      name: map['name'],
      isActive: map['isActive'],
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

  Bin copyWith({
    String? id,
    String? locationId,
    String? code,
    String? name,
    bool? isActive,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Bin(
    id: id ?? this.id,
    locationId: locationId ?? this.locationId,
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
    locationId,
    code,
    name,
    isActive,
    createdAt,
    updatedAt,
  ];
}
