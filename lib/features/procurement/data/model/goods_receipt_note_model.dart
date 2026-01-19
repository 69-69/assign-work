import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/grn_ses_status.dart';
import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

class GoodsReceiptNote extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String poNumber;
  final String supplierId;
  final String warehouseId;
  final String storeNumber; // FK CompanyStore.storeNumber
  final GRNSESStatus status;
  final List<GRNLineItem> lineItems;
  final List<String> attachments;
  final String? notes;

  /// [history] Audit trail: track all changes made to the PR
  final List<AuditLog> history;

  /// [receivedAt] System timestamp when the GRN was recorded in the system (audit trail)
  final DateTime receivedAt;
  final String receivedBy;

  GoodsReceiptNote({
    this.id = '',
    required this.poNumber,
    required this.supplierId,
    this.warehouseId = '',
    required this.storeNumber,
    this.status = GRNSESStatus.draft,
    required this.lineItems,
    this.attachments = const [],
    this.notes,
    required this.receivedBy,
    DateTime? receivedAt,
    List<AuditLog>? history,
  }) : history = history ?? [],
       receivedAt = receivedAt ?? _today;

  factory GoodsReceiptNote.fromMap(Map<String, dynamic> map, {String? id}) {
    return GoodsReceiptNote(
      id: id ?? map['id'] ?? '',
      poNumber: map['poNumber'],
      storeNumber: map['storeNumber'] ?? '',
      supplierId: map['supplierId'] ?? '',
      warehouseId: map['warehouseId'] ?? '',
      status: GRNSESStatusUtil.fromString(map['status']),
      lineItems: (map['lineItems'] as List? ?? [])
          .map((i) => GRNLineItem.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
      attachments: List<String>.from(map['attachments'] ?? []),
      receivedBy: map['receivedBy'] ?? '',
      receivedAt: toDateTimeFn(map['receivedAt'] ?? '$_today'),
      history: (map['history'] as List? ?? [])
          .map((i) => AuditLog.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'storeNumber': storeNumber,
    'poNumber': poNumber,
    'supplierId': supplierId,
    'warehouseId': warehouseId,
    'status': status.name,
    'notes': notes,
    'lineItems': lineItems.map((i) => i.toMap()).toList(),
    'attachments': attachments,
    'receivedBy': receivedBy,
    'receivedAt': receivedAt,
    'history': history.map((i) => i.toMap()).toList(),
  };

  Map<String, dynamic> toMap() {
    final newMap = _mapTemp();
    newMap['receivedAt'] = newMap['receivedAt'].toIsoString();

    return newMap;
  }

  Map<String, dynamic> toCache() {
    final newMap = _mapTemp();
    newMap['receivedAt'] = receivedAt.toMilliseconds;

    return {'id': id, 'data': newMap};
  }

  /// A singleton instance representing an empty/default GoodsReceiptNote.
  /// Used as a fallback when no matching GRN is found.
  static final GoodsReceiptNote empty = GoodsReceiptNote(
    poNumber: '',
    storeNumber: '',
    supplierId: '',
    receivedBy: '',
    lineItems: [],
  );

  /// Returns true if this instance is the singleton [empty] PR.
  /// Use this to check if the PR is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, GoodsReceiptNote.empty);

  bool get isNotEmpty => lineItems.isNotEmpty;

  String get getGRNStatus => status.getLabel;

  bool filterByAny(String filter) =>
      itemAsList.filterAny(filter) ||
      notes.filterAny(filter) ||
      lineItems.any((i) => i.filterByAny(filter));

  /// For UI display only
  List<String> get itemAsList => [
    id,
    poNumber,
    supplierId,
    receivedBy,
    getGRNStatus,
  ];

  /// For UI Header display only
  static List<String> get dataTableHeader => const [
    'ID',
    'PO Number',
    'Supplier ID',
    'Received By',
    'Status',
  ];

  GoodsReceiptNote copyWith({
    String? id,
    String? poNumber,
    String? supplierId,
    String? warehouseId,
    String? storeNumber,
    GRNSESStatus? status,
    List<GRNLineItem>? lineItems,
    List<String>? attachments,
    String? notes,
    DateTime? receivedAt,
    String? receivedBy,
    List<AuditLog>? history,
  }) => GoodsReceiptNote(
    id: id ?? this.id,
    poNumber: poNumber ?? this.poNumber,
    supplierId: supplierId ?? this.supplierId,
    warehouseId: warehouseId ?? this.warehouseId,
    storeNumber: storeNumber ?? this.storeNumber,
    status: status ?? this.status,
    lineItems: lineItems ?? this.lineItems,
    attachments: attachments ?? this.attachments,
    notes: notes ?? this.notes,
    receivedAt: receivedAt ?? this.receivedAt,
    receivedBy: receivedBy ?? this.receivedBy,
    history: history ?? this.history,
  );

  @override
  List<Object?> get props => [
    id,
    poNumber,
    supplierId,
    warehouseId,
    receivedBy,
    status,
    lineItems,
    attachments,
    notes,
    receivedAt,
    receivedBy,
    history,
  ];
}

class GRNLineItem extends Equatable {
  final String itemCode;
  final String itemName; // <- updated
  final UnitOfMeasure unitOfMeasure;
  final double orderedQty;
  final double receivedQty;
  final double acceptedQty;
  final double rejectedQty;
  final String? batchNo;
  final List<String>? serialNumbers;

  const GRNLineItem({
    required this.itemCode,
    required this.itemName, // <- updated
    required this.unitOfMeasure,
    required this.orderedQty,
    required this.receivedQty,
    required this.acceptedQty,
    required this.rejectedQty,
    this.batchNo,
    this.serialNumbers,
  });

  factory GRNLineItem.fromMap(Map<String, dynamic> map) {
    return GRNLineItem(
      itemName: map['itemName'] ?? '',
      itemCode: map['itemCode'] ?? '',
      unitOfMeasure: UOMUtil.fromString(map['unitOfMeasure']),
      orderedQty: '${map['orderedQty']}'.asDouble,
      receivedQty: '${map['receivedQty']}'.asDouble,
      acceptedQty: '${map['acceptedQty']}'.asDouble,
      rejectedQty: '${map['rejectedQty']}'.asDouble,
      batchNo: map['batchNo'] ?? '',
      serialNumbers: List<String>.from(map['serialNumbers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'itemName': itemName,
    'itemCode': itemCode,
    'unitOfMeasure': getUnitOfMeasure,
    'orderedQty': orderedQty,
    'receivedQty': receivedQty,
    'acceptedQty': acceptedQty,
    'rejectedQty': rejectedQty,
    'batchNo': batchNo,
    'serialNumbers': serialNumbers,
  };

  String get getUnitOfMeasure => unitOfMeasure.getLabel;

  /// Filter/search
  bool filterByAny(String filter) => itemAsList.filterAny(filter);

  /// For UI display only
  List<String> get itemAsList => [
    itemCode,
    itemName.toTitle,
    '$orderedQty',
    getUnitOfMeasure.toTitle,
    batchNo ?? '',
  ];

  /// For UI Header display only
  static List<String> get dataTableHeader => const [
    'Code',
    'Name',
    'Ordered Qty',
    'Unit',
    'Batch No',
  ];

  @override
  List<Object?> get props => [
    itemCode,
    itemName,
    unitOfMeasure,
    orderedQty,
    receivedQty,
    acceptedQty,
    rejectedQty,
    batchNo,
    serialNumbers,
  ];

  GRNLineItem copyWith({
    String? itemCode,
    String? itemName,
    UnitOfMeasure? unitOfMeasure,
    double? orderedQty,
    double? receivedQty,
    double? acceptedQty,
    double? rejectedQty,
    String? batchNo,
    List<String>? serialNumbers,
  }) => GRNLineItem(
    itemCode: itemCode ?? this.itemCode,
    itemName: itemName ?? this.itemName,
    unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
    orderedQty: orderedQty ?? this.orderedQty,
    receivedQty: receivedQty ?? this.receivedQty,
    acceptedQty: acceptedQty ?? this.acceptedQty,
    rejectedQty: rejectedQty ?? this.rejectedQty,
    batchNo: batchNo ?? this.batchNo,
    serialNumbers: serialNumbers ?? this.serialNumbers,
  );
}
