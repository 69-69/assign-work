import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

/// [WHMovement] Internal Movements within Warehouse (Bin-to-Bin, Location-to-Location)
class WHMovement extends Equatable {
  static final DateTime _today = DateTime.now();

  final String id; // (PK)
  final String fromLocationId; // (FK)
  final String toLocationId; // (FK)
  final String itemId; // (FK)
  final int quantity;
  final String reason; // (PutAway | Replenish | Transfer | Adjustment)
  final String status; // (Draft | Completed)
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  WHMovement({
    this.id = '',
    required this.fromLocationId,
    required this.toLocationId,
    required this.itemId,
    required this.quantity,
    required this.reason,
    required this.status,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory WHMovement.fromJson(Map<String, dynamic> map, {String? id}) =>
      WHMovement(
        id: id ?? map['id'] ?? '',
        fromLocationId: map['fromLocationId'] ?? '',
        toLocationId: map['toLocationId'] ?? '',
        itemId: map['itemId'] ?? '',
        quantity: '${map['quantity']}'.asInt,
        reason: map['reason'] ?? '',
        status: map['status'] ?? '',
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
        createdAt: toDateTimeFn(map['createdAt']),
        updatedAt: toDateTimeFn(map['updatedAt']),
      );

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'fromLocationId': fromLocationId,
    'toLocationId': toLocationId,
    'itemId': itemId,
    'quantity': quantity,
    'reason': reason,
    'status': status,
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

  WHMovement copyWith({
    String? id,
    String? fromLocationId,
    String? toLocationId,
    String? itemId,
    int? quantity,
    String? reason,
    String? status,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WHMovement(
    id: id ?? this.id,
    fromLocationId: fromLocationId ?? this.fromLocationId,
    toLocationId: toLocationId ?? this.toLocationId,
    itemId: itemId ?? this.itemId,
    quantity: quantity ?? this.quantity,
    reason: reason ?? this.reason,
    status: status ?? this.status,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    fromLocationId,
    toLocationId,
    itemId,
    quantity,
    reason,
    status,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  ];
}
