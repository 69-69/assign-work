import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:equatable/equatable.dart';

/*WarehouseReceipt
----------------
id (PK)
warehouseId (FK)
referenceType (PO | Transfer | Return)
referenceId
status (Draft | Received)
receivedAt

WarehouseReceiptLine
--------------------
id (PK)
receiptId (FK)
itemId (FK)
quantity */

/// [WHReceipt] Receiving (Inbound Execution)
class WHReceipt extends Equatable {
  static final DateTime _today = DateTime.now();

  final String id;
  final String warehouseId;
  final String referenceType;
  final String referenceId;
  final String status;
  final DateTime receivedAt;
  final List<WMSReceiptLine> receiptLines;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  WHReceipt({
    required this.id,
    required this.warehouseId,
    required this.referenceType,
    required this.referenceId,
    required this.status,
    required this.receivedAt,
    required this.receiptLines,
    this.createdBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory WHReceipt.fromMap(Map<String, dynamic> map, {String? id}) =>
      WHReceipt(
        id: id ?? map['id'],
        warehouseId: map['warehouseId'],
        referenceType: map['referenceType'],
        referenceId: map['referenceId'],
        status: map['status'],
        receivedAt: DateTime.parse(map['receivedAt']),
        receiptLines: List<WMSReceiptLine>.from(
          map['receiptLines'].map((x) => WMSReceiptLine.fromMap(x)),
        ),
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
    'receivedAt': receivedAt.toIso8601String(),
    'receiptLines': receiptLines.map((x) => x.toMap()).toList(),
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

  WHReceipt copyWith({
    String? id,
    String? warehouseId,
    String? referenceType,
    String? referenceId,
    String? status,
    DateTime? receivedAt,
    List<WMSReceiptLine>? receiptLines,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WHReceipt(
    id: id ?? this.id,
    warehouseId: warehouseId ?? this.warehouseId,
    referenceType: referenceType ?? this.referenceType,
    referenceId: referenceId ?? this.referenceId,
    status: status ?? this.status,
    receivedAt: receivedAt ?? this.receivedAt,
    receiptLines: receiptLines ?? this.receiptLines,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    warehouseId,
    referenceType,
    referenceId,
    status,
    receivedAt,
    receiptLines,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  ];
}

class WMSReceiptLine extends Equatable {
  final String id;
  final String receiptId;
  final String itemId;
  final int quantity;

  const WMSReceiptLine({
    required this.id,
    required this.receiptId,
    required this.itemId,
    required this.quantity,
  });

  factory WMSReceiptLine.fromMap(Map<String, dynamic> map, {String? id}) =>
      WMSReceiptLine(
        id: id ?? map['id'],
        receiptId: map['receiptId'],
        itemId: map['itemId'],
        quantity: map['quantity'],
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'receiptId': receiptId,
    'itemId': itemId,
    'quantity': quantity,
  };

  @override
  List<Object?> get props => [id, receiptId, itemId, quantity];
}
