import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';

/// Workflow:
/// Purchase Request (PR) -> Request for Quotation (RFQ) -> Purchase Order (PO)
///
/// Represents a workflow entity that can originate from a PR or RFQ
/// and be converted downstream (e.g., RFQ or PO).
class WorkflowConverter {
  /// PR number or RFQ number depending on workflow stage
  final String workflowNumber;

  /// Business unit or cost center paying for the purchase
  final String costCenterCode;

  /// Department that initiated the request
  final String departmentCode;

  /// User who created the request
  final String requestedBy;

  /// Supplier ID for the purchase
  final String supplierId;
  final String supplierRepId;

  /// Line items carried through the workflow
  final List<LineItem> lineItems;

  /// Payment term for the purchase
  final String paymentTerm;

  const WorkflowConverter({
    required this.workflowNumber,
    required this.costCenterCode,
    required this.departmentCode,
    required this.requestedBy,
    required this.lineItems,
    this.paymentTerm = '',
    this.supplierId = '',
    this.supplierRepId = '',
  });

  factory WorkflowConverter.fromMap(Map<String, dynamic> map) {
    final wfNumber =
        (map['prNumber'] as String?) ?? (map['rfqNumber'] as String?) ?? '';

    return WorkflowConverter(
      workflowNumber: wfNumber,
      supplierId: map['supplierId'] ?? '',
      supplierRepId: map['supplierRepId'] ?? '',
      costCenterCode: map['costCenterCode'] ?? '',
      departmentCode: map['departmentCode'] ?? '',
      requestedBy: map['requestedBy'] ?? '',
      paymentTerm: map['paymentTerm'] ?? '',
      lineItems: LineItem.lineItems(map['lineItems']),
    );
  }

  /// Singleton instance representing an empty / fallback workflow
  static final WorkflowConverter empty = WorkflowConverter(
    workflowNumber: '',
    costCenterCode: '',
    departmentCode: '',
    requestedBy: '',
    lineItems: const [],
  );

  /// True when this instance is the shared empty workflow
  bool get isEmpty => identical(this, WorkflowConverter.empty);

  /// True when this workflow contains usable data
  bool get isNotEmpty => workflowNumber.isEmpty || lineItems.isNotEmpty;
}

/*Map<String, dynamic> toMap() => {
    'prNumber': prNumber,
    'costCenterCode': costCenterCode,
    'departmentCode': departmentCode,
    'requestedBy': requestedBy,
    'lineItems': lineItems.map((i) => i.toMap()).toList(),
  };*/

/*class RFQLineItem extends Equatable {
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double discount;
  final List<String> taxCodes;

  /// [taxAmount] is a non-persistent, computed value for UI display only.
  /// Calculated when [TaxMode.perLineTax] is used. Not stored in the database.
  final double taxAmount;

  /// [taxNames] is a non-persistent, UI-only field derived from [taxCodes] using the tax map.
  /// This value is not saved in the database.
  final String taxNames;

  const RFQLineItem({
    required this.itemName,
    required this.quantity,
    this.taxCodes = const [],
    this.unitPrice = 0.0,

    /// [discount] Discount is in percentage
    this.discount = 0.0,

    /// [taxAmount] UI-only, non-persistent value (per-line tax)
    this.taxAmount = 0.0,

    /// [taxNames] UI-only, non-persistent value (derived from tax codes)
    this.taxNames = '',
  });

  // get list of tax codes
  List<String> get taxCodesList =>
      List<String>.from(taxCodes).whereType<String>().toList();

  /// [subTotal] Calculated sub-total for a line item `[subTotal = quantity * unitPrice]`
  double get subTotal => quantity * unitPrice;
  double get discountAmount => (subTotal * discount) / 100;

  /// [perLineTotal] Calculated total for a line item including tax and after discount.
  /// It is derived as: `[perLineTotal = subTotal - discountAmount + taxAmount]`.
  double get perLineTotal => subTotal - discountAmount + taxAmount;

  /// The amount after applying Discounts BUT before Taxes `[netPrice = subTotal - discountAmount]`
  double get netPrice => subTotal - discountAmount;

  // Get tax amount by tax codes
  double resolvePerItemTaxes(Map<String, ResolveTaxCode> taxMap) =>
      _resolveTaxes(taxCodes, taxMap);

  // Get tax names by tax codes
  String getTaxName(Map<String, ResolveTaxCode> taxMap) =>
      _getTaxName(taxCodes, taxMap, '\n');

  bool get isEmpty => itemName.isEmpty;
  bool get isNotEmpty => !isEmpty;

  factory RFQLineItem.fromMap(Map<String, dynamic> map) {
    return RFQLineItem(
      itemName: map['itemName'] ?? '',
      quantity: int.tryParse('${map['quantity']}') ?? 0,
      unitPrice: double.tryParse('${map['unitPrice']}') ?? 0.0,
      discount: double.tryParse('${map['discount']}') ?? 0.0,
      taxCodes: List<String>.from(
        map['taxCodes'] ?? [],
      ).whereType<String>().toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'itemName': itemName,
    'taxCodes': taxCodes,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'discount': discount,
    // 'unitOfMeasure': getUnitOfMeasure,
  };

  bool filterByAny(String filter) =>
      itemName.contains(filter) ||
      quantity.toString().contains(filter) ||
      discount.toString().contains(filter) ||
      unitPrice.toString().contains(filter) ||
      netPrice.toString().contains(filter);

  RFQLineItem copyWith({
    String? itemName,
    double? unitPrice,
    int? quantity,
    List<String>? taxCodes,

    /// [discount] Discount is in percentage
    double? discount,

    /// [taxAmount] For UI perLineTax (per item) tax amount only
    double? taxAmount,

    /// [taxNames] For UI tax names calculation only
    String? taxNames,
  }) => RFQLineItem(
    itemName: itemName ?? this.itemName,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    taxCodes: taxCodes ?? this.taxCodes,
    discount: discount ?? this.discount,

    taxAmount: taxAmount ?? this.taxAmount,
    taxNames: taxNames ?? this.taxNames,
  );

  @override
  List<Object?> get props => [
    itemName,
    taxCodes,
    unitPrice,
    quantity,
    discount,
  ];

  static List<String> get dataTableHeader => const [
    'Item Name',
    'Unit Price',
    'Quantity',
    'Discount',
    'Net Price',
  ];

  List<String> get itemAsList => [
    itemName.toTitle,
    '$ghanaCedis$unitPrice',
    '$quantity',
    '$discount% = $ghanaCedis$discountAmount',
    '$ghanaCedis$netPrice',
  ];
}*/
