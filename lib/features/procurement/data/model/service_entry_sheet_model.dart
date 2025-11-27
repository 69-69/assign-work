import 'package:assign_erp/core/constants/grn_ses_status.dart';
import 'package:assign_erp/core/constants/unit_of_measure.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:equatable/equatable.dart';

/// [ServiceEntrySheet] The SES serves as a proof of delivery for the service.
/// Once the service is performed, the SES records the actual quantity and work performed,
/// and it validates the service against the PO before the buyer can approve the invoice.
class ServiceEntrySheet extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String poNumber;
  final String supplierId;
  final String storeNumber;
  final GRNSESStatus status;
  final List<SESServiceLine> servicesLines;
  final List<String> attachments;
  final String? note;

  /// [history] Audit trail: track all changes made to the PR
  final List<AuditLog> history;

  final String receivedBy;

  final DateTime serviceStart;
  final DateTime serviceEnd;

  /// [receivedAt] System timestamp when the SES was recorded in the system (audit trail)
  final DateTime receivedAt;

  ServiceEntrySheet({
    this.id = '',
    required this.poNumber,
    required this.supplierId,
    required this.storeNumber,
    this.status = GRNSESStatus.draft,
    required this.servicesLines,
    this.attachments = const [],
    this.note,
    required this.receivedBy,
    DateTime? receivedAt,
    DateTime? serviceStart,
    DateTime? serviceEnd,
    List<AuditLog>? history,
  }) : history = history ?? [],
       receivedAt = receivedAt ?? _today,
       serviceStart = serviceStart ?? _today,
       serviceEnd = serviceEnd ?? _today;

  factory ServiceEntrySheet.fromMap(Map<String, dynamic> map, {String? id}) {
    return ServiceEntrySheet(
      id: id ?? map['id'] ?? '',
      poNumber: map['poNumber'],
      storeNumber: map['storeNumber'] ?? '',
      supplierId: map['supplierId'] ?? '',
      status: GRNSESStatusHelper.fromString(map['status']),
      servicesLines: (map['servicesLines'] as List? ?? [])
          .map((i) => SESServiceLine.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
      attachments: List<String>.from(map['attachments'] ?? []),
      history: (map['history'] as List? ?? [])
          .map((i) => AuditLog.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
      note: map['note'] ?? '',
      receivedBy: map['receivedBy'] ?? '',
      receivedAt: toDateTimeFn(map['receivedAt'] ?? '$_today'),
      serviceStart: toDateTimeFn(map['serviceStart'] ?? '$_today'),
      serviceEnd: toDateTimeFn(map['serviceEnd'] ?? '$_today'),
    );
  }

  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'storeNumber': storeNumber,
    'poNumber': poNumber,
    'supplierId': supplierId,
    'status': getSESStatus,
    'serviceStart': serviceStart,
    'serviceEnd': serviceEnd,
    'servicesLines': servicesLines.map((i) => i.toMap()).toList(),
    'attachments': attachments,
    'receivedBy': receivedBy,
    'receivedAt': receivedAt,
    'note': note,
    'history': history.map((i) => i.toMap()).toList(),
  };

  Map<String, dynamic> toMap() {
    final newMap = _mapTemp();
    newMap['receivedAt'] = newMap['receivedAt'].toIsoString();
    newMap['serviceStart'] = newMap['serviceStart'].toIsoString();
    newMap['serviceEnd'] = newMap['serviceEnd'].toIsoString();

    return newMap;
  }

  Map<String, dynamic> toCache() {
    final newMap = _mapTemp();
    newMap['receivedAt'] = receivedAt.millisecondsSinceEpoch;

    return {'id': id, 'data': newMap};
  }

  /// A singleton instance representing an empty/default ServiceEntrySheet.
  /// Used as a fallback when no matching SES is found.
  static final ServiceEntrySheet empty = ServiceEntrySheet(
    poNumber: '',
    supplierId: '',
    storeNumber: '',
    status: GRNSESStatus.draft,
    servicesLines: [],
    receivedBy: '',
  );

  bool get isNotEmpty => servicesLines.isNotEmpty;

  String get getSESStatus => status.getLabel;

  ServiceEntrySheet copyWith({
    String? id,
    String? poNumber,
    String? supplierId,
    String? storeNumber,
    GRNSESStatus? status,
    List<SESServiceLine>? servicesLines,
    List<String>? attachments,
    String? note,
    List<AuditLog>? history,
    String? receivedBy,
    DateTime? receivedAt,
    DateTime? serviceStart,
    DateTime? serviceEnd,
  }) => ServiceEntrySheet(
    id: id ?? this.id,
    poNumber: poNumber ?? this.poNumber,
    supplierId: supplierId ?? this.supplierId,
    storeNumber: storeNumber ?? this.storeNumber,
    status: status ?? this.status,
    servicesLines: servicesLines ?? this.servicesLines,
    attachments: attachments ?? this.attachments,
    note: note ?? this.note,
    history: history ?? this.history,
    receivedBy: receivedBy ?? this.receivedBy,
    receivedAt: receivedAt ?? this.receivedAt,
    serviceStart: serviceStart ?? this.serviceStart,
    serviceEnd: serviceEnd ?? this.serviceEnd,
  );

  @override
  List<Object?> get props => [
    id,
    poNumber,
    supplierId,
    storeNumber,
    receivedBy,
    status,
    serviceStart,
    serviceEnd,
    servicesLines,
    attachments,
    note,
    history,
    receivedAt,
  ];
}

class SESServiceLine extends Equatable {
  final String serviceCode;
  final String serviceName; // <- updated (service name/task name)
  final UnitOfMeasure unitOfMeasure; // hour, day, task, milestone
  final double orderedQty;
  final double completedQty;

  /// [unitPrice] Price for unit of service
  final double unitPrice;

  const SESServiceLine({
    required this.serviceCode,
    required this.serviceName, // <- updated
    required this.unitOfMeasure,
    required this.orderedQty,
    required this.completedQty,
    required this.unitPrice,
  });

  factory SESServiceLine.fromMap(Map<String, dynamic> map) {
    return SESServiceLine(
      serviceCode: map['serviceCode'] ?? '',
      serviceName: map['serviceName'] ?? '',
      unitOfMeasure: map['unitOfMeasure'] ?? '',
      orderedQty: double.tryParse('${map['orderedQty']}') ?? 0.0,
      completedQty: double.tryParse('${map['completedQty']}') ?? 0.0,
      unitPrice: double.tryParse('${map['unitPrice']}') ?? 0.0,
    );
  }
  Map<String, dynamic> toMap() => {
    'serviceCode': serviceCode,
    'serviceName': serviceName,
    'unitOfMeasure': unitOfMeasure,
    'orderedQty': orderedQty,
    'completedQty': completedQty,
    'unitPrice': unitPrice,
  };

  String get getUnitOfMeasure => unitOfMeasure.getLabel;

  bool filterByAny(String filter) =>
      itemAsList.any((item) => item.contains(filter));

  /// For UI display only
  List<String> get itemAsList => [serviceCode, serviceName, getUnitOfMeasure];

  /// For UI Header display only
  static List<String> get dataTableHeader => const ['Code', 'Name', 'Unit'];

  double get total => completedQty * unitPrice;

  @override
  List<Object?> get props => [
    serviceCode,
    serviceName,
    unitOfMeasure,
    orderedQty,
    completedQty,
    unitPrice,
  ];

  SESServiceLine copyWith({
    String? serviceCode,
    String? serviceName,
    UnitOfMeasure? unitOfMeasure,
    double? orderedQty,
    double? completedQty,
    double? unitPrice,
  }) => SESServiceLine(
    serviceCode: serviceCode ?? this.serviceCode,
    serviceName: serviceName ?? this.serviceName,
    unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
    orderedQty: orderedQty ?? this.orderedQty,
    completedQty: completedQty ?? this.completedQty,
    unitPrice: unitPrice ?? this.unitPrice,
  );
}
