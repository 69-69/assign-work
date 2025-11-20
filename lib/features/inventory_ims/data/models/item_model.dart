import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:equatable/equatable.dart';

class Item extends Equatable {
  static get _today => DateTime.now();

  final String id; // Firestore will assign a unique ID (documentId)
  final String sku;
  final String batchId;
  final String supplierId;
  final String name;
  final String storeNumber;

  /// The price at which the product is acquired from the producer or manufacturer [costPrice]
  final double costPrice;

  /// The Standard selling price of the item [sellingPrice]
  final double sellingPrice;
  final String category; // item types
  final int inStock;
  final double inStockPercent;

  // Same as Sold-Out or Sales: total number of units sold for a particular product
  final int outOfStock;
  final double outOfStockPercent; // Same as sold-Out-Percent
  final int quantity; // Total items
  final String barcode;
  final double discountPercent;

  // Represents how quickly each product is sold r replaced over a period of time.
  final double turnoverRate;

  // Historical sales data for forecasting
  final List<int> historicalSales;

  /// Manufacturer name or ID [manufacturer]
  final String? manufacturer;
  final String? remarks;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;
  final DateTime? manufactureDate;
  final DateTime? expiryDate;

  Item({
    this.id = '', // Firestore will assign a unique ID (documentId)
    required this.storeNumber,
    this.sku = '',
    this.batchId = '',
    this.supplierId = '',
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    this.barcode = '',
    required this.inStock,
    this.inStockPercent = 0.0,
    // Same as Sold-Out or Sales: total number of units sold for a particular product
    this.outOfStock = 0,
    this.outOfStockPercent = 0.0, // Same as sold-Out-Percent
    required this.quantity, // Total items
    required this.category,
    this.discountPercent = 0.0,
    this.turnoverRate = 0.0,
    this.historicalSales = const [],
    this.manufacturer,
    this.remarks,
    DateTime? expiryDate,
    DateTime? manufactureDate,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : expiryDate = expiryDate ?? _today,
       manufactureDate = manufactureDate ?? _today,
       createdAt = updatedAt ?? _today,
       updatedAt = updatedAt ?? _today; // Set default value

  /// fromFirestore / fromJson Function [Product.fromMap]
  factory Item.fromMap(Map<String, dynamic> data, String documentId) {
    final totalQty = _toIntData(data['quantity']);
    final outOfStock = _toIntData(data['outOfStock']);

    ({double inStockPercent, double outOfStockPercent}) r = _calculateStocks(
      totalQty: totalQty,
      outOfStock: outOfStock,
    );

    return Item(
      id: documentId,
      storeNumber: data['storeNumber'] ?? '',
      sku: data['sku'] ?? '',
      batchId: data['batchId'] ?? '',
      supplierId: data['supplierId'] ?? '',
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      barcode: data['barcode'] ?? '',
      sellingPrice: (data['sellingPrice'] ?? 0.0).toDouble(),
      costPrice: (data['costPrice'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      outOfStock: data['outOfStock'] ?? 0,
      outOfStockPercent: r.outOfStockPercent,
      inStock: data['inStock'] ?? 0,
      inStockPercent: r.inStockPercent,
      discountPercent: data['discountPercent'] ?? 0.0,
      turnoverRate: (data['turnoverRate'] ?? 0.0).toDouble(),
      historicalSales: _toList(data['historicalSales'] ?? []),
      manufacturer: data['manufacturer'] ?? '',
      remarks: data['remarks'] ?? '',
      manufactureDate: toDateTimeFn(data['manufactureDate']),
      expiryDate: toDateTimeFn(data['expiryDate']),
      createdBy: data['createdBy'] ?? '',
      createdAt: toDateTimeFn(data['createdAt']),
      updatedBy: data['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(data['updatedAt']),
    );
  }

  // Convert List<dynamic> to List<int>
  static _toList(List data) => data.map<int>((item) => item as int).toList();

  static _toIntData(dynamic data) => data != null ? data.toInt() : 0;

  // map template
  Map<String, dynamic> _mapTemp() {
    ({double inStockPercent, double outOfStockPercent}) r = _calculateStocks(
      totalQty: quantity,
      outOfStock: outOfStock,
    );

    return {
      'id': id,
      'storeNumber': storeNumber,
      'sku': sku,
      'batchId': batchId,
      'supplierId': supplierId,
      'name': name,
      'category': category,
      'sellingPrice': sellingPrice,
      'costPrice': costPrice,
      'outOfStock': outOfStock,
      'outOfStockPercent': r.outOfStockPercent,
      'inStock': inStock,
      'inStockPercent': r.inStockPercent,
      'quantity': quantity,
      'barcode': barcode,
      'discountPercent': discountPercent,
      'turnoverRate': turnoverRate,
      'historicalSales': historicalSales,
      'manufacturer': manufacturer,
      'remarks': remarks,
      'manufactureDate': manufactureDate,
      'expiryDate': expiryDate,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt,
    };
  }

  /// Convert Model to toFirestore / toJson Function [toMap]
  Map<String, dynamic> toMap() {
    var newMap = _mapTemp();
    newMap['manufactureDate'] = manufactureDate.toISOString;
    newMap['expiryDate'] = expiryDate.toISOString;
    newMap['createdAt'] = createdAt.toISOString;
    newMap['updatedAt'] = updatedAt.toISOString;

    return newMap;
  }

  /// toCache Function [toCache]
  Map<String, dynamic> toCache() {
    var newMap = _mapTemp();
    newMap['manufactureDate'] = manufactureDate?.millisecondsSinceEpoch;
    newMap['expiryDate'] = expiryDate?.millisecondsSinceEpoch;
    newMap['createdAt'] = createdAt.millisecondsSinceEpoch;
    newMap['updatedAt'] = updatedAt.millisecondsSinceEpoch;

    return {'id': id, 'data': newMap};
  }

  /// Calculate Stocks using Dart Records
  static ({double inStockPercent, double outOfStockPercent}) _calculateStocks({
    required int totalQty,
    required int outOfStock,
  }) {
    /// In-Stock Formulae: total items - Out-Of-Stock = Results
    var getInStock = totalQty - outOfStock;

    /// In-Stock-Percentile Formulae:
    /// (InStock / Total items) x 100 = Results in Percentile
    String getInStockPercent = ((getInStock / totalQty) * 100).toStringAsFixed(
      2,
    );

    /// Out-Of-Stock-Percentile (Sold-Out-Percentile) Formulae:
    /// (Out-Of-Stock / Total items) x 100 = Results in Percentage
    String getOutOfStockPercent = ((outOfStock / totalQty) * 100)
        .toStringAsFixed(2);

    return (
      inStockPercent: double.parse(getInStockPercent),
      outOfStockPercent: double.parse(getOutOfStockPercent),
    );
  }

  getTurnoverRate() {
    // Calculate average inventory. Formulae: (beginningInventory + endingInventory) / 2
    int beginningInventory = inStock;
    int endingInventory = quantity;
    double averageInventory = (beginningInventory + endingInventory) / 2;

    // Calculate turnover rate. Formulae: currentSales / averageInventory
    int currentSales = outOfStock;
    double turnOver = currentSales / averageInventory;

    return turnOver.toCurrency;
  }

  bool get isEmpty => isNullOrEmpty || (id.isEmpty && name.isEmpty);

  bool get isNotEmpty => !isEmpty;

  /// Get Out of Stock Values [isOutOfStock]
  bool get isOutOfStock => inStock == 0;

  /// Get In Stock Values [isInStock]
  bool get isInStock => inStock >= 1;

  double get discountAmt => (discountPercent / 100) * sellingPrice;

  /// Formatted to Date Only in String [getExpiryDate]
  String get getExpiryDate => expiryDate.dateOnly;

  /// Formatted to Date Only in String [getManufactureDate]
  String get getManufactureDate => manufactureDate.dateOnly;

  /// Formatted to Standard-DateTime in String [getCreatedAt]
  String get getCreatedAt => createdAt.toStandardDT;

  /// Formatted to Standard-DateTime in String [getUpdatedAt]
  String get getUpdatedAt => updatedAt.toStandardDT;

  /// Product Expired [isExpired]
  bool get isExpired => _today.isAfter(expiryDate.toDateTime);

  /// Current / Today's Products/Stocks
  bool get isToday {
    var dt = createdAt.toDateTime;

    return dt.year == _today.year &&
        dt.month == _today.month &&
        dt.day == _today.day;
  }

  static get notFound => Item(
    name: 'No Data',
    storeNumber: 'No Data',
    costPrice: 0.0,
    sellingPrice: 0.0,
    inStock: 0,
    quantity: 0,
    category: 'No Data',
    createdBy: 'No Data',
  );

  /// [findItemById]
  static Iterable<Item> findItemById(List<Item> items, String itemId) =>
      items.where((item) => item.id == itemId);

  /// Sort items by quantity in Descending order [sortItemsByStockLevel]
  static List<Item> sortItemsByStockLevel(List<Item> items) {
    // Create a copy of the products list to avoid mutating the original list
    List<Item> sortedItems = List.from(items);
    /* Ascending order
    sortedProducts.sort((a, b) => a.quantity.compareTo(b.quantity));*/
    // Descending order
    sortedItems.sort((a, b) => b.inStock.compareTo(a.inStock));
    return sortedItems;
  }

  static List<Item> findExpiredItem(List<Item> items) =>
      items.where((product) => product.isExpired).toList();

  static List<Item> filterItemsByStock(
    List<Item> items, {
    bool inStock = true,
  }) => items.where((i) => inStock ? i.isInStock : i.isOutOfStock).toList();

  /// Filter
  bool filterByAny(String filter) =>
      name.contains(filter) ||
      '$discountPercent'.contains(filter) ||
      storeNumber.contains(filter) ||
      category.contains(filter) ||
      sku.contains(filter) ||
      batchId.contains(filter) ||
      supplierId.contains(filter) ||
      '$sellingPrice'.contains(filter) ||
      '$turnoverRate'.contains(filter) ||
      '$historicalSales'.contains(filter);

  @override
  String toString() => '$name - $category';

  /// copyWith method
  Item copyWith({
    String? id,
    String? storeNumber,
    String? sku,
    String? batchId,
    String? supplierId,
    String? name,
    double? costPrice,
    double? sellingPrice,
    String? barcode,
    int? inStock,
    double? inStockPercent,
    int? outOfStock,
    double? outOfStockPercent,
    int? quantity,
    String? category,
    String? manufacturer,
    String? remarks,
    double? discountPercent,
    double? turnoverRate,
    List<int>? historicalSales,
    DateTime? manufactureDate,
    DateTime? expiryDate,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      storeNumber: storeNumber ?? this.storeNumber,
      sku: sku ?? this.sku,
      batchId: batchId ?? this.batchId,
      supplierId: supplierId ?? this.supplierId,
      name: name ?? this.name,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      barcode: barcode ?? this.barcode,
      inStock: inStock ?? this.inStock,
      inStockPercent: inStockPercent ?? this.inStockPercent,
      outOfStock: outOfStock ?? this.outOfStock,
      outOfStockPercent: outOfStockPercent ?? this.outOfStockPercent,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      discountPercent: discountPercent ?? this.discountPercent,
      turnoverRate: turnoverRate ?? this.turnoverRate,
      historicalSales: historicalSales ?? this.historicalSales,
      manufacturer: manufacturer ?? this.manufacturer,
      remarks: remarks ?? this.remarks,
      manufactureDate: manufactureDate ?? this.manufactureDate,
      expiryDate: expiryDate ?? this.expiryDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    sku,
    storeNumber,
    batchId,
    supplierId,
    name,
    costPrice,
    sellingPrice,
    category,
    quantity,
    inStock,
    inStockPercent,
    outOfStock,
    outOfStockPercent,
    barcode,
    discountPercent,
    turnoverRate,
    historicalSales,
    manufacturer ?? '',
    remarks ?? '',
    manufactureDate ?? '',
    expiryDate ?? '',
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];

  /// ToList for PRODUCTS [itemAsList]
  List<String> itemAsList({int? start, int? end}) {
    var list = [
      id,
      supplierId,
      storeNumber,
      sku,
      batchId,
      name.toTitle,
      category.toTitle,
      '$ghanaCedis$costPrice',
      '$ghanaCedis$sellingPrice',
      '$ghanaCedis${discountAmt.toCurrency} = $discountPercent%',
      '$quantity',
      '$inStock = $inStockPercent%',
      '$outOfStock = $outOfStockPercent%',
      getTurnoverRate().toString(),
      (manufacturer ?? 'none').toTitle,
      getExpiryDate,
      createdBy.toTitle,
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
    'Supplier ID',
    'Store Number',
    'SKU',
    'Batch ID',
    'Product',
    'Category',
    'Cost Price',
    'Selling Price',
    'Discount',
    'Quantity',
    'In-Stock',
    'Sales',
    'Turnover Rate',
    'Manufacturer',
    'Expires On',
    'Created By',
    'Updated By',
    'Updated At',
  ];
}
