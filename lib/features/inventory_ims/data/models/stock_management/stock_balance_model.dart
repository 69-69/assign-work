import 'package:assign_erp/core/util/extensions/stock_txn_type.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/inventory_ims/data/models/stock_management/stock_transaction_model.dart';
import 'package:equatable/equatable.dart';

/// Inventory Stock Balance table: This is not a transaction table.
/// ✔ This table is updated by StockTransactions
/// ❌ Never edited directly by users
class StockBalance extends Equatable {
  static DateTime get _today => DateTime.now();

  /// 1. Identification
  final String id; // UUID
  final String itemId; // FK → ItemMaster.id

  /// 2. Location
  final String warehouseId; // (FK → Warehouse.id) → physical building
  final String locationId; // (FK → Location.id) → Bin / Shelf / Subinventory

  /// 3. Quantity
  late final double onHandQty;
  final double reservedQty;

  /// 4. Traceability
  final String lotNumber;
  final String serialNumber;
  final String stockStatus; // unrestricted, blocked, qc

  /// 5. Audit
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  StockBalance({
    required this.id,
    required this.itemId,
    required this.warehouseId,
    required this.locationId,
    required this.onHandQty,
    this.reservedQty = 0,
    this.lotNumber = '',
    this.serialNumber = '',
    this.stockStatus = 'UNRESTRICTED',
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory StockBalance.fromMap(Map<String, dynamic> map) {
    return StockBalance(
      id: map['id'],
      itemId: map['itemId'],
      warehouseId: map['warehouseId'],
      locationId: map['locationId'],
      onHandQty: '${map['onHandQty']}'.asDouble,
      reservedQty: '${map['reservedQty']}'.asDouble,
      lotNumber: map['lotNumber'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      stockStatus: map['stockStatus'] ?? 'UNRESTRICTED',
      createdBy: map['createdBy'],
      updatedBy: map['updatedBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      updatedAt: toDateTimeFn(map['updatedAt']),
    );
  }

  /// Serialize to Map / JSON
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'itemId': itemId,
    'warehouseId': warehouseId,
    'locationId': locationId,
    'onHandQty': onHandQty,
    'reservedQty': reservedQty,
    'lotNumber': lotNumber,
    'serialNumber': serialNumber,
    'stockStatus': stockStatus,
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

  double get availableQty => onHandQty - reservedQty;

  void applyTransaction(
    StockBalance source,
    StockBalance destination,
    StockTransaction txn,
  ) {
    final qty = txn.lines.map((a) => a.quantity).reduce((a, b) => a + b);

    switch (txn.txnType) {
      case StockTxnType.grn:
        destination.onHandQty += qty;
        break;

      case StockTxnType.issue:
        source.onHandQty -= qty;
        break;

      case StockTxnType.transfer:
        source.onHandQty -= qty;
        destination.onHandQty += qty;
        break;

      case StockTxnType.adjustment:
        destination.onHandQty += qty;
        break;
    }
  }

  StockBalance copyWith({
    String? id,
    String? itemId,
    String? warehouseId,
    String? locationId,
    double? onHandQty,
    double? reservedQty,
    String? lotNumber,
    String? serialNumber,
    String? stockStatus,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) => StockBalance(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    warehouseId: warehouseId ?? this.warehouseId,
    locationId: locationId ?? this.locationId,
    onHandQty: onHandQty ?? this.onHandQty,
    reservedQty: reservedQty ?? this.reservedQty,
    lotNumber: lotNumber ?? this.lotNumber,
    serialNumber: serialNumber ?? this.serialNumber,
    stockStatus: stockStatus ?? this.stockStatus,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedBy: updatedBy ?? this.updatedBy,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    itemId,
    warehouseId,
    locationId,
    onHandQty,
    reservedQty,
    lotNumber,
    serialNumber,
    stockStatus,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];
}
