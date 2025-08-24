import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

var _today = DateTime.now(); /*.millisecondsSinceEpoch.toString()*/

/// @TODO request for quotation fields
// * Terms & conditions
// * List of invited suppliers
// * Attachments (drawings/specs)
// * Responses (linked or stored in sub-table)

// Calculated net price from the line items
/*double get netPrice {
    double total = 0;
    for (var item in lineItems) {
      total += item.unitPrice * item.quantity;
    }
    return total - (total * discountPercent / 100) + (total * taxPercent / 100);
  }*/

class RequestForQuotation extends Equatable {
  final String id; // Firestore will assign a unique ID (documentId)
  final String storeNumber;
  final String rfqNumber;
  final String supplierId;
  final List<RFQLineItem> lineItems; // A list of items in the RFQ

  final String status;

  // new
  final String title;
  final String currency;
  final String department;
  final String validityDate;
  final String? deliveryAddress;

  final String? notes;

  final double taxPercent;

  final DateTime? deadline;
  final DateTime? deliveryDate;

  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  RequestForQuotation({
    this.id = '',
    required this.title,
    this.rfqNumber = '',
    required this.storeNumber,
    required this.supplierId,
    required this.status,
    required this.lineItems,
    this.department = '',
    this.notes,
    this.validityDate = '',
    this.currency = 'GHC',
    this.deliveryAddress = '',
    this.taxPercent = 0.0,
    DateTime? deadline,
    DateTime? deliveryDate,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : deadline = deadline ?? _today,
       deliveryDate = deliveryDate ?? _today,
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [RequestForQuotation.fromMap]
  factory RequestForQuotation.fromMap(Map<String, dynamic> data, String docId) {
    return RequestForQuotation(
      id: docId,
      title: data['title'] ?? '',
      department: data['department'] ?? '',
      storeNumber: data['storeNumber'] ?? '',
      rfqNumber: data['rfqNumber'] ?? '',
      supplierId: data['supplierId'] ?? '',
      status: data['status'] ?? '',
      lineItems:
          (data['lineItems'] as List<dynamic>?)
              ?.map((i) => RFQLineItem.fromMap(i.cast<String, dynamic>()))
              .toList() ??
          [],
      notes: data['notes'] ?? '',
      taxPercent: data['taxPercent'] ?? 0.0,
      deadline: toDateTimeFn(data['deadline']),
      deliveryDate: toDateTimeFn(data['deliveryDate']),
      validityDate: data['validityDate'] ?? '',
      currency: data['currency'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: toDateTimeFn(data['createdAt']),
      updatedBy: data['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(data['updatedAt']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'title': title,
    'department': department,
    'storeNumber': storeNumber,
    'rfqNumber': rfqNumber,
    'supplierId': supplierId,
    'lineItems': lineItems.map((item) => item.toMap()).toList(),
    'status': status,
    'notes': notes,
    'taxPercent': taxPercent,
    'deadline': deadline,
    'deliveryDate': deliveryDate,
    'validityDate': validityDate,
    'currency': currency,
    'deliveryAddress': deliveryAddress,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt,
  };

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['deadline'] = deadline?.toISOString;
    newMap['deliveryDate'] = deliveryDate?.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['deadline'] = deadline?.millisecondsSinceEpoch;
    newMap['deliveryDate'] = deliveryDate?.millisecondsSinceEpoch;
    newMap['createdAt'] = createdAt.millisecondsSinceEpoch;
    newMap['updatedAt'] = updatedAt.millisecondsSinceEpoch;

    return {'id': id, 'data': newMap};
  }

  // --- Calculations ---

  double get subTotal =>
      lineItems.fold(0.0, (sum, item) => sum + item.subTotal);

  double get discountAmt =>
      lineItems.fold(0.0, (sum, item) => sum + item.discountAmt);

  double get taxAmt =>
      lineItems.fold(0.0, (sum, item) => sum + item.taxAmt(taxPercent));

  double get netTotal => subTotal - discountAmt + taxAmt;

  // --- Utilities ---
  bool get isEmpty => lineItems.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// approved POs [isApproved]
  bool get isAwarded => status == 'awarded';

  /// Formatted to Date Only in String [getDeliveryDate]
  String get getDeliveryDate => deliveryDate.dateOnly;

  /// Formatted to Date Only in String [getDeliveryDate]
  String get getDeadlineDate => deadline.dateOnly;

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
      storeNumber.contains(filter) ||
      rfqNumber.contains(filter) ||
      department.contains(filter) ||
      title.contains(filter) ||
      status.contains(filter) ||
      supplierId.contains(filter) ||
      (notes ?? '').contains(filter) ||
      validityDate.contains(filter) ||
      currency.contains(filter) ||
      (deliveryAddress ?? '').contains(filter) ||
      taxPercent.toString().contains(filter) ||
      getDeadlineDate.contains(filter) ||
      getDeliveryDate.contains(filter) ||
      lineItems.map((e) => e.filterByAny(filter)).toList().contains(true);

  /// [findRFQById]
  static Iterable<RequestForQuotation> findRFQById(
    List<RequestForQuotation> quotes,
    String quoteId,
  ) => quotes.where((quote) => quote.id == quoteId);

  /// [filterRFQByDate]
  static List<RequestForQuotation> filterRFQByDate(
    List<RequestForQuotation> quotes, {
    bool isSameDay = true,
  }) => quotes
      .where(
        (quote) =>
            !quote.isAwarded && (isSameDay ? quote.isToday : !quote.isToday),
      )
      .toList();

  /// [filterAwardedRFQ]
  static List<RequestForQuotation> filterAwardedRFQ(
    List<RequestForQuotation> quotes,
  ) => quotes.where((quote) => quote.isAwarded).toList();

  @override
  String toString() => 'RFQ: $rfqNumber - $supplierId';

  /// copyWith method
  RequestForQuotation copyWith({
    String? id,
    String? title,
    String? department,
    String? storeNumber,
    String? rfqNumber,
    String? supplierId,
    List<RFQLineItem>? lineItems,
    int? quantity,
    String? status,
    String? notes,
    double? taxPercent,
    DateTime? deadline,
    DateTime? deliveryDate,
    String? validityDate,
    String? currency,
    String? deliveryAddress,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return RequestForQuotation(
      id: id ?? this.id,
      title: title ?? this.title,
      department: department ?? this.department,
      storeNumber: storeNumber ?? this.storeNumber,
      rfqNumber: rfqNumber ?? this.rfqNumber,
      supplierId: supplierId ?? this.supplierId,
      lineItems: lineItems ?? this.lineItems,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      deadline: deadline ?? this.deadline,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      taxPercent: taxPercent ?? this.taxPercent,
      validityDate: validityDate ?? this.validityDate,
      currency: currency ?? this.currency,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    storeNumber,
    rfqNumber,
    supplierId,
    department,
    status,
    lineItems.map((e) => e.props).toList(),
    notes,
    deadline ?? '',
    deliveryDate ?? '',
    taxPercent,
    validityDate,
    currency,
    deliveryAddress,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  /// ToList for RequestPriceQuotation [itemAsList]
  List<String> get itemAsList => [
    id,
    storeNumber,
    rfqNumber,
    status.toTitleCase,
    // lineItems.map((e) => e.itemAsList).toList().join(', '),
    '$taxPercent% = $currency$taxAmt',
    getDeadlineDate,
    getDeliveryDate,
    createdBy.toTitleCase,
    getCreatedAt,
    updatedBy.toTitleCase,
    getUpdatedAt,
  ];

  static List<String> get dataTableHeader => const [
    'ID',
    'Store Number',
    'RFQ Number',
    'Status',
    // 'lineItems',
    'Tax',
    'Quotation Deadline',
    'Delivery Date',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}

/// RFQ Line Items
class RFQLineItem extends Equatable {
  final String itemName;
  final double unitPrice;
  final int quantity;
  final double discountPercent;

  const RFQLineItem({
    required this.itemName,
    required this.quantity,
    this.unitPrice = 0.0,
    this.discountPercent = 0.0,
  });

  double get netPrice => unitPrice * quantity;

  double get subTotal => quantity * unitPrice;

  double get discountAmt => (discountPercent / 100) * netPrice;

  double taxAmt(double taxPercent) =>
      (taxPercent / 100) * (subTotal - discountAmt);

  bool get isEmpty => itemName.isEmpty;

  bool get isNotEmpty => !isEmpty;

  factory RFQLineItem.fromMap(Map<String, dynamic> data) {
    return RFQLineItem(
      itemName: data['itemName'] ?? '',
      quantity: int.tryParse('${data['quantity']}') ?? 0,
      unitPrice: double.tryParse('${data['unitPrice']}') ?? 0.0,
      discountPercent: double.tryParse('${data['discountPercent']}') ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
    'itemName': itemName,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'discountPercent': discountPercent,
  };

  bool filterByAny(String filter) =>
      itemName.contains(filter) ||
      quantity.toString().contains(filter) ||
      discountPercent.toString().contains(filter) ||
      unitPrice.toString().contains(filter) ||
      netPrice.toString().contains(filter);

  RFQLineItem copyWith({
    String? itemName,
    double? unitPrice,
    int? quantity,
    double? discountPercent,
  }) {
    return RFQLineItem(
      itemName: itemName ?? this.itemName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }

  @override
  List<Object?> get props => [itemName, unitPrice, quantity, discountPercent];

  static List<String> get dataTableHeader => const [
    'Item Name',
    'Unit Price',
    'Quantity',
    'Discount',
    'Net Price',
  ];

  /// ToList for RequestPriceQuotation [itemAsList]
  List<String> get itemAsList => [
    itemName.toTitleCase,
    '$ghanaCedis$unitPrice',
    '$quantity',
    '$discountPercent% = $ghanaCedis$discountAmt',
    '$ghanaCedis$netPrice',
  ];
}
