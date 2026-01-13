import 'package:assign_erp/core/util/extensions/stock_txn_type.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/inventory_ims/data/models/stock_management/stock_transaction_model.dart';
import 'package:equatable/equatable.dart';

class InventoryStock extends Equatable {
  static DateTime get _today => DateTime.now();

  /// 1. Identification
  final String id; // UUID
  final String itemId; // FK → ItemMaster.id

  /// 2. Location
  final String warehouseId;
  final String locationId; // Bin / Shelf / Subinventory

  /// 3. Quantity
  late final double onHandQty;
  final double reservedQty;
  final String uom;

  /// 4. Traceability
  final String lotNumber;
  final String serialNumber;
  final String stockStatus; // unrestricted, blocked, qc

  /// 5. Audit
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  InventoryStock({
    required this.id,
    required this.itemId,
    required this.warehouseId,
    required this.locationId,
    required this.onHandQty,
    this.reservedQty = 0,
    required this.uom,
    this.lotNumber = '',
    this.serialNumber = '',
    this.stockStatus = 'UNRESTRICTED',
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory InventoryStock.fromMap(Map<String, dynamic> map) {
    return InventoryStock(
      id: map['id'],
      itemId: map['itemId'],
      warehouseId: map['warehouseId'],
      locationId: map['locationId'],
      onHandQty: '${map['onHandQty']}'.asDouble,
      reservedQty: '${map['reservedQty']}'.asDouble,
      uom: map['uom'],
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
    'uom': uom,
    'lotNumber': lotNumber,
    'serialNumber': serialNumber,
    'stockStatus': stockStatus,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
  };

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['deliveryDate'] = createdAt.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['deliveryDate'] = createdAt.toMilliseconds;
    newMap['createdAt'] = createdAt.toMilliseconds;
    newMap['updatedAt'] = updatedAt.toMilliseconds;

    return {'id': id, 'data': newMap};
  }

  double get availableQty => onHandQty - reservedQty;
  void applyTransaction(
    InventoryStock source,
    InventoryStock destination,
    StockTransaction txn,
  ) {
    switch (txn.type) {
      case StockTxnType.grn:
        destination.onHandQty += txn.quantity;
        break;

      case StockTxnType.issue:
        source.onHandQty -= txn.quantity;
        break;

      case StockTxnType.transfer:
        source.onHandQty -= txn.quantity;
        destination.onHandQty += txn.quantity;
        break;

      case StockTxnType.adjustment:
        destination.onHandQty += txn.quantity;
        break;
    }
  }

  InventoryStock copyWith({
    String? id,
    String? itemId,
    String? warehouseId,
    String? locationId,
    double? onHandQty,
    double? reservedQty,
    String? uom,
    String? lotNumber,
    String? serialNumber,
    String? stockStatus,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) => InventoryStock(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    warehouseId: warehouseId ?? this.warehouseId,
    locationId: locationId ?? this.locationId,
    onHandQty: onHandQty ?? this.onHandQty,
    reservedQty: reservedQty ?? this.reservedQty,
    uom: uom ?? this.uom,
    lotNumber: lotNumber ?? this.lotNumber,
    serialNumber: serialNumber ?? this.serialNumber,
    stockStatus: stockStatus ?? this.stockStatus,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedBy: updatedBy ?? this.updatedBy,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [id, itemId, warehouseId, locationId];
}
