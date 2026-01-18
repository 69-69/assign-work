import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/enum_util.dart';
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
  status: status,
  quantity: diff.abs(),
  toWarehouseId: warehouse.id,
  createdBy: user.id,
  remarks: reason,
);*/

enum StockStatus { draft, posted }

extension StockStatusExt on StockStatus {
  String get getName => EnumUtil<StockStatus>(this).getName;
}

/// Stock Transaction table
class StockTransaction extends Equatable {
  static DateTime get _today => DateTime.now();

  /// 1. Identification
  final String id; // UUID
  final StockTxnType txnType; // (GR | GI | TRANSFER | ADJUSTMENT)
  final String? sourceDocType; // PO, SO, ADJ
  final String? sourceDocNo; // Unique PO, SO Number

  /// 2. Line Items
  final List<StockTransactionLine> lines;
  final StockStatus status;

  /// 3. Traceability
  final String lotNumber; // (optional)
  final String serialNumber; // (optional)

  /// 4. Audit
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
    required this.lines,
    this.status = StockStatus.draft,
    this.lotNumber = '',
    this.serialNumber = '',
    required this.createdBy,
    this.updatedBy,
    this.remarks = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.history = const [],
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory StockTransaction.fromMap(Map<String, dynamic> map, {String? id}) {
    return StockTransaction(
      id: id ?? map['id'] ?? '',
      txnType: StockTxnTypeUtil.fromString(map['txnType']),
      sourceDocNo: map['sourceDocNo'],
      sourceDocType: map['sourceDocType'],
      status: fromString(map['status']),
      lotNumber: map['lotNumber'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      remarks: map['remarks'] ?? '',
      createdBy: map['createdBy'],
      updatedBy: map['updatedBy'],
      createdAt: toDateTimeFn(map['createdAt']),
      updatedAt: toDateTimeFn(map['updatedAt']),
      history: AuditLog.auditLogs(map['history']),
      lines: [],
    );
  }

  /// Serialize to Map / JSON
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'txnType': txnType.getName,
    'sourceDocNo': sourceDocNo,
    'sourceDocType': sourceDocType,
    'status': status.getName,
    'lotNumber': lotNumber,
    'serialNumber': serialNumber,
    'lines': lines.map((e) => e.toMap()).toList(),
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
    StockStatus? status,
    List<StockTransactionLine>? lines,
    String? lotNumber,
    String? serialNumber,
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
    status: status ?? this.status,
    lotNumber: lotNumber ?? this.lotNumber,
    serialNumber: serialNumber ?? this.serialNumber,
    lines: lines ?? this.lines,
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
    status,
    lotNumber,
    serialNumber,
    lines,
    createdBy,
    remarks,
    createdAt,
    updatedAt,
    history,
  ];

  /// [fromString] Converts String/Label to enum value.
  static StockStatus fromString(String? value) =>
      EnumUtil.fromString<StockStatus>(StockStatus.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final label = includeHeader ? 'Warehouse type' : '';
    return EnumUtil.toStringList<StockStatus>(StockStatus.values, label);
  }
}

/// Stock Transaction Line
class StockTransactionLine extends Equatable {
  /// 1. Identification
  final String id;
  final String stockTxnId;

  /// 2. Item Master
  final String itemId; // (FK → ItemMaster.id)

  /// 3. Financial: Cost snapshot &Quantity (always positive)
  final double quantity;
  //snapshot
  final double unitCost;
  final double totalCost;

  /// 4. Source (nullable for GRN)
  final String? fromWarehouseId; // (FK → Warehouse.id)
  final String? fromLocationId; // (FK → Location.id)
  final String? fromBinId; // (FK → Bin.id)

  /// 5. Destination (nullable for ISSUE)
  final String? toWarehouseId; // (FK → Warehouse.id)
  final String? toLocationId; // (FK → Location.id)
  final String? toBinId; // (FK → Bin.id)

  const StockTransactionLine({
    required this.id,
    required this.stockTxnId,
    required this.itemId,
    required this.quantity,
    this.unitCost = 0,
    this.fromWarehouseId,
    this.fromLocationId,
    this.fromBinId,
    this.toWarehouseId,
    this.toLocationId,
    this.toBinId,
    double totalCost = 0,
  }) : totalCost = quantity * unitCost;

  factory StockTransactionLine.fromMap(Map<String, dynamic> map, {String? id}) {
    return StockTransactionLine(
      id: id ?? map['id'] ?? '',
      stockTxnId: map['stockTxnId'],
      itemId: map['itemId'],
      quantity: '${map['quantity']}'.asDouble,
      unitCost: '${map['unitCost']}'.asDouble,
      fromWarehouseId: map['fromWarehouseId'],
      fromLocationId: map['fromLocationId'],
      fromBinId: map['fromBinId'],
      toWarehouseId: map['toWarehouseId'],
      toLocationId: map['toLocationId'],
      toBinId: map['toBinId'],
    );
  }

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() => {
    'id': id,
    'stockTxnId': stockTxnId,
    'itemId': itemId,
    'quantity': quantity,
    'fromWarehouseId': fromWarehouseId,
    'fromLocationId': fromLocationId,
    'fromBinId': fromBinId,
    'toWarehouseId': toWarehouseId,
    'toLocationId': toLocationId,
    'toBinId': toBinId,
    'unitCost': unitCost,
  };

  /// A singleton instance representing an empty/default StockTransactionLine.
  static get empty =>
      StockTransactionLine(id: '', stockTxnId: '', itemId: '', quantity: 0);

  /// Returns true if this instance is the singleton [empty] StockTransactionLine.
  bool get isEmpty => identical(this, StockTransactionLine.empty);

  bool filterByAny(String keyword) => props.filterAny(keyword);

  StockTransactionLine copyWith({
    String? id,
    String? stockTxnId,
    String? itemId,
    double? quantity,
    double? unitCost,
    String? fromWarehouseId,
    String? fromLocationId,
    String? fromBinId,
    String? toWarehouseId,
    String? toLocationId,
    String? toBinId,
  }) => StockTransactionLine(
    id: id ?? this.id,
    stockTxnId: stockTxnId ?? this.stockTxnId,
    itemId: itemId ?? this.itemId,
    quantity: quantity ?? this.quantity,
    unitCost: unitCost ?? this.unitCost,
    fromWarehouseId: fromWarehouseId ?? this.fromWarehouseId,
    fromLocationId: fromLocationId ?? this.fromLocationId,
    fromBinId: fromBinId ?? this.fromBinId,
    toWarehouseId: toWarehouseId ?? this.toWarehouseId,
    toLocationId: toLocationId ?? this.toLocationId,
    toBinId: toBinId ?? this.toBinId,
  );

  @override
  List<Object?> get props => [
    id,
    stockTxnId,
    itemId,
    quantity,
    unitCost,
    fromWarehouseId,
    fromLocationId,
    fromBinId,
    toWarehouseId,
    toLocationId,
    toBinId,
  ];

  List<String> get itemAsList => [
    '$quantity',
    '$unitCost',
    itemId,
    fromWarehouseId ?? '',
    fromLocationId ?? '',
    fromBinId ?? '',
    toWarehouseId ?? '',
    toLocationId ?? '',
  ];

  List<String> get dataTableHeader => [
    'Quantity',
    'Unit Cost',
    'Item ID',
    'From Warehouse',
    'From Location',
    'From Bin',
    'To Warehouse',
    'To Location'
        'To Bin',
  ];
}
