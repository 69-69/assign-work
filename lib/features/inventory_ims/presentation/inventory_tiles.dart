import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/features/inventory_ims/data/permission/inventory_permission.dart';
import 'package:flutter/material.dart';

/*ChatGPT QA: Im developing an ERP system in dart flutter: Im done with Procurement (PR-RFQ-PO), Sales & Distribution (Sales Quote) and Item master.
Currently working on Stock management (StockTransaction = Goods Receipt, Goods Issue, Transfer, Adjustment) & Warehouses.

NOTE: However, since StockTXN depends on "(FK → Warehouse.id), (FK → Location.id)"
- im developing the warehouse management (warehouse, location, bin,
Inbound-Receiving, Internal-Movements & Picking-Shipments)?*/

/// Inventory Management System App(IMS) Dashboard tiles [InventoryTiles]
extension InventoryTiles on dynamic {
  /// Sub Menu Tiles under orders tab
  List<DashboardTile> get ordersSubTiles {
    final tilesData = [
      {
        'hasSplit': true,
        'label': 'sales . order',
        'icon': Icons.trending_up,
        'route': RouteNames.salesOrders,
        'param': {},
        'access': _getName(InventoryPermission.manageSOs),
        'description': 'Create orders for customers or clients',
      },
      {
        'hasSplit': true,
        'label': 'purchase . order',
        'icon': Icons.paypal,
        'route': RouteNames.imsPurchaseOrders,
        'param': {},
        'access': _getName(InventoryPermission.managePOs),
        'description': 'generate POs to suppliers to request goods or services',
      },
    ];

    return tilesData.map((e) => DashboardTile.fromMap(e)).toList();
  }

  /// Sub Menu Tiles under Stock management tab
  List<DashboardTile> get stockManagementSubTiles {
    final tilesData = [
      {
        'hasSplit': true,
        'label': 'goods . receipt',
        'icon': Icons.receipt_long,
        'route': RouteNames.goodsReceipt,
        'param': {},
        'access': _getName(InventoryPermission.manageGoodsReceipt),
        'description':
            'Record and post the receipt of physical goods from suppliers into inventory.',
      },
      {
        'hasSplit': true,
        'label': 'goods . issue',
        'icon': Icons.output,
        'route': RouteNames.goodsIssue,
        'param': {},
        'access': _getName(InventoryPermission.manageGoodsIssue),
        'description':
            'Issue goods from inventory for sales, production, transfers, or internal use.',
      },
      {
        'hasSplit': true,
        'label': 'stock . transfer',
        'icon': Icons.compare_arrows,
        'route': RouteNames.stockTransfer,
        'param': {},
        'access': _getName(InventoryPermission.manageStockTransfer),
        'description':
            'Transfer stock between warehouses, locations, or bins without affecting overall inventory levels.',
      },
      {
        'hasSplit': true,
        'label': 'stock . adjustment',
        'icon': Icons.tune,
        'route': RouteNames.stockAdjustment,
        'param': {},
        'access': _getName(InventoryPermission.manageStockAdjustment),
        'description':
            'Adjust inventory quantities to account for discrepancies from counts, damage, loss, or corrections.',
      },
      {
        'hasSplit': true,
        'label': 'reserve . stocks',
        'icon': Icons.lock_outline,
        'route': RouteNames.reserveStocks,
        'param': {},
        'access': _getName(InventoryPermission.manageReserveStocks),
        'description':
            'Reserve available inventory quantities to prevent them from being issued or sold.',
      },
      {
        'hasSplit': true,
        'label': 'returns . from customers',
        'icon': Icons.rotate_left,
        'route': RouteNames.returnsFromCustomers,
        'param': {},
        'access': _getName(InventoryPermission.manageReturns),
        'description':
            'Process returned goods from customers and update inventory accordingly.',
      },
    ];

    return tilesData.map((e) => DashboardTile.fromMap(e)).toList();
  }

  /// Sub Menu Tiles under Warehouse tab
  List<DashboardTile> get warehouseSubTiles {
    final tileData = [
      // ───────────── Master Data ─────────────
      {
        'label': 'Warehouse',
        'icon': Icons.store,
        'route': RouteNames.warehouse,
        'param': {},
        'access': _getName(InventoryPermission.manageWarehouseAddress),
        'description':
            'Define physical storage facilities such as Main, Store, or Transit warehouses.',
      },
      {
        'label': 'Location',
        'icon': Icons.view_kanban,
        'route': RouteNames.warehouseLocation,
        'param': {},
        'access': _getName(InventoryPermission.manageWHLocation),
        'description':
            'Define sub-areas within a warehouse, such as racks, aisles, or shelves.',
      },
      {
        'label': 'Bin',
        'icon': Icons.inbox,
        'route': RouteNames.warehouseBin,
        'param': {},
        'access': _getName(InventoryPermission.manageWHBin),
        'description':
            'Define precise storage bins inside a location for accurate stock placement.',
      },

      // ───────────── Inbound Execution ─────────────
      {
        'hasSplit': true,
        'label': 'Inbound . Receiving',
        'icon': Icons.call_received,
        'route': RouteNames.inboundReceiving,
        'param': {},
        'access': _getName(InventoryPermission.manageWHReceiving),
        'description':
            'Receive incoming goods from purchase orders and place them into warehouse bins.',
      },
      {
        'hasSplit': true,
        'label': 'Internal . Movements',
        'icon': Icons.swap_horiz,
        'route': RouteNames.internalMovements,
        'param': {},
        'access': _getName(InventoryPermission.manageWHMovement),
        'description':
            'Move stock internally between bins or locations within the same warehouse.',
      },

      // ───────────── Outbound Execution ─────────────
      {
        'hasSplit': true,
        'label': 'Picking . Shipments',
        'icon': Icons.local_shipping,
        'route': RouteNames.outboundPickShipping,
        'param': {},
        'access': _getName(InventoryPermission.manageWHPickShipping),
        'description':
            'Pick, pack, and ship goods to customers in a single outbound process.',
      },
    ];

    return tileData.map((e) => DashboardTile.fromMap(e)).toList();
  }

  /// Sub Menu Tiles under Inventory Dashboard
  List<DashboardTile> get inventoryTiles {
    final tilesData = [
      /// NEW Modules (These will be added)

      /* 2️⃣ Stock Management
          Purpose: Define where stock can exist - Real-time stock control.
          Key objects:
          Stock On Hand
          Available Quantity
          Reserved Quantity
          Damaged / Blocked Stock
        📌 Core for preventing overselling.
        =========================
        2️⃣ Stock Management
          Purpose: Ensures real-time visibility and control over stock levels.
          It tracks the actual quantities available and makes sure there’s no overselling.
        Key Objects:
          Stock On Hand: The total quantity of an item in inventory.
          Available Quantity: Quantity that is ready for sale or use.
          Reserved Quantity: Stock reserved for a sales order or production process.
          Damaged / Blocked Stock: Items that are no longer sellable or usable, flagged for reporting.
        Why It Matters:
          This module is core to preventing overselling. It helps balance sales, production, and
          procurement by providing real-time visibility into what’s actually available and what’s already committed elsewhere in the system.
        What it does:
          Warehouses
          Bins / locations
          Stock rules (min/max, reorder level)*/
      {
        'hasSplit': true,
        'label': 'Stock . Management',
        'icon': Icons.assignment_returned,
        'route': RouteNames.stockManagementModule,
        'param': {},
        'access': _getName(InventoryPermission.manageStock),
        'description':
            'Record, view available, reserved, and total stock quantities.',
      },

      /*3️⃣ Warehouse Management
        Purpose: Physical stock organization.
        Key objects:
        Warehouses
        Locations / Bins
        Zones / Racks
        Put-away rules
        Picking strategies
        📌 Scales from simple warehouse → WMS-level complexity.
        ==================
        3️⃣ Warehouse Management
          Purpose: Organizes physical stock within the warehouse or distribution center. It helps optimize the space, flow, and handling of products, which becomes increasingly important as your business grows.
        Key Objects:
          Warehouses: Different locations where stock is held (e.g., Main Warehouse, Regional Depot).
          Locations / Bins: Specific spots within the warehouse (e.g., “Aisle 3, Bin 5”).
          Zones / Racks: Larger divisions within the warehouse (e.g., Cold Storage, Bulk Storage).
          Put-away Rules: Guidelines for where to store products based on size, demand, and other factors.
          Picking Strategies: Optimized processes for retrieving items, such as FIFO (First In, First Out) or LIFO (Last In, First Out), depending on product type.
        Why It Matters:
          This module can scale from a simple warehouse system to a WMS (Warehouse Management System)-level solution, with features like automated stock picking, real-time location tracking, and advanced reporting.
          It’s crucial for large businesses with multiple warehouses or complex inventory flows.
        */
      {
        'hasSplit': true,
        'label': 'Warehouse . Management',
        'icon': Icons.warehouse,
        'route': RouteNames.wmsModule,
        'param': {},
        'access': _getName(
          InventoryPermission.manageWarehouse,
        ), // Temporal Placeholder
        // 'access': _getName(InventoryPermission.manageWarehouses),
        'description': 'Manage warehouses, bins, racks, and storage locations.',
      },

      /*6️⃣ Inventory Reports & Analytics
        Purpose: Visibility and control
        This module turns raw inventory data into actionable insights for managers and planners.
        Common Reports
        Stock Aging – how long items have been in stock
        Inventory Turnover – how fast stock is sold/used
        Dead Stock – items with no movement
        Fast / Slow Moving Items
        Warehouse Utilization – space and capacity usage
        Why it matters
        Identifies cash tied up in inventory
        Improves purchasing and stocking decisions
        Supports strategic planning and audits*/
      {
        'hasSplit': true,
        'label': 'Inventory . Reports',
        'icon': Icons.bar_chart,
        // 'route': RouteNames.inventoryReports,
        'route': RouteNames.items,
        // Temporal Placeholder
        'param': {},
        // 'access': _getName(InventoryPermission.viewInventoryReports),
        'access': _getName(InventoryPermission.manageStock),
        // Temporal Placeholder
        'description':
            'Visual insights of stock levels, movement, aging, and inventory performance.',
        // Visual insights into stock levels, movement trends, aging analysis, and overall inventory performance.
      },

      /// OLD Modules (These will be remove)
      // stocking tab
      {
        'label': 'stocks',
        'icon': Icons.receipt_long,
        'route': RouteNames.items,
        'param': {},
        'access': _getName(InventoryPermission.manageStock),
        'description': 'add or create new items to the inventory.',
      },
      // orders tab
      {
        'label': 'orders',
        'icon': Icons.shopping_cart,
        'route': RouteNames.orders,
        'param': {},
        'access': _getName(InventoryPermission.manageOrders),
        'description':
            'create purchase orders (POs), sales orders (SOs), and miscellaneous orders (MOs) for suppliers or customers',
      },
      // for inventory
      {
        'hasSplit': true,
        'label': 'misc . order',
        'icon': Icons.payments_outlined,
        'route': RouteNames.miscOrders,
        'param': {},
        'access': _getName(InventoryPermission.manageMOs),
        'description':
            'create additional orders that may include special requests, one-time purchases',
      },
      /*{
        'label': 'Item Categories',
        'icon': Icons.dashboard_customize_outlined,
        'route': RouteNames.itemCategories,
        'param': {},
        'access': _getName(InventoryPermission.manageItemCategory),
        'description':
            'Organize items into categories for easier tracking and reporting.',
      },
      {
        'label': 'Item Suppliers',
        'icon': Icons.local_shipping,
        'route': RouteNames.itemSuppliers,
        'param': {},
        'access': _getName(InventoryPermission.manageItemSuppliers),
        'description':
            'Manage suppliers linked to specific items for sourcing and restocking.',
      },*/
      // deliveries tab
      {
        'label': 'deliveries',
        'icon': Icons.delivery_dining,
        'route': RouteNames.deliveries,
        'param': {},
        'access': _getName(InventoryPermission.manageDeliveries),
        'description':
            'add or create delivery of order(s) and update their status.',
      },
      // sales tab
      {
        'label': 'sales',
        'icon': Icons.shopping_basket,
        'route': RouteNames.sales,
        'param': {},
        'access': _getName(InventoryPermission.manageSales),
        'description': 'keep track of, and oversee the progress of sales.',
      },
      // credit/debit cards, mobile payments, and cash tabs
      {
        'label': 'payment',
        'icon': Icons.payments_outlined,
        'route': RouteNames.posPayments,
        'param': {},
        'access': _getName(InventoryPermission.manageOrders),
        'description':
            'records payment details for each transaction: payment method and any related information',
      },
      // finance tab
      {
        'label': 'finance',
        'icon': Icons.money,
        'route': RouteNames.posPayments,
        'param': {},
        'access': _getName(InventoryPermission.manageOrders),
        'description':
            'Manages & analyzes company\'s financial resources; budgeting, forecasting, investing',
      },
      // invoice tab
      {
        'label': 'invoice',
        'icon': Icons.receipt,
        'route': RouteNames.invoice,
        'param': {},
        'access': _getName(InventoryPermission.viewInvoice),
        'description':
            'keep history of the creation and processing of receipts',
      },
      // report analytics tab
      {
        'hasSplit': true,
        'label': 'report . Analytics',
        'icon': Icons.add_chart,
        'route': RouteNames.inventReports,
        'param': {},
        'access': _getName(InventoryPermission.viewReport),
        'description':
            'generate sales reports, inventory status, turnover rates, forecasts, and performance analytics',
      },
      // tracking tab
      {
        'label': 'tracking',
        'icon': Icons.location_on,
        'route': RouteNames.ordersTracking,
        'param': {},
        'access': _getName(InventoryPermission.manageOrders),
        'description': 'monitor the progress of order placement and deliveries',
      },
    ];

    final defaultTiles = tilesData
        .map((e) => DashboardTile.fromMap(e))
        .toList();

    return defaultTiles;
  }
}

// Get name from enum
String _getName(e) => EnumUtil<InventoryPermission>(e).getName;

/**In a **full ERP**, **Inventory** is not just “stock in / stock out”. It’s a **core operational domain** with multiple tightly related **sub-modules** that support Sales, Procurement, POS, Manufacturing, and Finance.

    Below is a **clean, enterprise-grade breakdown** of what typically falls **under the Inventory module**, with practical ERP context.

    ---

    # @TODO Core Inventory Modules

    ## 1️⃣ Item / Product Master

 **Purpose:** Central definition of everything that can be stocked.

 **Key objects:**

 * Items / Products
 * Item Categories
 * Units of Measure (UOM)
 * Barcodes / SKUs
 * Variants (size, color, model)
 * Lot / Serial tracking flags

    📌 Shared across **Sales, Procurement, POS, Manufacturing**.

    ---

    ## 2️⃣ Stock Management

 **Purpose:** Real-time stock control.

 **Key objects:**

 * Stock On Hand
 * Available Quantity
 * Reserved Quantity
 * Damaged / Blocked Stock

    📌 Core for preventing overselling.

    ---

    ## 3️⃣ Warehouse Management

 **Purpose:** Physical stock organization.

 **Key objects:**

 * Warehouses
 * Locations / Bins
 * Zones / Racks
 * Put-away rules
 * Picking strategies

    📌 Scales from simple warehouse → WMS-level complexity.

    ---

    ## 4️⃣ Goods Receipt (Inbound)

 **Purpose:** Increase inventory from external sources.

 **Sources:**

 * Purchase Orders
 * Customer Returns
 * Production Output

 **Key objects:**

 * Goods Receipt Notes (GRN)
 * Receiving Inspection
 * Partial Receipts

    ---

    ## 5️⃣ Goods Issue (Outbound)

 **Purpose:** Decrease inventory.

 **Sources:**

 * Sales Orders
 * POS Sales
 * Transfers
 * Write-offs

 **Key objects:**

 * Delivery Issues
 * Picking Lists
 * Issue Notes

    ---

    ## 6️⃣ Inventory Transfers

 **Purpose:** Move stock internally.

 **Types:**

 * Warehouse → Warehouse
 * Bin → Bin
 * Store → Store

 **Key objects:**

 * Transfer Orders
 * In-Transit Stock

    ---

    ## 7️⃣ Inventory Adjustments

 **Purpose:** Correct discrepancies.

 **Reasons:**

 * Damage
 * Theft
 * Shrinkage
 * Counting errors

 **Key objects:**

 * Adjustment Documents
 * Reason Codes
 * Approval Workflow

    📌 Strong audit requirement.

    ---

    ## 8️⃣ Cycle Counting & Physical Inventory

 **Purpose:** Stock accuracy.

 **Key objects:**

 * Physical Count Documents
 * Variance Reports
 * Reconciliation Entries

    📌 Essential for compliance and accuracy.

    ---

    ## 9️⃣ Lot / Batch Management

 **Purpose:** Traceability.

 **Used in:**

 * Food
 * Pharma
 * Manufacturing

 **Key objects:**

 * Lot Numbers
 * Expiry Dates
 * Batch History

    ---

    ## 🔟 Serial Number Tracking

 **Purpose:** Individual item traceability.

 **Used for:**

 * Electronics
 * Appliances
 * Assets

 **Key objects:**

 * Serial Numbers
 * Warranty Tracking
 * Ownership History

    ---

    ## 1️⃣1️⃣ Inventory Valuation

 **Purpose:** Financial impact of stock.

 **Methods:**

 * FIFO
 * LIFO
 * Weighted Average
 * Standard Cost

 **Key objects:**

 * Stock Value
 * Cost Layers
 * GL Postings

    📌 Deep integration with Finance.

    ---

    ## 1️⃣2️⃣ Reordering & Stock Planning

 **Purpose:** Prevent stockouts and overstocking.

 **Key objects:**

 * Reorder Levels
 * Safety Stock
 * Min / Max Rules
 * Demand Forecast (optional)

    📌 Feeds into Procurement.

    ---

    ## 1️⃣3️⃣ Inventory Reservations

 **Purpose:** Protect stock for specific orders.

 **Sources:**

 * Sales Orders
 * Production Orders
 * Transfers

    📌 Critical for ERP sales integrity.

    ---

    ## 1️⃣4️⃣ Inventory Reports & Analytics

 **Purpose:** Visibility and control.

 **Reports:**

 * Stock Aging
 * Inventory Turnover
 * Dead Stock
 * Fast / Slow Moving Items
 * Warehouse Utilization

    ---

    # Inventory Module → Integration Map

    | Inventory Sub-Module | Integrates With    |
    | -------------------- | ------------------ |
    | Goods Receipt        | Procurement        |
    | Goods Issue          | Sales / POS        |
    | Valuation            | Finance (GL, COGS) |
    | Reordering           | Procurement        |
    | Serial / Lot         | Sales, Returns     |
    | Transfers            | Logistics          |

    ---

    # High-Level Inventory Flow

    ```
    Item Master
    ↓
    Goods Receipt
    ↓
    Stock On Hand
    ↓
    Reservation
    ↓
    Goods Issue
    ↓
    Valuation Posting
    ```

    ---

    # Architecture Tip (From Your ERP Experience)

    Best practice is to separate:

 * **Inventory Core Service** (stock, reservations)
 * **Warehouse Service** (bins, picking)
 * **Valuation Service** (costing, GL entries)

    Even in a monolith, keep **clear boundaries**.

    ---

    ## Final takeaway

    ✔ Inventory is a **domain**, not a table
    ✔ Every movement is a **document + ledger entry**
    ✔ Accuracy and auditability are more important than speed
    ✔ POS is just another consumer of inventory

    If you want next, I can:

 * Design **Inventory DB schema**
 * Show **event-driven inventory updates**
 * Explain **reservation vs deduction timing**

    Just tell me.
 */

/*// Goods Receipt (Inbound)
      /*4️⃣ Goods Receipt (Inbound)
        Purpose: Actually add stock to inventory - Increase inventory from external sources.
        Sources:
        Purchase Orders
        Customer Returns
        Production Output
        Key objects:
        Goods Receipt Notes (GRN)
        Receiving Inspection
        Partial Receipts
        =====================
        4️⃣ Goods Receipt (Inbound)
          Purpose: Manages the receipt of goods from external sources—suppliers, customers, or even internal
          production outputs. It ensures accurate, timely updates to stock levels.
        Sources:
          Purchase Orders: Goods received based on orders placed with suppliers.
          Customer Returns: Items returned by customers for exchange or refund.
          Production Output: Finished goods produced in-house and added to stock.
        Key Objects:
          Goods Receipt Notes (GRN): Documents used to confirm the receipt of items from suppliers or other sources.
          Receiving Inspection: Process for inspecting goods on arrival for quality and quantity.
          Partial Receipts: Handling of partial shipments from suppliers.
        Why It Matters:
          Without a robust Goods Receipt system, businesses can easily experience inventory discrepancies,
          which could lead to overselling, stockouts, or misplaced goods. Accurate receipt tracking
          ensures inventory levels are updated in real time and that the correct quantities are added.
        What it does:
          Increases on-hand quantity
          Creates stock ledger entries
          Triggers inventory valuation
          Posts accounting entries
          /// NOTE: There'll be Horizonal-tabs under the Goods / Service Receipt tab (for: GRN, SES).*/
      {
        /// Goods Receipt (GR): the BUYER checking the goods delivered by the SUPPLIER to ensure they match
        /// the details of the Purchase Order (PO). The Goods Receipt Note (GRN) is then generated (delivery receipt)
        /// for both the BUYER and the SUPPLIER to SIGN as PROOF that the goods were received correctly and in the expected quantity.
        'hasSplit': true,
        'label': 'Goods / Service Receipt',
        'icon': Icons.assignment_returned,
        'route': RouteNames.items,
        // Temporal Placeholder
        // 'route': RouteNames.goodsReceipt,
        'param': {},
        'access': _getName(InventoryPermission.manageStock),
        // Temporal Placeholder
        // 'access': _getName(InventoryPermission.manageGoodsReceipt),
        'description':
            'Record/stock goods/services from suppliers, returns, or production into inventory.',
      },

      /*5️⃣ Goods Issue (Outbound)
        Purpose: Decrease inventory.
        Sources:
        Sales Orders
        POS Sales
        Transfers
        Write-offs
        Key objects:
        Delivery Issues
        Picking Lists
        Issue Notes

        NOTE: Good Issue databases do NOT duplicate full item master data.
        They store references (foreign keys) + a small snapshot.*/
      {
        'hasSplit': true,
        'label': 'Goods . Issue',
        'icon': Icons.call_made,
        // 'route': RouteNames.goodsIssue,
        'route': RouteNames.items, // Temporal Placeholder
        'param': {},
        // 'access': _getName(InventoryPermission.issueStock),
        'access': _getName(
          InventoryPermission.manageStock,
        ), // Temporal Placeholder
        'description':
            'Release stock for in-store, online sales, POS or internal use.',
      },*/

/*/// Returns a list of Inventory-Dashboard-Tiles based on the Inventory license [inventoryTiles]
  Map<EmployeeRole, List<DashboardTile>> get _rbcInventoryTiles {
    final tilesData = [
      // products tab
      {
        'label': 'stocks',
        'icon': Icons.receipt_long,
        'route': RouteNames.products,
        'param': {},
        'access': InventoryPermission.manageStock.name,
        'description': 'add or create new products to the inventory.',
      },
      // orders tab
      {
        'label': 'orders',
        'icon': Icons.shopping_cart,
        'route': RouteNames.orders,
        'param': {},
        'access': InventoryPermission.manageOrders.name,
        'description':
            'create purchase orders (POs), sales orders (SOs), and miscellaneous orders for suppliers or customers',
      },
      // deliveries tab
      {
        'label': 'deliveries',
        'icon': Icons.delivery_dining,
        'route': RouteNames.deliveries,
        'param': {},
        'access': InventoryPermission.manageDeliveries.name,
        'description':
            'add or create delivery of order(s) and update their status.',
      },
      // sales tab
      {
        'label': 'sales',
        'icon': Icons.shopping_basket,
        'route': RouteNames.sales,
        'param': {},
        'access': InventoryPermission.manageSales.name,
        'description': 'keep track of, and oversee the progress of sales.',
      },
      // credit/debit cards, mobile payments, and cash tabs
      {
        'label': 'payment',
        'icon': Icons.payments_outlined,
        'route': RouteNames.posPayments,
        'param': {},
        'access': InventoryPermission.manageOrders.name,
        'description':
            'records payment details for each transaction: payment method and any related information',
      },
      // finance tab
      {
        'label': 'finance',
        'icon': Icons.money,
        'route': RouteNames.posPayments,
        'param': {},
        'access': InventoryPermission.manageOrders.name,
        'description':
            'Manages & analyzes company\'s financial resources; budgeting, forecasting, investing',
      },
      // invoice tab
      {
        'label': 'invoice',
        'icon': Icons.receipt,
        'route': RouteNames.invoice,
        'param': {},
        'access': InventoryPermission.viewInvoice.name,
        'description':
            'keep history of the creation and processing of receipts',
      },
      // report analytics tab
      {
        'label': 'report - Analytics',
        'icon': Icons.add_chart,
        'route': RouteNames.inventReports,
        'param': {},
        'access': InventoryPermission.viewReport.name,
        'description':
            'generate sales reports, inventory status, turnover rates, forecasts, and performance analytics',
      },
      // tracking tab
      {
        'label': 'tracking',
        'icon': Icons.location_on,
        'route': RouteNames.ordersTracking,
        'param': {},
        'access': InventoryPermission.manageOrders.name,
        'description': 'monitor the progress of order placement and deliveries',
      },
    ];
    final defaultTiles = tilesData
        .map((e) => DashboardTile.fromMap(e))
        .toList();

    final productsTile = defaultTiles[0];
    final ordersTile = defaultTiles[1];
    final deliveriesTile = defaultTiles[2];
    final salesTile = defaultTiles[3];
    final paymentTile = defaultTiles[4];
    final financeTile = defaultTiles[5];
    final invoiceTile = defaultTiles[6];
    final reportAnalyticsTile = defaultTiles[7];

    // Role Based Access Control
    return {
      EmployeeRole.businessOwner: defaultTiles,
      EmployeeRole.manager: defaultTiles,
      EmployeeRole.sale: [salesTile],
      EmployeeRole.developer: defaultTiles,
      EmployeeRole.cashier: [paymentTile],
      EmployeeRole.delivery: [deliveriesTile],
      EmployeeRole.stockControl: [productsTile],
      EmployeeRole.procurement: [ordersTile, invoiceTile],
      EmployeeRole.finance: [
        financeTile,
        salesTile,
        invoiceTile,
        reportAnalyticsTile,
      ],
    };
  }

  Map<EmployeeRole, RoleBasedDashboardTile<EmployeeRole>> get inventoryTiles =>
      DashboardTileManager<EmployeeRole>(tiles: _rbcInventoryTiles).create();*/
