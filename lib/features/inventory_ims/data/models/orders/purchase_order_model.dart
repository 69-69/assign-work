import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

class PurchaseOrder extends Equatable {
  static get _today => DateTime.now();

  final String id; // Firestore will assign a unique ID (documentId)
  final String storeNumber; // FK CompanyStore.storeNumber
  final String poNumber;
  final String supplierId;
  // final List<POLineItem> lineItems; // A list of items in the RFQ

  final String itemName;
  final String currency;

  final double unitPrice;
  final int quantity;

  final String status;

  /// [payTerms] When the payment is due and if any discounts apply
  final String payTerms;

  /// [payMethod] How the payment is made (the financial instrument or channel)
  final String payMethod;

  final String? remarks;

  final double taxPercent;
  final double discountPercent;

  final double subTotal;

  final DateTime? deliveryDate;
  final double totalAmount;

  final String orderType;

  final String approvedBy;

  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  /// @TODO purchase order fields
  // Taxes
  // Attachments (e.g., specifications)

  PurchaseOrder({
    this.id = '',
    this.poNumber = '',
    required this.currency,
    required this.storeNumber,
    required this.supplierId,
    required this.status,
    required this.quantity,
    required this.itemName,
    this.orderType = 'purchase order',
    required this.unitPrice,
    required this.payTerms,
    required this.payMethod,
    this.remarks,
    this.subTotal = 0.0,
    this.approvedBy = '',
    this.discountPercent = 0.0,
    this.taxPercent = 0.0,
    required this.totalAmount,
    DateTime? deliveryDate,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : deliveryDate = deliveryDate ?? _today,
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [PurchaseOrder.fromMap]
  factory PurchaseOrder.fromMap(Map<String, dynamic> data, String documentId) {
    return PurchaseOrder(
      id: documentId,
      storeNumber: data['storeNumber'] ?? '',
      poNumber: data['poNumber'] ?? '',
      supplierId: data['supplierId'] ?? '',
      status: data['status'] ?? '',
      itemName: data['itemName'] ?? '',
      currency: data['currency'] ?? '',
      orderType: data['orderType'] ?? 'purchase order',
      quantity: '${data['quantity']}'.asInt,
      unitPrice: '${data['unitPrice']}'.asDouble,
      payTerms: data['payTerms'] ?? '',
      payMethod: data['payMethod'] ?? '',
      remarks: data['remarks'] ?? '',
      subTotal: '${data['subTotal']}'.asDouble,
      taxPercent: '${data['taxPercent']}'.asDouble,
      discountPercent: '${data['discountPercent']}'.asDouble,
      totalAmount: '${data['totalAmount']}'.asDouble,
      approvedBy: data['approvedBy'] ?? '',
      deliveryDate: toDateTimeFn(data['deliveryDate']),
      createdBy: data['createdBy'] ?? '',
      createdAt: toDateTimeFn(data['createdAt']),
      updatedBy: data['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(data['updatedAt']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'storeNumber': storeNumber,
    'poNumber': poNumber,
    'supplierId': supplierId,
    'itemName': itemName,
    'currency': currency,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'status': status,
    'orderType': orderType,
    'payTerms': payTerms,
    'payMethod': payMethod,
    'remarks': remarks,
    'subTotal': subTotal,
    'approvedBy': approvedBy,
    'taxPercent': taxPercent,
    'discountPercent': discountPercent,
    'totalAmount': totalAmount,
    'deliveryDate': deliveryDate,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt,
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

  bool get isEmpty => itemName.isEmpty;

  bool get isNotEmpty => !isEmpty;

  // NetPrice: After discountAmt is deducted & other charges are added from 'subTotal'
  double get netPrice => subTotal - discountAmt;

  double get discountAmt => (discountPercent / 100) * subTotal;

  double get taxAmt => (taxPercent / 100) * netPrice;

  /// approved POs [isApproved]
  bool get isApproved => status == 'approved' && approvedBy.isNotEmpty;

  /// Formatted to Date Only in String [getDeliveryDate]
  String get getDeliveryDate => deliveryDate.dateOnly;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Date Only in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  /// Current / Today's Products/Stocks
  bool get isToday {
    var dt = createdAt.toDateTime;

    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  /// Filter
  bool filterByAny(String filter) =>
      poNumber.contains(filter) ||
      storeNumber.contains(filter) ||
      itemName.contains(filter) ||
      status.contains(filter) ||
      supplierId.contains(filter) ||
      currency.contains(filter) ||
      payTerms.contains(filter);

  /// [findPurchaseOrderById]
  static Iterable<PurchaseOrder> findPurchaseOrderById(
    List<PurchaseOrder> po,
    String poId,
  ) => po.where((order) => order.id == poId);

  /// [filterPurchaseOrderByDate]
  static List<PurchaseOrder> filterPurchaseOrderByDate(
    List<PurchaseOrder> po, {
    bool isSameDay = true,
  }) => po
      .where(
        (order) =>
            !order.isApproved && (isSameDay ? order.isToday : !order.isToday),
      )
      .toList();

  /// [filterApprovedPOs]
  static List<PurchaseOrder> filterApprovedPOs(List<PurchaseOrder> po) =>
      po.where((order) => order.isApproved).toList();

  @override
  String toString() =>
      'PO: $poNumber - $itemName @ ${isToday ? 'Today' : 'Past'}';

  /// copyWith method
  PurchaseOrder copyWith({
    String? id,
    String? storeNumber,
    String? poNumber,
    String? supplierId,
    String? itemName,
    String? currency,
    String? orderType,
    double? unitPrice,
    int? quantity,
    String? status,
    String? payTerms,
    String? payMethod,
    String? remarks,
    double? subTotal,
    String? approvedBy,
    double? taxPercent,
    double? discountPercent,
    double? totalAmount,
    DateTime? deliveryDate,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      storeNumber: storeNumber ?? this.storeNumber,
      poNumber: poNumber ?? this.poNumber,
      supplierId: supplierId ?? this.supplierId,
      itemName: itemName ?? this.itemName,
      currency: currency ?? this.currency,
      unitPrice: unitPrice ?? this.unitPrice,
      orderType: orderType ?? this.orderType,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      payTerms: payTerms ?? this.payTerms,
      payMethod: payMethod ?? this.payMethod,
      remarks: remarks ?? this.remarks,
      subTotal: subTotal ?? this.subTotal,
      approvedBy: approvedBy ?? this.approvedBy,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      discountPercent: discountPercent ?? this.discountPercent,
      taxPercent: taxPercent ?? this.taxPercent,
      totalAmount: totalAmount ?? this.totalAmount,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    storeNumber,
    poNumber,
    supplierId,
    status,
    itemName,
    currency,
    quantity,
    orderType,
    unitPrice,
    payTerms,
    payMethod,
    remarks,
    subTotal,
    deliveryDate ?? '',
    taxPercent,
    discountPercent,
    totalAmount,
    approvedBy,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  /// ToList for PurchaseOrder [itemAsList]
  List<String> itemAsList({int? start, int? end}) {
    var list = [
      id,
      storeNumber,
      poNumber,
      supplierId,
      orderType.toTitle,
      status.toTitle,
      currency.toTitle,
      payTerms.toTitle,
      payMethod.toTitle,
      itemName.toTitle,
      '$ghanaCedis$unitPrice',
      '$quantity',
      '$ghanaCedis$subTotal',
      '$discountPercent% = $ghanaCedis$discountAmt',
      '$taxPercent% = $ghanaCedis$taxAmt',
      '$ghanaCedis$totalAmount',
      getDeliveryDate,
      approvedBy.toTitle,
      createdBy.toTitle,
      getCreatedAt,
      updatedBy.toTitle,
      getUpdatedAt,
    ];

    /// Removes a range of elements from the list
    if (start != null && end != null) {
      list.removeRange(start, end);
    }

    return list;
  }

  static List<String> get dataTableHeader => const [
    'ID',
    'Store Number',
    'PO Number',
    'Supplier ID',
    'Order Type',
    'Status',
    'Currency',
    'Payment Terms',
    'Payment Method',
    'Item Name',
    'Unit Price',
    'Quantity',
    'SubTotal',
    'Discount',
    'Tax',
    'Total Amount',
    'Delivery',
    'Approved By',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}
