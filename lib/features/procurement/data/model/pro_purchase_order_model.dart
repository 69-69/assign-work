import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/procurement/data/model/po_type.dart';
import 'package:equatable/equatable.dart';

/*Below is a consolidated list of **common Purchase Order (PO) fields** used across major ERPs such as **SAP ECC/S/4HANA**, **Oracle ERP**, **Microsoft Dynamics**, **NetSuite**, and others.
The names differ slightly between systems, but the underlying **data elements are largely the same**.

---

# ✅ **1. Header-Level PO Fields (apply to entire PO)**

These fields describe the Purchase Order as a whole.

### **Identification & Control**

* **PO Number**
* **PO Type** (Standard, Subcontracting, Consignment, Services, Blanket/Framework, etc.)
* **Document Date**
* **Posting Date**
* **Created By / Buyer**
* **Company Code / Legal Entity**
* **Purchasing Organization**
* **Purchasing Group**
* **Document Currency**
* **Exchange Rate**

### **Vendor Information**

* **Vendor ID**
* **Vendor Name**
* **Vendor Address**
* **Vendor Payment Terms**
* **Vendor Tax ID**
* **Shipping/Delivery Address**
* **Incoterms** (e.g., FOB, CIF)

### **Terms & Compliance**

* **Payment Terms**
* **Delivery Terms**
* **Header Text / Notes**
* **Terms & Conditions**
* **Retention Terms** (for construction/service POs)
* **Approval Status / Workflow Status**

### **Financial & Tax**

* **Tax Code**
* **Budget Reference / Cost Center (if header-level)**
* **Freight Terms**
* **Overall Discount / Surcharge**

---

# ✅ **2. Item-Level PO Fields (one per line item)**

These describe each product/service being purchased.

### **Material / Service Details**

* **Line Item Number**
* **Material Number / Item Code**
* **Material Description**
* **Material Group / Category**
* **Quantity**
* **Unit of Measure (UOM)**
* **Delivery Date**
* **Item Type** (Goods, Services, Subcontracting, Limit item, etc.)

### **Pricing**

* **Unit Price**
* **Price Unit** (e.g., price per 100 units)
* **Gross Price**
* **Net Price**
* **Tax Code**
* **Discount / Surcharge**
* **Total Line Value**

### **Account Assignment**

(Varies if inventory item, service item, or consumable item)

* **Cost Center**
* **GL Account**
* **Internal Order / Project (WBS/Task)**
* **Asset Number**
* **Profit Center**
* **Accounting Category**

### **Delivery & Logistics**

* **Plant / Location**
* **Storage Location**
* **Delivery Date**
* **Delivery Address**
* **GR-Based Invoice Verification** flag
* **Delivery Complete** indicator
* **Partial Delivery Allowed** flag

### **Procurement Control**

* **Purchasing Info Record**
* **Source List**
* **Contract/Agreement Reference**
* **Requisition Reference**
* **Release Strategy (Approval)**

### **Quality / Compliance**

* **Quality Inspection Required**
* **Batch Information**
* **Shelf Life Requirements**
* **Serial Number Profile**

---

# ✅ **3. Service PO – Specific Fields**

Common for service procurement in systems like SAP, Oracle, NetSuite.

* **Service Line Number**
* **Service Description**
* **Unit of Measure (hours, days, lot, etc.)**
* **Service Quantity**
* **Service Rate**
* **Limits (value limit, quantity limit)**
* **Expected Service Date**
* **Service Entry Sheet Required** flag

---

# ✅ **4. PO Schedule Line Fields (SAP-specific but common concept)**

Represents each planned delivery for a line item.

* **Schedule Line Number**
* **Delivery Date**
* **Scheduled Quantity**
* **Open Quantity**
* **Confirmed Quantity**
* **Vendor Confirmation Number**

---

# 🔄 Mapping Examples: SAP vs Oracle vs Dynamics

| Concept     | SAP Field | Oracle ERP Field | Dynamics Field    |
| ----------- | --------- | ---------------- | ----------------- |
| PO Number   | EBELN     | PO_NUMBER        | Purchase Order ID |
| Vendor      | LIFNR     | SUPPLIER_ID      | Vendor Account    |
| Item        | EBELP     | LINE_NUM         | Line Number       |
| Material    | MATNR     | ITEM_ID          | Item Number       |
| Quantity    | MENGE     | QUANTITY         | Quantity          |
| Price       | NETPR     | UNIT_PRICE       | Unit Price        |
| Cost Center | KOSTL     | COST_CENTER      | Cost Center       |
| GL          | SAKTO     | ACCOUNT          | Ledger Account    |
*/

class ProPurchaseOrder extends Equatable {
  static get _today => DateTime.now();

  final String id; // Firestore will assign a unique ID (documentId)
  final String storeNumber;
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

  final POType poType;

  final String approvedBy;

  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  /// @TODO purchase order fields
  // Taxes
  // Attachments (e.g., specifications)

  ProPurchaseOrder({
    this.id = '',
    this.poNumber = '',
    required this.currency,
    required this.storeNumber,
    required this.supplierId,
    required this.status,
    required this.quantity,
    required this.itemName,
    this.poType = POType.standard,
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

  /// fromFirestore / fromJson Function [ProPurchaseOrder.fromMap]
  factory ProPurchaseOrder.fromMap(Map<String, dynamic> map, {String? docId}) {
    return ProPurchaseOrder(
      id: docId ?? map['id'] ?? '',
      storeNumber: map['storeNumber'] ?? '',
      poNumber: map['poNumber'] ?? '',
      supplierId: map['supplierId'] ?? '',
      status: map['status'] ?? '',
      itemName: map['itemName'] ?? '',
      currency: map['currency'] ?? '',
      poType: POTypeHelper.fromString(map['poType']),
      quantity: map['quantity'] ?? 0,
      unitPrice: map['unitPrice'] ?? 0.0,
      payTerms: map['payTerms'] ?? '',
      payMethod: map['payMethod'] ?? '',
      remarks: map['remarks'] ?? '',
      subTotal: map['subTotal'] ?? 0.0,
      taxPercent: map['taxPercent'] ?? 0.0,
      discountPercent: map['discountPercent'] ?? 0.0,
      totalAmount: map['totalAmount'] ?? 0.0,
      approvedBy: map['approvedBy'] ?? '',
      deliveryDate: toDateTimeFn(map['deliveryDate']),
      createdBy: map['createdBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: toDateTimeFn(map['updatedAt']),
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
    'poType': getPOType,
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
    newMap['deliveryDate'] = createdAt.millisecondsSinceEpoch;
    newMap['createdAt'] = createdAt.millisecondsSinceEpoch;
    newMap['updatedAt'] = updatedAt.millisecondsSinceEpoch;

    return {'id': id, 'data': newMap};
  }

  bool get isEmpty => itemName.isEmpty;

  bool get isNotEmpty => !isEmpty;

  String get getPOType => poType.getLabel;

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

  /// [findProPurchaseOrderById]
  static Iterable<ProPurchaseOrder> findProPurchaseOrderById(
    List<ProPurchaseOrder> po,
    String poId,
  ) => po.where((order) => order.id == poId);

  /// [filterProPurchaseOrderByDate]
  static List<ProPurchaseOrder> filterProPurchaseOrderByDate(
    List<ProPurchaseOrder> po, {
    bool isSameDay = true,
  }) => po
      .where(
        (order) =>
            !order.isApproved && (isSameDay ? order.isToday : !order.isToday),
      )
      .toList();

  /// [filterApprovedPOs]
  static List<ProPurchaseOrder> filterApprovedPOs(List<ProPurchaseOrder> po) =>
      po.where((order) => order.isApproved).toList();

  @override
  String toString() =>
      'PO: $poNumber - $itemName @ ${isToday ? 'Today' : 'Past'}';

  /// copyWith method
  ProPurchaseOrder copyWith({
    String? id,
    String? storeNumber,
    String? poNumber,
    String? supplierId,
    String? itemName,
    String? currency,
    POType? poType,
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
    return ProPurchaseOrder(
      id: id ?? this.id,
      storeNumber: storeNumber ?? this.storeNumber,
      poNumber: poNumber ?? this.poNumber,
      supplierId: supplierId ?? this.supplierId,
      itemName: itemName ?? this.itemName,
      currency: currency ?? this.currency,
      unitPrice: unitPrice ?? this.unitPrice,
      poType: poType ?? this.poType,
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
    poType,
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

  /// ToList for ProPurchaseOrder [itemAsList]
  List<String> itemAsList({int? start, int? end}) {
    var list = [
      id,
      storeNumber,
      poNumber,
      supplierId,
      getPOType.toTitle,
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
    'PO Type',
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

class POLineItem extends Equatable {
  final String itemName;
  final double unitPrice;
  final int quantity;

  const POLineItem({
    required this.itemName,
    required this.unitPrice,
    required this.quantity,
  });

  @override
  List<Object?> get props => [itemName, unitPrice, quantity];
}
