import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/workflow_status.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:equatable/equatable.dart';

/// Release stock for in-store, online sales, POS or internal use
/// It also records Snapshots of Items sold in Sales Orders and POS transactions
class GoodsIssue extends Equatable {
  static get _today => DateTime.now();

  /// 1. Identification
  final String id; // UUID
  final String documentNumber; // Human-readable
  final WorkflowStatus status; // draft, posted, etc.
  final String issuedBy;
  final DateTime issuedAt;
  final String notes;

  /// 2. Reference to original transaction
  final String? salesOrderId; // Optional link to Sales Order
  final String? posTransactionId; // Optional link to POS
  final String? sourceDocumentType;

  /// 3. Warehouse info
  final String warehouseId;

  /// 4. Line items
  final List<GoodsIssueLine> lineItems;

  /// 5. Audit / traceability
  final List<AuditLog> history;

  GoodsIssue({
    required this.id,
    required this.documentNumber,
    this.status = WorkflowStatus.draft,
    required this.issuedBy,
    DateTime? issuedAt,
    this.notes = '',
    this.salesOrderId,
    this.posTransactionId,
    this.sourceDocumentType,
    required this.warehouseId,
    required this.lineItems,
    List<AuditLog>? history,
  }) : issuedAt = issuedAt ?? _today,
       history = history ?? [];

  /// Deserialize from Map / JSON
  factory GoodsIssue.fromMap(Map<String, dynamic> map) {
    return GoodsIssue(
      id: map['id'] ?? '',
      documentNumber: map['documentNumber'] ?? '',
      issuedBy: map['issuedBy'] ?? '',
      issuedAt: toDateTimeFn(map['issuedAt'] ?? _today),
      notes: map['notes'],
      status: WorkflowStatusUtil.fromString(map['status']),
      salesOrderId: map['salesOrderId'],
      posTransactionId: map['posTransactionId'],
      sourceDocumentType: map['sourceDocumentType'],
      warehouseId: map['warehouseId'] ?? '',
      lineItems:
          (map['lineItems'] as List<dynamic>?)
              ?.map((e) => GoodsIssueLine.fromMap(e))
              .toList() ??
          [],
      history:
          (map['history'] as List<dynamic>?)
              ?.map((e) => AuditLog.fromMap(e))
              .toList() ??
          [],
    );
  }

  /// Serialize to Map / JSON
  Map<String, dynamic> toMap() => {
    'id': id,
    'documentNumber': documentNumber,
    'status': status.getName,
    'issuedBy': issuedBy,
    'issuedAt': issuedAt.toIso8601String(),
    'notes': notes,
    'salesOrderId': salesOrderId,
    'posTransactionId': posTransactionId,
    'sourceDocumentType': sourceDocumentType,
    'warehouseId': warehouseId,
    'lineItems': lineItems.map((e) => e.toMap()).toList(),
    'history': history.map((e) => e.toMap()).toList(),
  };

  @override
  List<Object?> get props => [
    id,
    documentNumber,
    status,
    issuedBy,
    issuedAt,
    notes,
    salesOrderId,
    posTransactionId,
    sourceDocumentType,
    warehouseId,
    lineItems,
    history,
  ];
}

class GoodsIssueLine extends Equatable {
  final String id; // UUID
  final String goodsIssueId; // FK to GI
  final String lineReferenceId; // FK to SO/POS line
  final String productId; // FK to Product Master
  final String sku; // Snapshot
  final String productName; // Snapshot
  final double quantityIssued;
  final String uom; // Unit of measure
  final double? unitPrice; // Optional, snapshot for reporting
  final double? taxRate; // Optional, snapshot

  const GoodsIssueLine({
    required this.id,
    required this.goodsIssueId,
    required this.lineReferenceId,
    required this.productId,
    required this.sku,
    required this.productName,
    required this.quantityIssued,
    this.uom = 'pcs',
    this.unitPrice,
    this.taxRate,
  });

  factory GoodsIssueLine.fromMap(Map<String, dynamic> map) {
    return GoodsIssueLine(
      id: map['id'] ?? '',
      goodsIssueId: map['goodsIssueId'] ?? '',
      lineReferenceId: map['lineReferenceId'] ?? '',
      productId: map['productId'] ?? '',
      sku: map['sku'] ?? '',
      productName: map['productName'] ?? '',
      quantityIssued: (map['quantityIssued'] ?? 0).toDouble(),
      uom: map['uom'] ?? 'pcs',
      unitPrice: map['unitPrice'] != null
          ? (map['unitPrice']).toDouble()
          : null,
      taxRate: map['taxRate'] != null ? (map['taxRate']).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'goodsIssueId': goodsIssueId,
    'lineReferenceId': lineReferenceId,
    'productId': productId,
    'sku': sku,
    'productName': productName,
    'quantityIssued': quantityIssued,
    'uom': uom,
    'unitPrice': unitPrice,
    'taxRate': taxRate,
  };

  @override
  List<Object?> get props => [
    id,
    goodsIssueId,
    lineReferenceId,
    productId,
    sku,
    productName,
    quantityIssued,
    uom,
    unitPrice,
    taxRate,
  ];
}
