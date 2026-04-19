import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:equatable/equatable.dart';

/*PickList
--------
id (PK)
warehouseId (FK)
referenceType (SO | Transfer)
referenceId
status (Open | Picked | Packed | Shipped)

PickListLine
------------
id (PK)
itemId (FK)
fromLocationId (FK)
quantity
*/
/// [PickList] Picking / Shipping (Outbound Execution)
class PickList extends Equatable {
  static final DateTime _today = DateTime.now();

  final String id; // (PK)
  final String warehouseId; // (FK)
  final String referenceType; // (SO | Transfer)
  final String referenceId; // (FK)
  final String status; // (Open | Picked | Packed | Shipped)

  final List<PickListLine> lines; // (FK)
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  PickList({
    this.id = '',
    required this.warehouseId,
    required this.referenceType,
    required this.referenceId,
    required this.status,
    required this.lines,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory PickList.fromMap(Map<String, dynamic> map, {required String id}) =>
      PickList(
        id: id,
        warehouseId: map['warehouseId'],
        referenceType: map['referenceType'],
        referenceId: map['referenceId'],
        status: map['status'],
        lines: map['lines']
            .map<PickListLine>((line) => PickListLine.fromJson(line))
            .toList(),
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
        createdAt: toDateTimeFn(map['createdAt']),
        updatedAt: toDateTimeFn(map['updatedAt']),
      );

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'warehouseId': warehouseId,
    'referenceType': referenceType,
    'referenceId': referenceId,
    'status': status,
    'lines': lines.map((line) => line.toMap()).toList(),
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

  PickList copyWith({
    String? id,
    String? warehouseId,
    String? referenceType,
    String? referenceId,
    String? status,
    List<PickListLine>? lines,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PickList(
    id: id ?? this.id,
    warehouseId: warehouseId ?? this.warehouseId,
    referenceType: referenceType ?? this.referenceType,
    referenceId: referenceId ?? this.referenceId,
    status: status ?? this.status,
    lines: lines ?? this.lines,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    warehouseId,
    referenceType,
    referenceId,
    status,
    lines,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  ];
}

class PickListLine extends Equatable {
  final String id; // (PK)
  final String itemId; // (FK)
  final String fromLocationId; // (FK)
  final int quantity;

  const PickListLine({
    required this.id,
    required this.itemId,
    required this.fromLocationId,
    required this.quantity,
  });

  factory PickListLine.fromJson(Map<String, dynamic> map, {String? id}) =>
      PickListLine(
        id: id ?? '',
        itemId: map['itemId'],
        fromLocationId: map['fromLocationId'],
        quantity: map['quantity'],
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'itemId': itemId,
    'fromLocationId': fromLocationId,
    'quantity': quantity,
  };

  @override
  List<Object?> get props => [id, itemId, fromLocationId, quantity];
}
