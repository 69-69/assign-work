import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

// POSOrder Model class
class POSOrder extends Equatable {
  static get _today => DateTime.now();

  final String id; // Firestore will assign a unique ID (documentId)
  final String storeNumber; // FK CompanyStore.storeNumber
  final String orderNumber;
  final String customerId;
  final String itemId;
  final String itemName;
  final String barcode;
  final int quantity;
  final double unitPrice;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double totalAmount;
  final String payMethod;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  POSOrder({
    this.id = '', // Firestore will assign a unique ID (documentId)
    required this.storeNumber,
    required this.orderNumber,
    required this.itemId,
    required this.itemName,
    this.customerId = '',
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0.0,
    this.taxPercent = 0.0,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.barcode = '',
    required this.totalAmount,
    required this.payMethod,
    required this.status,
    this.createdBy = '',
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  factory POSOrder.fromMap(Map<String, dynamic> map, String documentId) {
    return POSOrder(
      id: documentId,
      storeNumber: map['storeNumber'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      customerId: map['customerId'] ?? '',
      quantity: '${map['quantity']}'.asInt,
      unitPrice: '${map['unitPrice']}'.asDouble,
      barcode: map['barcode'] ?? '',
      discountPercent: '${map['discountPercent']}'.asDouble,
      taxPercent: '${map['taxPercent']}'.asDouble,
      discountAmount: '${map['discountAmount']}'.asDouble,
      taxAmount: '${map['taxAmount']}'.asDouble,
      totalAmount: '${map['totalAmount']}'.asDouble,
      payMethod: map['payMethod'] ?? '',
      status: map['status'] ?? '',
      createdBy: map['createdBy'],
      createdAt: toDateTimeFn(map['createdAt']),
      updatedBy: map['updatedBy'],
      updatedAt: toDateTimeFn(map['updatedAt']),
    );
  }

  // map template
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'storeNumber': storeNumber,
    'orderNumber': orderNumber,
    'itemId': itemId,
    'itemName': itemName,
    'customerId': customerId,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'barcode': barcode,
    'discountPercent': discountPercent,
    'taxPercent': taxPercent,
    'totalAmount': totalAmount,
    'discountAmount': discountAmount,
    'taxAmount': taxAmount,
    'payMethod': payMethod,
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

  /// Convert UserModel to toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['createdAt'] = createdAt.toMilliseconds;
    newMap['updatedAt'] = updatedAt.toMilliseconds;

    return {'id': id, 'data': newMap};
  }

  bool get isEmpty => id.isEmpty && itemId.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => createdAt.toStandardDT;

  double get getSubTotal => quantity * unitPrice;

  // double get getDiscountAmount => (discountPercent / 100) * getSubTotal;

  // double get getTaxAmount => (taxPercent / 100) * getNetPrice;

  // NetPrice: After discountAmt is deducted & other charges are added from 'subTotal'
  double get getNetPrice => getSubTotal - discountAmount;

  /// Current / Today's Products/Stocks
  bool get isToday {
    var dt = createdAt.toDateTime;

    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  /// Calculate Profit [calculateProfit]
  /// Profit = Revenue − Cost or Profit = (unitPrice - costPrice) * quantity
  double calculateProfit(double costPrice) =>
      costPrice == 0.0 ? 0.0 : (unitPrice - costPrice) * quantity.toDouble();

  /// Find a Specific order by id [findOrdersById]
  static Iterable<POSOrder> findOrdersById(
    List<POSOrder> orders, {
    required String orderId,
  }) => orders.where((order) => order.id == orderId);

  /// Filter Orders [filterOrdersByDate]
  static List<POSOrder> filterOrdersByDate(
    List<POSOrder> orders, {
    bool isSameDay = true,
  }) => orders
      .where((order) => isSameDay ? order.isToday : !order.isToday)
      .toList();

  /// copyWith method
  POSOrder copyWith({
    String? id,
    String? storeNumber,
    String? orderNumber,
    String? itemId,
    String? itemName,
    String? customerId,
    String? status,
    int? quantity,
    String? barcode,
    double? unitPrice,
    double? discountPercent,
    double? taxPercent,
    double? discountAmount,
    double? taxAmount,
    double? totalAmount,
    String? payMethod,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return POSOrder(
      id: id ?? this.id,
      storeNumber: storeNumber ?? this.storeNumber,
      orderNumber: orderNumber ?? this.orderNumber,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      customerId: customerId ?? this.customerId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      barcode: barcode ?? this.barcode,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      payMethod: payMethod ?? this.payMethod,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    orderNumber,
    customerId,
    itemId,
    itemName,
    quantity,
    unitPrice,
    barcode,
    discountPercent,
    taxPercent,
    totalAmount,
    payMethod,
    status,
    createdBy,
    createdAt,
    updatedBy,
    storeNumber,
    updatedAt,
  ];

  /// ToList for POS-ORDER [itemAsList]
  List<String> get itemAsList => [
    id,
    storeNumber,
    itemId.toUpperAll,
    orderNumber,
    customerId,
    itemName.toTitle,
    status.toTitle,
    '$ghanaCedis${unitPrice.toCurrency}',
    '$quantity',
    '$ghanaCedis${getSubTotal.toCurrency}',
    '$discountPercent% = $ghanaCedis${discountAmount.toCurrency}',
    '$taxPercent% = $ghanaCedis${taxAmount.toCurrency}',
    '$ghanaCedis${totalAmount.toCurrency}',
    payMethod.toTitle,
    createdBy.toTitle,
    getCreatedAt,
    updatedBy.toTitle,
    getUpdatedAt,
  ];

  static List<String> get dataTableHeader => const [
    'ID',
    'Store Number',
    'Item ID',
    'Order Number',
    'Customer ID',
    'Item Name',
    'Status',
    'Unit Price',
    'Quantity',
    'Sub Total',
    'Discount',
    'Tax',
    'Total Amount',
    'Payment Method',
    'Created By',
    'Created At',
    'Updated By',
    'Updated At',
  ];
}

/*
* 1. Order Table
  Purpose: Records each order placed, including details such as order ID, date, time, customer information, and payment method.
Fields: Order ID, Customer ID, Order Date, Order Time, Total Amount, Payment Method, Order Status.
* 2. Sales Table
  Purpose: Tracks individual sales transactions, often linked to the order table to provide detailed information about each sale.
Fields: Sale ID, Order ID (foreign key), Product ID, Quantity, Unit Price, Total Price.
* 3. Product Table
  Purpose: Contains information about the products or services available for sale.
Fields: Product ID, Product Name, Description, Price, Category, Supplier ID, Stock Level.
* 4. Customer Table
  Purpose: Stores information about customers, which can be used for loyalty programs, marketing, and personalized service.
Fields: Customer ID, Name, Contact Information, Address, Purchase History.
* 5. Employee Table
  Purpose: Manages employee details, which can include login credentials, roles, and sales performance.
Fields: Employee ID, Name, Position, Contact Information, Sales Performance.
* 6. Payment Table
  Purpose: Records payment details for each transaction, including the method of payment and any related information.
Fields: Payment ID, Order ID, Payment Amount, Payment Date, Payment Method (e.g., cash, credit card).
* 7. Discounts/Promotions Table
  Purpose: Manages information about discounts or promotions applied to orders or products.
Fields: Discount ID, Discount Code, Description, Discount Amount/Percentage, Validity Period, Conditions.
* 8. Tax Table
  Purpose: Contains tax rates and rules applied to transactions.
Fields: Tax ID, Tax Name, Tax Rate, Applicable Regions.
* 9. Return/Refund Table
  Purpose: Keeps track of returns and refunds processed, linked to the original sale and order.
Fields: Return ID, Sale ID (foreign key), Return Date, Refund Amount, Reason for Return.
* 10. Inventory Table
  Purpose: Manages stock levels and inventory transactions, often integrated with or separate from the POS system.
Fields: Inventory ID, Product ID, Stock Level, Reorder Level, Last Restock Date.
* 11. Store/Branch Table
  Purpose: For businesses with multiple locations, this table tracks details specific to each store or branch.
Fields: Store ID, Store Name, Location, Contact Information.
* */
