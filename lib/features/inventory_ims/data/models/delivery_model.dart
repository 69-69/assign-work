import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

class Delivery extends Equatable {
  static get _today => DateTime.now();

  final String id;
  final String storeNumber; // FK CompanyStore.storeNumber
  final String orderNumber;
  final String status;
  final String barcode;
  final String deliveryPhone;
  final String deliveryType;
  final String deliveryPerson;
  final String? remarks;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  Delivery({
    this.id = '',
    required this.status,
    required this.storeNumber,
    required this.orderNumber,
    required this.barcode,
    required this.deliveryType,
    this.deliveryPerson = '',
    this.deliveryPhone = '',
    this.remarks,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [Delivery.fromMap]
  factory Delivery.fromMap(Map<String, dynamic> data, String documentId) {
    return Delivery(
      id: documentId,
      status: data['status'] ?? '',
      storeNumber: data['storeNumber'] ?? '',
      orderNumber: data['orderNumber'] ?? '',
      barcode: data['barcode'] ?? '',
      deliveryType: data['deliveryType'] ?? '',
      deliveryPerson: data['deliveryPerson'] ?? '',
      deliveryPhone: data['deliveryPhone'] ?? '',
      remarks: data['remarks'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: toDateTimeFn(data['createdAt']),
      updatedBy: data['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(data['updatedAt']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'status': status,
    'storeNumber': storeNumber,
    'orderNumber': orderNumber,
    'barcode': barcode,
    'deliveryType': deliveryType,
    'deliveryPerson': deliveryPerson,
    'deliveryPhone': deliveryPhone,
    'remarks': remarks,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt,
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

  bool get isEmpty => id.isEmpty && orderNumber.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Check Delivery Status [isPending]
  bool get isPending => status == 'pending';

  /// Check Delivery Status [isDispatched]
  bool get isDispatched => status == 'shipped / dispatched';

  /// Check Delivery Status [isDelivered]
  bool get isDelivered => status == 'delivered';

  /// Check Delivery Status [isCancelled]
  bool get isCancelled => status == 'cancelled';

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  /// Current / Today's Products/Stocks
  bool get isToday {
    var dt = createdAt.toDateTime;

    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  /// [findDeliveryById]
  static Iterable<Delivery> findDeliveryById(
    List<Delivery> deliveries,
    String id,
  ) => deliveries.where((d) => d.id == id);

  /// [filterDeliveriesByDate]
  static List<Delivery> filterDeliveriesByDate(
    List<Delivery> deliveries, {
    bool isSameDay = false,
  }) => deliveries.where((d) => isSameDay ? d.isToday : !d.isToday).toList();

  /// copyWith method
  Delivery copyWith({
    String? id,
    String? status,
    String? storeNumber,
    String? orderNumber,
    String? barcode,
    String? deliveryType,
    String? deliveryPerson,
    String? deliveryPhone,
    String? remarks,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return Delivery(
      id: id ?? this.id,
      status: status ?? this.status,
      storeNumber: storeNumber ?? this.storeNumber,
      orderNumber: orderNumber ?? this.orderNumber,
      barcode: barcode ?? this.barcode,
      deliveryType: deliveryType ?? this.deliveryType,
      deliveryPerson: deliveryPerson ?? this.deliveryPerson,
      deliveryPhone: deliveryPhone ?? this.deliveryPhone,
      remarks: remarks ?? this.remarks,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    status,
    storeNumber,
    orderNumber,
    barcode,
    deliveryType,
    deliveryPerson,
    deliveryPhone,
    remarks,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  /// ToList for DELIVERY [itemAsList]
  List<String> itemAsList() => [
    id,
    storeNumber,
    orderNumber,
    status.toTitle,
    deliveryType.toTitle,
    deliveryPerson.toTitle,
    deliveryPhone,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataHeader => const [
    'ID',
    'Store #',
    'Order No.',
    'Status',
    'Delivery Type',
    'Delivery Staff',
    'Delivery Phone',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}
