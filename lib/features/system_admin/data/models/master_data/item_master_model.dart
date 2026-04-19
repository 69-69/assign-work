import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/core/util/extensions/line_item_type.dart';
import 'package:assign_erp/core/util/extensions/tax_mode.dart';
import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

/// Winner@g2021 Item Master = “template” / “definition only”: Central definition of all stockable, sellable, and purchasable items
/*1️⃣ How Inventory / StockBalance is used
Goods Receipt (GR):
  When goods arrive from a supplier:
  System checks Item Master for the item definition
  Updates Inventory.quantityOnHand at the receiving warehouse/location/bin
  Optionally updates batchNumber or expiryDate if tracked
  Creates a StockLedger entry for traceability
Goods Issue (GI):
  When goods are issued (to sales, production, transfer, etc.):
  System reduces Inventory.quantityOnHand
  Updates quantityReserved if picking was done
  Creates a StockLedger transaction
Reservation / Picking:
  quantityReserved is used when items are allocated for an order but not yet physically moved
  Ensures that stock isn’t double-booked
Backorders / Ordered Stock:
  quantityOrdered tracks items on purchase orders but not yet received*/

/*2️⃣ Provides Default Values in Transactions (Not for Stocking Items)
  When a user selects an item in:
    PR
    RFQ
    PO
    Goods Receipt
    Sales Quotation
    Sales Order
    POS
  The system auto-fills:
    UOM
    Tax category
    Costing method
    Default warehouse (optional)
    Price
    📌 This speeds up entry and reduces errors.*/

/* USAGE - 🔵 Item Master Form
📋 UI Inputs:
  SKU / Item Code
  Item Name
  Description
  Item Type (Raw / Material / Product / Service)
  Base UOM
  Is Active
  Is Stock Item (auto-disabled for Service)
  Reorder Point (stock items only)
  Reorder Quantity (stock items only)
  Lead Time Days (stock items only)
  Standard Cost
  Costing Method (FIFO / AVG / STD)
  Category / Classification
  Remarks / Notes
  UI → Build ItemMaster Model


ItemMaster(
  id: uuid(),
  sku: itemSKUController.text.trim(),
  name: itemNameController.text.trim(),
  description: itemDescriptionController.text.trim(),
  category: selectedCategory.id,
  itemType: selectedItemType,       // LineItemType.product / service
  baseUom: uomController.text, // EA, KG, LTR
  isActive: isActiveToggle.value,
  isStockItem: selectedItemType != LineItemType.service,
  reorderPoint: selectedItemType != LineItemType.service
  ? double.tryParse(reorderPointController.text) ?? 0
      : 0,
  reorderQty: selectedItemType != LineItemType.service
  ? double.tryParse(reorderQtyController.text) ?? 0
      : 0,
  leadTimeDays: selectedItemType != LineItemType.service
  ? int.tryParse(leadTimeController.text) ?? 0
      : 0,
  standardCost: double.tryParse(standardCostController.text) ?? 0,
  costingMethod: selectedItemType != LineItemType.service
  ? selectedCostingMethod
      : 'NA',
  createdBy: currentUser.id,
  updatedBy: '',
);
*/

enum CostingMethod { fifo, avg, std }

extension CostingMethodExt on CostingMethod {
  String get getName => EnumUtil<CostingMethod>(this).getName;
}

class CostingMethodUtil {
  /// [fromString] Converts String/Label to enum value.
  static CostingMethod fromString(String? value) =>
      EnumUtil.fromString<CostingMethod>(CostingMethod.values, value);

  /// [toStringList] Convert enum list to a list of strings (for dropdowns)
  static List<String> toStringList([bool includeHeader = true]) {
    final list = EnumUtil.toStringList<CostingMethod>(CostingMethod.values);
    return includeHeader ? ['Costing Method', ...list] : list;
  }
}

List<String> extractHeaders<T>(T model, {bool isHuman = false}) {
  final map = (model as dynamic).toMap() as Map<String, dynamic>;
  return map.keys.map((k) => isHuman ? k.toSeparate : k).toList();
}

/* ## Recommended helper text (UI-ready)

### **isActive**

> **Active item**
> When disabled, this item cannot be selected in new transactions (Purchase, Sales, Inventory).
> Existing records are not affected.

---

### **isStockItem**

> **Stock-managed item**
> Enable if this item is physically stored and its quantity should be tracked in inventory.
> Disable for services and non-stock items.

---

### **isPurchasable**

> **Available for purchasing**
> Enable if this item can be requested, quoted, or ordered from suppliers.
> Required for Purchase Requisitions and Purchase Orders.

---

### **isSellable**

> **Available for sales**
> Enable if this item can be offered and sold to customers.
> Required for Sales Quotes and Sales Orders.

---

### **reorderQty**

> **Reorder quantity**
> The default quantity suggested when stock falls below the reorder point.
> Used for planning and purchase suggestions only.

---

### **leadTimeDays**

> **Lead time (days)**
> Estimated number of days between ordering this item and receiving it.
> Used for planning and delivery scheduling.

---

### **reorderPoint**

> **Reorder point**
> Minimum stock level that triggers a reorder suggestion.
> When inventory falls below this level, the system recommends replenishment.

---

### **standardCost**

> **Standard cost per unit**
> The expected cost of one unit of this item, used for inventory valuation and cost reporting.
> Not required for services.

---

### **costingMethod**

> **Inventory costing method**
> Determines how inventory cost is calculated when items are issued or sold:
>
> * **FIFO** – Uses the oldest stock cost first
> * **Average** – Uses the average cost of all stock
> * **Standard** – Uses the standard cost defined above

---

## Optional UX enhancement (highly recommended)

### Auto-hint logic

You can dynamically show warnings like:

* If `itemType == Service` and `isStockItem == true`
  ⚠️ *Services cannot be stock-managed*

* If `isStockItem == false`
  ℹ️ *Reorder settings are ignored for non-stock items*

---

## One-line UX philosophy (ERP-grade)

> **Tell users what the system will do, not what the field is.**
*/

// ItemMaster has NO quantities
class ItemMaster extends Equatable {
  static DateTime get _today => DateTime.now();

  /// 1. Identification
  final String storeNumber; // FK CompanyStore.storeNumber
  final String id; // UUID
  final String sku; // Unique ItemCode
  final String name;
  final String description;

  /// 2. Classification
  // Electronics, Furniture, Raw Materials, Finished Goods, Services, Packaging, Consumables.
  final String category;
  final LineItemType itemType; // raw, material/product, service
  // final List<String> barcodes; // Optional multiple barcodes
  // final List<String> taxCodes;
  // final List<String> barcodes;
  // final PriceList priceList;
  // final List<Variant> variants; // e.g., ["Size: L", "Color: Red", "Model": XYZ, ]

  /// 3. Units & Rules
  final UnitOfMeasure baseUom; // EA, KG, LTR
  final bool isActive;

  // isStockItem: Is this item allowed to participate in inventory processes?
  // false for 'itemType' as services
  final bool isStockItem;
  final bool isPurchasable; // Can this item appear on PR / RFQ / PO lines?
  final bool
  isSellable; // Can this item appear on Sales Quote / Sales Order lines?

  /// 4. Planning (stock items only)
  /* [reorderPoint]
  Purpose: Minimum inventory level at which the system should trigger a reorder suggestion.
  Example: If reorderPoint = 50 for an item, and your inventory falls to 45, the system knows it’s time to buy/produce more.
  Use Cases:
    Automated alerts in inventory management.
    Triggering procurement workflows for stockable items.*/
  final double reorderPoint;

  /* [reorderQty]
    Purpose: Default quantity to reorder when the stock reaches the reorder point.
    Example: reorderQty = 200 → system suggests ordering 200 units whenever inventory hits the reorder point.
    Use Cases:
      Simplifies purchase order creation.
      Ensures consistent lot sizing for procurement or production.*/
  final double reorderQty;
  final int leadTimeDays;

  /// 5. Costing (stock items only)
  // For products/materials → standardCost + costingMethod define how your inventory is valued.
  // For services → these fields are irrelevant, because there is no stock to value.
  /* standardCost: Only stockable items (isStockItem = true).
    Purpose: The base cost of one unit of the item, used for:
    Inventory valuation*/
  final double? standardCost;

  /*costingMethod
      Purpose: Defines how the inventory value is calculated when items are bought, produced, or sold. Common methods:
        FIFO (First In, First Out) – The oldest stock is considered used/sold first.
      Example: Bought 100 units at $10, then 100 at $12.
        Selling 50 units → cost = $10 × 50
      AVG (Weighted Average) – Average cost of all stock is used.
      Example: Bought 100 units at $10, 100 units at $12 → average = $11/unit
        Selling 50 units → cost = $11 × 50
        STD (Standard Cost) – Always uses the predefined standardCost.
      Example: Selling any quantity → cost = $10 × quantity (ignores purchase price)
      Important:
        Only used for stockable items, never for services.
        Determines inventory valuation in accounting reports.*/
  final CostingMethod costingMethod; // FIFO, AVG, STD

  /// 6. Audit (For snapshot)
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  /// 7. Audit history (candidate for extraction)
  final List<AuditLog> history;
  final TaxMode taxMode;

  ItemMaster({
    required this.storeNumber,
    this.id = '',
    required this.sku,
    required this.name,
    this.description = '',
    this.itemType = LineItemType.material,
    required this.category,
    required this.baseUom,
    this.isStockItem = false,
    this.isPurchasable = false,
    this.isSellable = false,
    this.isActive = true,
    this.reorderPoint = 0,
    this.reorderQty = 0,
    this.leadTimeDays = 0,
    this.standardCost,
    this.costingMethod = CostingMethod.avg,
    this.taxMode = TaxMode.headerTax,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
    this.history = const [],
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  factory ItemMaster.fromMap(Map<String, dynamic> map, {String? id}) {
    return ItemMaster(
      storeNumber: map['storeNumber'] ?? '',
      id: id ?? map['id'] ?? '',
      sku: map['sku'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      itemType: LineItemTypeUtil.fromString(map['itemType']),
      baseUom: UOMUtil.fromString(map['baseUom']),
      isStockItem: map['isStockItem'] ?? false,
      isPurchasable: map['isPurchasable'] ?? false,
      isSellable: map['isSellable'] ?? false,
      isActive: map['isActive'] ?? true,
      reorderPoint: '${map['reorderPoint']}'.asDouble,
      reorderQty: '${map['reorderQty']}'.asDouble,
      leadTimeDays: '${map['leadTimeDays']}'.asInt,
      standardCost: '${map['standardCost']}'.asDouble,
      costingMethod: CostingMethodUtil.fromString(map['costingMethod']),
      taxMode: TaxModeUtil.fromString(map['taxMode'] ?? TaxMode.headerTax.getName),
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
      createdAt: toDateTimeFn(map['createdAt']),
      updatedAt: toDateTimeFn(map['updatedAt']),
      history: AuditLog.auditLogs(map['history']),
    );
  }

  /// Serialize to Map / JSON
  Map<String, dynamic> _mapTemp() => {
    'storeNumber': storeNumber,
    'id': id,
    'sku': sku,
    'name': name,
    'description': description,
    'category': category,
    'itemType': getType,
    'baseUom': getUOM,
    'isActive': isActive,
    'isStockItem': isStockItem,
    'isPurchasable': isPurchasable,
    'isSellable': isSellable,
    'reorderPoint': reorderPoint,
    'reorderQty': reorderQty,
    'leadTimeDays': leadTimeDays,
    'standardCost': standardCost,
    'costingMethod': costingMethod.getName,
    'taxMode': getTaxName,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'history': history.map((e) => e.toMap()).toList(),
  };

  String get getUOM => baseUom.getName;

  String get getType => itemType.getName;

  // The name is needed not a label
  String get getTaxName => taxMode.getName;

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

  /// [pickKeys] Returns a subset of this item’s map containing only the specified [keys].
  ///
  /// - Keys not present in the map are ignored.
  /// - Useful for projecting the item into form-specific or UI-specific datasets.
  Map<String, dynamic> pickKeys(Set<String> keys) {
    final map = toMap();
    return Map.fromEntries(map.entries.where((e) => keys.filterAny(e.key)));
  }

  /// [empty] Empty ItemMaster object.
  static final ItemMaster empty = ItemMaster(
    storeNumber: '',
    sku: '',
    name: '',
    description: '',
    category: '',
    createdBy: '',
    baseUom: UnitOfMeasure.unknown,
  );

  /// [isEmpty] Checks if the ItemMaster is empty.
  bool get isEmpty => identical(this, ItemMaster.empty);

  bool get isNotEmpty => !isEmpty;

  /// Filter/search
  bool filterByAny(String filter) =>
      itemAsList.filterAny(filter) ||
      {description, category, standardCost, costingMethod}.filterAny(filter);

  /// [findById] Find ItemMaster by ID.
  static ItemMaster? findById(List<ItemMaster> items, String id) =>
      items.firstWhereOrNull((i) => i.id == id);

  ItemMaster copyWith({
    String? storeNumber,
    String? id,
    String? sku,
    String? name,
    String? description,
    String? category,
    LineItemType? itemType,
    UnitOfMeasure? baseUom,
    bool? isActive,
    bool? isStockItem,
    bool? isPurchasable,
    bool? isSellable,
    double? reorderPoint,
    double? reorderQty,
    int? leadTimeDays,
    double? standardCost,
    CostingMethod? costingMethod,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    List<AuditLog>? history,
    TaxMode? taxMode,
  }) => ItemMaster(
    storeNumber: storeNumber ?? this.storeNumber,
    id: id ?? this.id,
    sku: sku ?? this.sku,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    itemType: itemType ?? this.itemType,
    baseUom: baseUom ?? this.baseUom,
    isActive: isActive ?? this.isActive,
    isStockItem: isStockItem ?? this.isStockItem,
    isPurchasable: isPurchasable ?? this.isPurchasable,
    isSellable: isSellable ?? this.isSellable,
    reorderPoint: reorderPoint ?? this.reorderPoint,
    reorderQty: reorderQty ?? this.reorderQty,
    leadTimeDays: leadTimeDays ?? this.leadTimeDays,
    standardCost: standardCost ?? this.standardCost,
    costingMethod: costingMethod ?? this.costingMethod,
    taxMode: taxMode ?? this.taxMode,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedBy: updatedBy ?? this.updatedBy,
    updatedAt: updatedAt ?? this.updatedAt,
    history: history ?? this.history,
  );

  /// ToList for StoreLocation [itemAsList]
  List<String> get itemAsList => [
    id,
    sku,
    name,
    isStockItem ? 'Yes' : 'No',
    isSellable ? 'Yes' : 'No',
    isPurchasable ? 'Yes' : 'No',
    reorderPoint.toString(),
    reorderQty.toString(),
    createdBy.toTitle,
    updatedBy.toTitle,
  ];

  static List<String> get dataTableHeader => const [
    'ID',
    'SKU',
    'Item Name',
    'Track Inventory',
    'Sellable',
    'Purchasable',
    'Reorder Point',
    'Reorder Quantity',
    'Created By',
    'Updated By',
  ];

  /// For Bulk Upload/Saving template
  static Map<String, dynamic> get templateHeader => empty.toMap();

  @override
  List<Object?> get props => [
    storeNumber,
    id,
    sku,
    name,
    category,
    baseUom,
    isActive,
    isStockItem,
    reorderPoint,
    reorderQty,
    leadTimeDays,
    standardCost,
    costingMethod,
    taxMode,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
    history,
  ];
}

/*In an **ERP (Enterprise Resource Planning) system**, the **Item Master** (often called **Item Master Data** or **Product Master**) is a **centralized record that stores all essential information about an item** that a company buys, makes, stores, or sells.

Think of it as the **single source of truth for every product or material** in the organization.

---

## What is an Item Master?

The **Item Master** is a database table (or set of tables) that contains **one unique record per item**, identified by an **Item Code / Item Number**.

This record is referenced across multiple ERP modules such as:

* Purchasing
* Inventory
* Manufacturing
* Sales
* Finance
* Planning (MRP)

---

## Typical Information Stored in an Item Master

### 1. Identification Details

* Item code / Item number
* Item description
* Category / Item group
* Barcode / SKU

### 2. Inventory & Logistics

* Unit of Measure (UOM)
* Stock type (raw material, WIP, finished good)
* Storage conditions
* Warehouse locations
* Lot / serial tracking rules

### 3. Purchasing Information

* Preferred suppliers
* Purchase UOM
* Lead time
* Minimum order quantity
* Last purchase price

### 4. Sales Information

* Sales price
* Sales UOM
* Tax classification
* Customer-specific item codes

### 5. Manufacturing & Planning

* Bill of Materials (BOM) reference
* Make or buy indicator
* Planning parameters (safety stock, reorder point)
* Production lead time

### 6. Financial & Accounting Data

* Standard cost / average cost
* Valuation method
* GL account mappings
* Tax codes

---

## Why Item Master Is Important

* **Consistency**: Same item data used across all departments
* **Accuracy**: Prevents duplicate or incorrect item creation
* **Efficiency**: Faster purchasing, sales, and production planning
* **Control**: Better inventory valuation and cost management
* **Integration**: Enables smooth flow between ERP modules

---

## Example

If a company sells a **Laptop**, the Item Master would include:

* Item Code: LAP-001
* Description: 14” Business Laptop
* UOM: Each
* Cost: $700
* Sales Price: $950
* Supplier: ABC Electronics
* Stock Type: Finished Good

This single record is used by **sales orders, purchase orders, inventory transactions, and financial postings**.
*/

/*class ItemMaster2 extends Equatable {
  static get _today => DateTime.now();

  /// 1. Identification
  final String id; // UUID
  final String sku; // SKU/ItemCode: Unique stock keeping unit
  final String name; // Product / Item name
  final String description; // Optional detailed description

  /// 2. Categorization
  final String category; // FK to ItemCategory
  final String categoryName; // Denormalized for reporting

  /// 3. Unit of Measure
  final String baseUom; // Base unit (pcs, kg, liter, etc.)
  final double? conversionFactor; // Optional: for alternate units

  /// 4. Pricing & Cost
  final double purchasePrice; // Cost for procurement
  final double sellingPrice; // Standard selling price
  final double? taxRate; // Tax percentage applicable

  /// 5. Barcodes / Identifiers
  final List<String> barcodes; // Optional multiple barcodes
  final String? externalId; // Optional external system reference

  /// 6. Variants & Lead Time (Days)
  final Map<String, String> variants; // e.g., {"Size": "L", "Color": "Red"}
  // final List<String> variantNames; // e.g., ["Size", "Color"]
  // final List<String> variantValues; // e.g., ["L", "Red"]
  // final List<String> variantLabels; // e.g., ["Size: L", "Color: Red", "Model": XYZ, ]
  final double leadTime;

  /// 7. Inventory tracking flags
  final bool isActive; // Active / inactive for sales

  /// 8. Audit / System
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  ItemMaster2({
    required this.id,
    required this.sku,
    required this.name,
    this.description = '',
    required this.category,
    this.categoryName = '',
    required this.baseUom,
    this.conversionFactor,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.taxRate,
    this.barcodes = const [],
    this.externalId,
    this.variants = const {},
    this.leadTime = 0.0,
    this.isActive = true,
    required this.createdBy,
    DateTime? createdAt,
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? _today,
       updatedAt = updatedAt ?? _today;

  /// Deserialize from Map / JSON
  factory ItemMaster2.fromMap(Map<String, dynamic> map) {
    return ItemMaster2(
      id: map['id'] ?? '',
      sku: map['sku'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      categoryName: map['categoryName'] ?? '',
      baseUom: map['baseUom'] ?? 'pcs',
      conversionFactor: '${map['conversionFactor']}'.asDouble,
      purchasePrice: '${map['purchasePrice']}'.asDouble,
      sellingPrice: '${map['sellingPrice']}'.asDouble,
      taxRate: '${map['taxRate']}'.asDouble,
      barcodes: List<String>.from(map['barcodes'] ?? []),
      externalId: map['externalId'],
      variants: Map<String, String>.from(map['variants'] ?? {}),
      leadTime: '${map['leadTime']}'.asDouble,
      isActive: map['isActive'] ?? true,
      createdBy: map['createdBy'],
      updatedBy: map['updatedBy'],
      createdAt: toDateTimeFn(map['createdAt']),
      updatedAt: toDateTimeFn(map['updatedAt']),
    );
  }

  /// Serialize to Map / JSON
  Map<String, dynamic> _mapTemp() => {
    'id': id,
    'sku': sku,
    'name': name,
    'description': description,
    'category': category,
    'categoryName': categoryName,
    'baseUom': baseUom,
    'conversionFactor': conversionFactor,
    'purchasePrice': purchasePrice,
    'sellingPrice': sellingPrice,
    'taxRate': taxRate,
    'barcodes': barcodes,
    'externalId': externalId,
    'variants': variants,
    'isActive': isActive,
    'leadTime': leadTime,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
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

  ItemMaster2 copyWith({
    String? id,
    String? sku,
    String? name,
    String? description,
    String? category,
    String? categoryName,
    String? baseUom,
    double? conversionFactor,
    double? purchasePrice,
    double? sellingPrice,
    double? taxRate,
    List<String>? barcodes,
    String? externalId,
    Map<String, String>? variants,
    double? leadTime,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) => ItemMaster2(
    id: id ?? this.id,
    sku: sku ?? this.sku,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    categoryName: categoryName ?? this.categoryName,
    baseUom: baseUom ?? this.baseUom,
    conversionFactor: conversionFactor ?? this.conversionFactor,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    taxRate: taxRate ?? this.taxRate,
    barcodes: barcodes ?? this.barcodes,
    externalId: externalId ?? this.externalId,
    variants: variants ?? this.variants,
    leadTime: leadTime ?? this.leadTime,
    isActive: isActive ?? this.isActive,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedBy: updatedBy ?? this.updatedBy,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    sku,
    name,
    category,
    baseUom,
    purchasePrice,
    sellingPrice,
    taxRate,
    barcodes,
    variants,
    isActive,
    leadTime,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];
}*/
