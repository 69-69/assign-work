import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/tax_methods_enum.dart';
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
  final String id;
  final String storeNumber;
  final String rfqNumber;
  final String supplierId;
  final List<RFQLineItem> lineItems;
  final String status;
  final TaxMethodToApply taxMethod;
  final List<String> taxCodes;

  final String title;
  final String currency;
  final String department;
  final String paymentTerm;
  final String validityDate;
  final String? deliveryAddress;
  final String? notes;
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
    this.taxMethod = TaxMethodToApply.unknown,
    this.taxCodes = const [],
    required this.lineItems,
    this.paymentTerm = '',
    required this.department,
    this.notes,
    this.validityDate = '',
    this.currency = 'GHC',
    this.deliveryAddress = '',
    DateTime? deadline,
    DateTime? deliveryDate,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : deadline = deadline ?? _today,
       deliveryDate = deliveryDate ?? _today,
       createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

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
              ?.map((i) => RFQLineItem.fromMap(Map<String, dynamic>.from(i)))
              .toList() ??
          [],
      notes: data['notes'],
      taxMethod: getTaxMethodByString(
        data['taxMethod'] ?? TaxMethodToApply.perLineTax,
      ),
      paymentTerm: data['paymentTerm'] ?? '',
      taxCodes: List<String>.from(data['taxCodes'] ?? []),
      deadline: toDateTimeFn(data['deadline']),
      deliveryDate: toDateTimeFn(data['deliveryDate']),
      validityDate: data['validityDate'] ?? '',
      currency: data['currency'] ?? '',
      deliveryAddress: data['deliveryAddress'],
      createdBy: data['createdBy'] ?? '',
      createdAt: toDateTimeFn(data['createdAt'] ?? '$_today'),
      updatedBy: data['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(data['updatedAt'] ?? '$_today'),
    );
  }

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
    'taxCodes': taxCodes,
    'taxMethod': taxMethod.label,
    'paymentTerm': paymentTerm,
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

  Map<String, dynamic> toMap() {
    final newMap = _mapTemp();
    newMap['deadline'] = deadline?.toISOString;
    newMap['deliveryDate'] = deliveryDate?.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;
    return newMap;
  }

  Map<String, dynamic> toCache() {
    final newMap = _mapTemp();
    newMap['deadline'] = deadline?.millisecondsSinceEpoch;
    newMap['deliveryDate'] = deliveryDate?.millisecondsSinceEpoch;
    newMap['createdAt'] = createdAt.millisecondsSinceEpoch;
    newMap['updatedAt'] = updatedAt.millisecondsSinceEpoch;
    return {'id': id, 'data': newMap};
  }

  double get subTotal =>
      lineItems.fold(0.0, (sum, item) => sum + item.subTotal);

  double get discountAmt =>
      lineItems.fold(0.0, (sum, item) => sum + item.discountAmt);

  double get taxAmt {
    final baseAmount = subTotal - discountAmt;

    if (taxMethod.isPerLineTax) {
      return lineItems.fold(0.0, (sum, item) => sum + item.taxAmt);
    }

    // TODO: Implement logic to resolve taxCodes into rates.
    // For now, return 0.
    return 0.0;
  }

  double get netTotal => subTotal - discountAmt + taxAmt;

  bool get isEmpty => lineItems.isEmpty;
  bool get isNotEmpty => lineItems.isNotEmpty;
  bool get isAwarded => status == 'awarded';

  String get getDeliveryDate => deliveryDate.dateOnly;
  String get getValidityDate =>
      (int.tryParse(validityDate.split(' ').first)?.toDate).dateOnly;
  String get getDeadlineDate => deadline.dateOnly;
  String get getCreatedAt => createdAt.toStandardDT;
  String get getUpdatedAt => updatedAt.toStandardDT;

  bool get isToday {
    final dt = createdAt.toDateTime;
    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  bool filterByAny(String filter) =>
      storeNumber.contains(filter) ||
      rfqNumber.contains(filter) ||
      title.contains(filter) ||
      status.contains(filter) ||
      supplierId.contains(filter) ||
      department.contains(filter) ||
      currency.contains(filter) ||
      paymentTerm.contains(filter) ||
      (notes ?? '').contains(filter) ||
      validityDate.contains(filter) ||
      (deliveryAddress ?? '').contains(filter) ||
      taxCodes.any((e) => e.contains(filter)) ||
      getDeadlineDate.contains(filter) ||
      getDeliveryDate.contains(filter) ||
      lineItems.any((e) => e.filterByAny(filter));

  static Iterable<RequestForQuotation> findRFQById(
    List<RequestForQuotation> quotes,
    String quoteId,
  ) => quotes.where((quote) => quote.id == quoteId);

  static List<RequestForQuotation> filterRFQByDate(
    List<RequestForQuotation> quotes, {
    bool isSameDay = true,
  }) => quotes
      .where((q) => !q.isAwarded && (isSameDay ? q.isToday : !q.isToday))
      .toList();

  static List<RequestForQuotation> filterAwardedRFQ(
    List<RequestForQuotation> quotes,
  ) => quotes.where((q) => q.isAwarded).toList();

  @override
  String toString() => 'RFQ: $rfqNumber - $supplierId';

  RequestForQuotation copyWith({
    String? id,
    String? title,
    String? department,
    String? storeNumber,
    String? rfqNumber,
    String? supplierId,
    List<RFQLineItem>? lineItems,
    String? status,
    String? notes,
    TaxMethodToApply? taxMethod,
    List<String>? taxCodes,
    DateTime? deadline,
    DateTime? deliveryDate,
    String? validityDate,
    String? currency,
    String? paymentTerm,
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
      paymentTerm: paymentTerm ?? this.paymentTerm,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      deadline: deadline ?? this.deadline,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      taxCodes: taxCodes ?? this.taxCodes,
      taxMethod: taxMethod ?? this.taxMethod,
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
    paymentTerm,
    status,
    lineItems,
    notes,
    deadline,
    deliveryDate,
    taxMethod,
    taxCodes,
    taxMethod,
    validityDate,
    currency,
    deliveryAddress,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  List<String> get itemAsList => [
    id,
    storeNumber,
    rfqNumber,
    status.toTitleCase,
    department.toTitleCase,
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
    'Department',
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
  final List<String> taxCodes;

  const RFQLineItem({
    required this.itemName,
    required this.quantity,
    this.taxCodes = const [],
    this.unitPrice = 0.0,
    this.discountPercent = 0.0,
  });

  // get list of tax codes
  List<String> get taxCodesList =>
      List<String>.from(taxCodes).whereType<String>().toList();
  double get netPrice => unitPrice * quantity;
  double get subTotal => quantity * unitPrice;
  double get discountAmt => (discountPercent / 100) * netPrice;

  double get taxAmt {
    // TODO: Resolve taxCodes to rates.
    return 0.0;
  }

  bool get isEmpty => itemName.isEmpty;
  bool get isNotEmpty => !isEmpty;

  factory RFQLineItem.fromMap(Map<String, dynamic> data) {
    return RFQLineItem(
      itemName: data['itemName'] ?? '',
      quantity: int.tryParse('${data['quantity']}') ?? 0,
      unitPrice: double.tryParse('${data['unitPrice']}') ?? 0.0,
      discountPercent: double.tryParse('${data['discountPercent']}') ?? 0.0,
      taxCodes: List<String>.from(
        data['taxCodes'] ?? [],
      ).whereType<String>().toList(),

      /*taxCodes: (data['taxCodes'] as List?)
          ?.map((e) {
        if (e is Tax) return e.id; // or e.code if you prefer codes
        if (e is String) return e;
        return null;
      })
          .whereType<String>()
          .toList() ?? [],*/
    );
  }

  Map<String, dynamic> toMap() => {
    'itemName': itemName,
    'taxCodes': taxCodes,
    'quantity': quantity,
    'unitPrice': unitPrice,
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
    List<String>? taxCodes,
    double? discountPercent,
  }) {
    return RFQLineItem(
      itemName: itemName ?? this.itemName,
      taxCodes: taxCodes ?? this.taxCodes,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }

  @override
  List<Object?> get props => [
    itemName,
    taxCodes,
    unitPrice,
    quantity,
    discountPercent,
  ];

  static List<String> get dataTableHeader => const [
    'Item Name',
    'Unit Price',
    'Quantity',
    'Discount',
    'Net Price',
  ];

  List<String> get itemAsList => [
    itemName.toTitleCase,
    '$ghanaCedis$unitPrice',
    '$quantity',
    '$discountPercent% = $ghanaCedis$discountAmt',
    '$ghanaCedis$netPrice',
  ];
}
