import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/stock_txn_type.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

/* 3️⃣ How Each Transaction Works
✅ GRN (Goods Receipt)
    fromWarehouse = null
    toWarehouse   = WH-A
    quantity      = +100
✔ Increases stock
✔ Creates valuation entry
✔ Links to PO / Production
----
❌ Issue (Sales / Production)
    fromWarehouse = WH-A
    toWarehouse   = null
    quantity      = +20
✔ Decreases stock
✔ Hits COGS / WIP
✔ Requires availability check
-----
🔄 Stock Transfer (WH → WH / Bin → Bin)
    fromWarehouse = WH-A
    toWarehouse   = WH-B
    quantity      = +50
✔ Decrease source
✔ Increase destination
✔ Zero net valuation change*/

/* USAGE / IMPLEMENTATION of StockTransaction Model:

| Type           | fromWarehouse | toWarehouse | quantity | Meaning            |
| -------------- | ------------- | ----------- | -------- | ------------------ |
| **GRN**        | ❌ null       | ✅ required | +        | Supplier → WH      |
| **Issue**      | ✅ required   | ❌ null     | +        | WH → Sales/Prod    |
| **Transfer**   | ✅ required   | ✅ required | +        | WH → WH            |
| **Adjustment** | ❌/✅         | ✅ required | + / −    | Stock correction   |

- A. Single Posting Service (Critical)
class StockPostingService {
  Future<void> post(StockTransaction txn) async {
    _validate(txn);
    await _persistTransaction(txn);
    await _applyToInventory(txn);
  }
}

- B. Validation Rules (Per Type)
void _validate(StockTransaction txn) {
  switch (txn.txnType) {
    case StockTxnType.grn:
      assert(txn.toWarehouseId != null);
      assert(txn.fromWarehouseId == null);
      break;

    case StockTxnType.issue:
      assert(txn.fromWarehouseId != null);
      assert(txn.toWarehouseId == null);
      break;

    case StockTxnType.transfer:
      assert(txn.fromWarehouseId != null);
      assert(txn.toWarehouseId != null);
      break;

    case StockTxnType.adjustment:
      assert(txn.quantity > 0);
      break;
  }
}

- C. Inventory Update (Derived State)
void _applyToInventory(StockTransaction txn) {
  if (txn.txnType == StockTxnType.grn) {
    increaseStock(txn.toWarehouseId!, txn.itemId, txn.quantity);
  }

  if (txn.txnType == StockTxnType.issue) {
    decreaseStock(txn.fromWarehouseId!, txn.itemId, txn.quantity);
  }

  if (txn.txnType == StockTxnType.transfer) {
    decreaseStock(txn.fromWarehouseId!, txn.itemId, txn.quantity);
    increaseStock(txn.toWarehouseId!, txn.itemId, txn.quantity);
  }
}
Future<void> _decrease(
  Transaction trx,
  String warehouseId,
  String itemId,
  double qty,
) async {}

Future<void> _increase(
  Transaction trx,
  String warehouseId,
  String itemId,
  double qty,
) async {
  final ref = db
      .collection('inventory_stocks')
      .doc('$itemId-$warehouseId');

  final snap = await trx.get(ref);

  if (!snap.exists) {
    trx.set(ref, {
      'itemId': itemId,
      'warehouseId': warehouseId,
      'onHandQty': qty,
    });
  } else {
    trx.update(ref, {
      'onHandQty': FieldValue.increment(qty),
    });
  }
} */

/* USAGE-1- 🟢 Goods Receipt (GRN) UI
📋UI Inputs:
  PO Number
  Item
  Quantity Received
  Warehouse
  Location
  Unit Cost
  Lot / Serial (optional)
  Remarks
  UI → Build StockTransaction

StockTransaction(
  id: uuid(),
  txnType: StockTxnType.grn,
  sourceDocNo: poNumber,
  itemId: selectedItem.id, // FK to ItemMaster.id
  uom: selectedItem.baseUom,
  quantity: receivedQty,
  toWarehouseId: selectedWarehouse.id,
  toLocationId: selectedLocation.id,
  unitCost: unitCost,
  createdBy: currentUser.id,
  remarks: remarks,
);
🔴 UI does not touch InventoryStock*/

/* USAGE-2- 🔴 Goods Issue (GI) UI
📋UI Inputs:
  Issue To (Sales / Production / Internal)
  Item
  Quantity
  Warehouse
  Location
  Remarks
  UI → Build StockTransaction

StockTransaction(
  id: uuid(),
  txnType: StockTxnType.issue,
  sourceDocNo: issueDocNo,
  itemId: selectedItem.id,  // FK to ItemMaster.id
  uom: selectedItem.baseUom,
  quantity: issueQty,
  fromWarehouseId: selectedWarehouse.id,
  fromLocationId: selectedLocation.id,
  createdBy: currentUser.id,
  remarks: remarks,
);*/

/* USAGE-3- 🔄 Transfer UI (WH → WH Movement / Bin → Bin)
📋 UI Inputs:
  Item
  Quantity
  From Warehouse / Location
  To Warehouse / Location
  UI → Build StockTransaction

StockTransaction(
  id: uuid(),
  txnType: StockTxnType.transfer,
  sourceDocNo: transferNo,
  itemId: item.id,  // FK to ItemMaster.id
  uom: item.baseUom,
  quantity: qty,
  fromWarehouseId: fromWh.id,
  fromLocationId: fromLoc.id,
  toWarehouseId: toWh.id,
  toLocationId: toLoc.id,
  createdBy: currentUser.id,
);*/

/* USAGE-4- 🟡 Adjustment UI
📋 UI Inputs:
  Item
  Warehouse
  Counted Quantity
  Reason
  Backend calculates difference → posts transaction
  final diff = countedQty - systemQty;

StockTransaction(
  id: uuid(),
  txnType: StockTxnType.adjustment,
  sourceDocNo: 'CYCLE-COUNT',
  itemId: item.id,  // FK to ItemMaster.id
  uom: item.baseUom,
  quantity: diff.abs(),
  toWarehouseId: warehouse.id,
  createdBy: user.id,
  remarks: reason,
);*/

/// StockTransaction table
class StockTransaction extends Equatable {
  static DateTime get _today => DateTime.now();

  /// 1. Identification
  final String id; // UUID
  final StockTxnType txnType;
  final String? sourceDocType; // PO, SO, ADJ
  final String? sourceDocNo; // Unique PO, SO Number

  /// 2. Item
  final String itemId; // (FK → ItemMaster.id)
  final String uom;

  /// 3. Quantity (always positive)
  final double quantity;

  /// 4. Source (nullable for GRN)
  final String? fromWarehouseId; // (FK → Warehouse.id)
  final String? fromLocationId; // (FK → Location.id)

  /// 5. Destination (nullable for ISSUE)
  final String? toWarehouseId; // (FK → Warehouse.id)
  final String? toLocationId; // (FK → Location.id)

  /// 6. Traceability
  final String lotNumber; // (optional)
  final String serialNumber; // (optional)

  /// 7. Financial: Cost snapshot (important!)
  final double unitCost;
  final double totalCost;

  /// 8. Audit
  final String remarks;
  final String createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AuditLog> history;

  StockTransaction({
    required this.id,
    required this.txnType,
    this.sourceDocNo,
    this.sourceDocType,
    required this.itemId,
    required this.uom,
    required this.quantity,
    this.fromWarehouseId,
    this.fromLocationId,
    this.toWarehouseId,
    this.toLocationId,
    this.lotNumber = '',
    this.serialNumber = '',
    this.unitCost = 0,
    double totalCost = 0,
    required this.createdBy,
    this.updatedBy,
    this.remarks = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.history = const [],
  }) : totalCost = quantity * unitCost,
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory StockTransaction.fromMap(Map<String, dynamic> map, {String? id}) {
    return StockTransaction(
      id: id ?? map['id'] ?? '',
      txnType: StockTxnTypeUtil.fromString(map['txnType']),
      sourceDocNo: map['sourceDocNo'],
      sourceDocType: map['sourceDocType'],
      itemId: map['itemId'],
      uom: map['uom'],
      quantity: '${map['quantity']}'.asDouble,
      fromWarehouseId: map['fromWarehouseId'],
      fromLocationId: map['fromLocationId'],
      toWarehouseId: map['toWarehouseId'],
      toLocationId: map['toLocationId'],
      lotNumber: map['lotNumber'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      unitCost: '${map['unitCost']}'.asDouble,
      remarks: map['remarks'] ?? '',
      createdBy: map['createdBy'],
      updatedBy: map['updatedBy'],
      createdAt: toDateTimeFn(map['createdAt']),
      updatedAt: toDateTimeFn(map['updatedAt']),
      history: AuditLog.auditLogs(map['history']),
    );
  }

  /// Serialize to Map / JSON
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'txnType': txnType.getName,
    'sourceDocNo': sourceDocNo,
    'sourceDocType': sourceDocType,
    'itemId': itemId,
    'uom': uom,
    'quantity': quantity,
    'fromWarehouseId': fromWarehouseId,
    'fromLocationId': fromLocationId,
    'toWarehouseId': toWarehouseId,
    'toLocationId': toLocationId,
    'lotNumber': lotNumber,
    'serialNumber': serialNumber,
    'unitCost': unitCost,
    'totalCost': totalCost,
    'remarks': remarks,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'history': history.map((e) => e.toMap()).toList(),
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
    newMap['createdAt'] = createdAt.toMilliseconds;
    newMap['updatedAt'] = updatedAt.toMilliseconds;

    return {'id': id, 'data': newMap};
  }

  StockTransaction copyWith({
    String? id,
    StockTxnType? txnType,
    String? sourceDocNo,
    String? sourceDocType,
    String? itemId,
    String? uom,
    double? quantity,
    String? fromWarehouseId,
    String? fromLocationId,
    String? toWarehouseId,
    String? toLocationId,
    String? lotNumber,
    String? serialNumber,
    double? unitCost,
    double? totalCost,
    String? remarks,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AuditLog>? history,
  }) => StockTransaction(
    id: id ?? this.id,
    txnType: txnType ?? this.txnType,
    sourceDocNo: sourceDocNo ?? this.sourceDocNo,
    sourceDocType: sourceDocType ?? this.sourceDocType,
    itemId: itemId ?? this.itemId,
    uom: uom ?? this.uom,
    quantity: quantity ?? this.quantity,
    fromWarehouseId: fromWarehouseId ?? this.fromWarehouseId,
    fromLocationId: fromLocationId ?? this.fromLocationId,
    toWarehouseId: toWarehouseId ?? this.toWarehouseId,
    toLocationId: toLocationId ?? this.toLocationId,
    lotNumber: lotNumber ?? this.lotNumber,
    serialNumber: serialNumber ?? this.serialNumber,
    unitCost: unitCost ?? this.unitCost,
    totalCost: totalCost ?? this.totalCost,
    remarks: remarks ?? this.remarks,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    history: history ?? this.history,
  );

  @override
  List<Object?> get props => [
    id,
    txnType,
    sourceDocNo,
    sourceDocType,
    itemId,
    uom,
    quantity,
    fromWarehouseId,
    fromLocationId,
    toWarehouseId,
    toLocationId,
    lotNumber,
    serialNumber,
    unitCost,
    createdBy,
    remarks,
    createdAt,
    updatedAt,
    history,
  ];
}
