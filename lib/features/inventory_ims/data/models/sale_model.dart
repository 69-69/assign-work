import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

var _today = DateTime.now(); /*.millisecondsSinceEpoch.toString()*/

class Sale extends Equatable {
  final String id; // Firestore will assign a unique ID (documentId)
  final String orderNumber;
  final String itemId;
  final String customerId;
  final String invoiceNumber;
  final int quantity;
  final double unitPrice;
  final double deliveryAmount;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double totalAmount;
  final double amountPaid;
  final double outstandingBalance;
  final double revenue;
  final double profit;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String? notes;
  final String storeNumber;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  Sale({
    this.id = '',
    required this.orderNumber,
    required this.itemId,
    required this.customerId,
    this.invoiceNumber = '',
    required this.quantity,
    required this.unitPrice,
    this.deliveryAmount = 0.0,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.taxPercent = 0.0,
    this.taxAmount = 0.0,
    this.totalAmount = 0.0,
    this.amountPaid = 0.0,
    this.outstandingBalance = 0.0,
    this.revenue = 0.0,
    this.profit = 0.0,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.storeNumber = '',
    this.notes,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [Sale.fromMap]
  factory Sale.fromMap(Map<String, dynamic> data, String documentId) {
    var (double arrears, double rev) = calculateArrearsAndRevenue(data);

    return Sale(
      id: documentId,
      orderNumber: data['orderNumber'] ?? '',
      itemId: data['itemId'] ?? '',
      customerId: data['customerId'] ?? '',
      invoiceNumber:
          data['invoiceNumber'] ??
          '${data['orderNumber']}'.convertOrderNumberTo,
      quantity: data['quantity'] ?? 0,
      unitPrice: data['unitPrice'] ?? 0.0,
      deliveryAmount: data['deliveryAmount'] ?? 0.0,
      taxPercent: data['taxPercent'] ?? 0.0,
      taxAmount: data['taxAmount'] ?? 0.0,
      discountPercent: data['discountPercent'] ?? 0.0,
      discountAmount: data['discountAmount'] ?? 0.0,
      totalAmount: data['totalAmount'] ?? 0.0,
      amountPaid: data['amountPaid'] ?? 0.0,
      outstandingBalance: data['outstandingBalance'] ?? arrears,
      revenue: data['revenue'] ?? rev,
      profit: data['profit'] ?? 0.0,
      paymentMethod: data['paymentMethod'] ?? '',
      paymentStatus: data['paymentStatus'] ?? '',
      status: data['status'] ?? '',
      storeNumber: data['storeNumber'] ?? '',
      notes: data['notes'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: toDateTimeFn(data['createdAt']),
      updatedBy: data['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(data['updatedAt']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'orderNumber': orderNumber,
    'itemId': itemId,
    'customerId': customerId,
    'invoiceNumber': invoiceNumber,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'deliveryAmount': deliveryAmount,
    'taxPercent': taxPercent,
    'taxAmount': taxAmount,
    'storeNumber': storeNumber,
    'notes': notes,
    'discountPercent': discountPercent,
    'discountAmount': discountAmount,
    'totalAmount': totalAmount,
    'amountPaid': amountPaid,
    'outstandingBalance': outstandingBalance,
    'revenue': revenue,
    'profit': profit,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'status': status,
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
    newMap['createdAt'] = createdAt.millisecondsSinceEpoch;
    newMap['updatedAt'] = updatedAt.millisecondsSinceEpoch;

    return {'id': id, 'data': newMap};
  }

  bool get isEmpty => id.isEmpty && itemId.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Calculate Revenue [getRevenue]
  double get getRevenue => quantity * unitPrice;

  /// Calculate outStanding Balance [getOutStandingBalance]
  double get getOutStandingBalance => totalAmount - amountPaid;

  double get getSubTotal => quantity * unitPrice;

  // NetPrice: After discountAmt is deducted & other charges are added from 'subTotal'
  double get getNetPrice => getSubTotal - getDiscountAmount;

  double get getDiscountAmount => (discountPercent / 100) * getSubTotal;

  double get getTaxAmount => (taxPercent / 100) * getNetPrice;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  /// Current / Today's Products/Stocks [isToday]
  bool get isToday {
    var dt = createdAt.toDateTime;

    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  static (double, double) calculateArrearsAndRevenue(Map<String, dynamic> d) =>
      switch (d) {
        {
          'totalAmount': double totalAmount,
          'unitPrice': double unitPrice,
          'amountPaid': double amountPaid,
        } =>
          (totalAmount - amountPaid, totalAmount * unitPrice),
        _ => (0, 0),
      };

  /// Calculate Profit [calculateProfit]
  /// Profit = Revenue − Cost or Profit = (unitPrice - costPrice) * quantity
  double calculateProfit(double costPrice) =>
      costPrice == 0.0 ? 0.0 : (unitPrice - costPrice) * quantity.toDouble();

  /// Find a Specific sale by id [findSaleById]
  static Iterable<Sale> findSaleById(
    List<Sale> sales, {
    required String saleId,
  }) => sales.where((sale) => sale.id == saleId);

  /// Filter sales [filterSalesByDate]
  static List<Sale> filterSalesByDate(
    List<Sale> sales, {
    bool isSameDay = true,
  }) =>
      sales.where((sale) => isSameDay ? sale.isToday : !sale.isToday).toList();

  /// copyWith method
  Sale copyWith({
    String? id,
    String? storeNumber,
    String? orderNumber,
    String? itemId,
    String? customerId,
    String? invoiceNumber,
    int? quantity,
    double? unitPrice,
    double? deliveryAmount,
    double? discountPercent,
    double? discountAmount,
    double? taxPercent,
    double? taxAmount,
    double? totalAmount,
    double? amountPaid,
    double? outstandingBalance,
    double? revenue,
    double? profit,
    String? notes,
    String? paymentMethod,
    String? paymentStatus,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return Sale(
      id: id ?? this.id,
      storeNumber: storeNumber ?? this.storeNumber,
      orderNumber: orderNumber ?? this.orderNumber,
      itemId: itemId ?? this.itemId,
      customerId: customerId ?? this.customerId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      deliveryAmount: deliveryAmount ?? this.deliveryAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      revenue: revenue ?? this.revenue,
      profit: profit ?? this.profit,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      notes: notes ?? this.notes,
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
    orderNumber,
    itemId,
    customerId,
    invoiceNumber,
    quantity,
    unitPrice,
    status,
    deliveryAmount,
    taxPercent,
    taxAmount,
    discountPercent,
    discountAmount,
    totalAmount,
    amountPaid,
    outstandingBalance,
    revenue,
    profit,
    paymentMethod,
    notes,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  /// Check if any required fields are missing or empty [isDataComplete]
  bool isDataComplete() {
    // Check for non-empty string fields
    bool areStringFieldsValid = [
      storeNumber,
      orderNumber,
      itemId,
      customerId,
      paymentMethod,
      paymentStatus,
      status,
      createdBy,
    ].every((field) => field.isNotEmpty);

    // Check for numerical fields
    bool areNumericFieldsValid =
        quantity > 0 && unitPrice > 0 && totalAmount > 0;

    // Check for complete data
    return areStringFieldsValid && areNumericFieldsValid;
  }

  /// ToList for SALES [itemAsList]
  List<String> itemAsList() => [
    id,
    storeNumber,
    itemId.toUpperAll,
    orderNumber,
    invoiceNumber,
    customerId,
    status.toTitle,
    '$quantity',
    '$ghanaCedis${unitPrice.toCurrency}',
    '$ghanaCedis${deliveryAmount.toCurrency}',
    '$discountPercent% = $ghanaCedis${getDiscountAmount.toCurrency}',
    '$taxPercent% = $ghanaCedis${getTaxAmount.toCurrency}',
    '$ghanaCedis${totalAmount.toCurrency}',
    '$ghanaCedis${amountPaid.toCurrency}',
    '$ghanaCedis${getOutStandingBalance.toCurrency}',
    '$ghanaCedis${getRevenue.toCurrency}',
    '$ghanaCedis${profit.toCurrency}',
    paymentMethod.toTitle,
    paymentStatus.toTitle,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataTableHeader => const [
    'ID',
    'Store Number',
    'Product ID',
    'Order Number',
    'Invoice Number',
    'Customer ID',
    'Status',
    'Quantity',
    'Unit Price',
    'Delivery fee',
    'Discount',
    'Tax',
    'Total Amount',
    'Amount Paid',
    'OutStanding Balance',
    'Revenue',
    'Gross Profit',
    'Payment Terms',
    'Payment Status',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}
