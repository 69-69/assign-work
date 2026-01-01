import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/features/inventory_ims/data/permission/inventory_permission.dart';
import 'package:flutter/material.dart';

/// Inventory Management System App(IMS) Dashboard tiles [InventoryTiles]
extension InventoryTiles on dynamic {
  /// Sub Menu Tiles under orders tab
  List<DashboardTile> get ordersTiles {
    final tilesData = [
      {
        'hasSplit': true,
        'label': 'sales . order',
        'icon': Icons.trending_up,
        'action': RouteNames.salesOrders,
        'param': {},
        'access': _getName(InventoryPermission.manageSOs),
        'description': 'Create orders for customers or clients',
      },
      {
        'hasSplit': true,
        'label': 'purchase . order',
        'icon': Icons.paypal,
        'action': RouteNames.imsPurchaseOrders,
        'param': {},
        'access': _getName(InventoryPermission.managePOs),
        'description': 'generate POs to suppliers to request goods or services',
      },
    ];

    return tilesData.map((e) => DashboardTile.fromMap(e)).toList();
  }

  /// Sub Menu Tiles under Inventory Dashboard
  List<DashboardTile> get inventoryTiles {
    final tilesData = [
      /// NEW Modules (These will be added)
      /*1️⃣ Item / Product Master
          Purpose: Central definition of everything that can be stocked.
          Key objects:
          Items / Products
          Item Categories
          Units of Measure (UOM)
          Barcodes / SKUs
          Variants (size, color, model)
          Lot / Serial tracking flags
        📌 Shared across Sales, Procurement, POS, Manufacturing.
        =========================
        1️⃣ Item / Product Master
          Purpose: This module acts as the central repository for defining and categorizing all items/products that are stocked, sold, or procured. It’s essential for standardizing product information across all other ERP modules.
        Key Objects:
          Items / Products: Defines each individual item in the system.
          Item Categories: Groups products by type (e.g., electronics, furniture, raw materials).
          Units of Measure (UOM): Defines how items are measured (e.g., pieces, kilograms, liters).
          Barcodes / SKUs: Unique identifiers for easy tracking and sales processing.
          Variants: Variations of a product like size, color, or model (e.g., “T-shirt (Large, Red)”).
          Lot / Serial Tracking Flags: Helps track inventory at a lot or serial number level for high-value or regulated items.
        Shared Across:
          Sales: Products defined here show up in catalogs and sales orders.
          Procurement: Products managed here are ordered and tracked.
          POS (Point of Sale): Items are identified and sold through POS systems.
          Manufacturing: Products can be raw materials or finished goods.
          Finance: Product costs and inventory valuation affect financial reporting.

        =========================
        /// NOTE: There'll be Horizonal-tabs under the Item/Product Master tab (for: Items Stocking, Expiry, Warranty start/end).
        */
      {
        'hasSplit': true,
        'label': 'Item . Master',
        'icon': Icons.inventory_2,
        'action': RouteNames.items,
        'param': {},
        'access': _getName(InventoryPermission.manageStock),
        'description':
            'Create, update, and manage inventory, SKUs, and attributes.',
      },
      /* 2️⃣ Stock Management
          Purpose: Real-time stock control.
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
          procurement by providing real-time visibility into what’s actually available and what’s already committed elsewhere in the system.*/
      {
        'hasSplit': true,
        'label': 'Stock . Management',
        'icon': Icons.receipt_long,
        'action': RouteNames.items, // Temporal Placeholder
        // 'action': RouteNames.stockOnHand,
        'param': {},
        'access': _getName(InventoryPermission.viewStock),
        'description': 'View available, reserved, and total stock quantities.',
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
        'label': 'Warehouses',
        'icon': Icons.warehouse,
        'action': RouteNames.warehouseProducts,
        'param': {},
        'access': _getName(
          InventoryPermission.manageStock,
        ), // Temporal Placeholder
        // 'access': _getName(InventoryPermission.manageWarehouses),
        'description': 'Manage warehouses, bins, racks, and storage locations.',
      },

      // Goods Receipt (Inbound)
      /*4️⃣ Goods Receipt (Inbound)
        Purpose: Increase inventory from external sources.
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

          /// NOTE: There'll be Horizonal-tabs under the Goods / Service Receipt tab (for: GRN, SES).*/
      {
        /// Goods Receipt (GR): the BUYER checking the goods delivered by the SUPPLIER to ensure they match
        /// the details of the Purchase Order (PO). The Goods Receipt Note (GRN) is then generated (delivery receipt)
        /// for both the BUYER and the SUPPLIER to SIGN as PROOF that the goods were received correctly and in the expected quantity.
        'hasSplit': true,
        'label': 'Goods / Service Receipt',
        'icon': Icons.assignment_returned,
        'action': RouteNames.items,
        // Temporal Placeholder
        // 'action': RouteNames.goodsReceipt,
        'param': {},
        'access': _getName(InventoryPermission.manageStock),
        // Temporal Placeholder
        // 'access': _getName(InventoryPermission.manageGoodsReceipt),
        'description':
            'Record goods/services from suppliers, returns, or production into inventory.',
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
        // 'action': RouteNames.goodsIssue,
        'action': RouteNames.items, // Temporal Placeholder
        'param': {},
        // 'access': _getName(InventoryPermission.issueStock),
        'access': _getName(
          InventoryPermission.manageStock,
        ), // Temporal Placeholder
        'description':
            'Release stock for in-store, online sales, POS or internal use.',
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
        // 'action': RouteNames.inventoryReports,
        'action': RouteNames.items,
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
        'action': RouteNames.items,
        'param': {},
        'access': _getName(InventoryPermission.manageStock),
        'description': 'add or create new items to the inventory.',
      },
      // orders tab
      {
        'label': 'orders',
        'icon': Icons.shopping_cart,
        'action': RouteNames.orders,
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
        'action': RouteNames.miscOrders,
        'param': {},
        'access': _getName(InventoryPermission.manageMOs),
        'description':
            'create additional orders that may include special requests, one-time purchases',
      },
      /*{
        'label': 'Item Categories',
        'icon': Icons.dashboard_customize_outlined,
        'action': RouteNames.itemCategories,
        'param': {},
        'access': _getName(InventoryPermission.manageItemCategory),
        'description':
            'Organize items into categories for easier tracking and reporting.',
      },
      {
        'label': 'Item Suppliers',
        'icon': Icons.local_shipping,
        'action': RouteNames.itemSuppliers,
        'param': {},
        'access': _getName(InventoryPermission.manageItemSuppliers),
        'description':
            'Manage suppliers linked to specific items for sourcing and restocking.',
      },*/
      // deliveries tab
      {
        'label': 'deliveries',
        'icon': Icons.delivery_dining,
        'action': RouteNames.deliveries,
        'param': {},
        'access': _getName(InventoryPermission.manageDeliveries),
        'description':
            'add or create delivery of order(s) and update their status.',
      },
      // sales tab
      {
        'label': 'sales',
        'icon': Icons.shopping_basket,
        'action': RouteNames.sales,
        'param': {},
        'access': _getName(InventoryPermission.manageSales),
        'description': 'keep track of, and oversee the progress of sales.',
      },
      // credit/debit cards, mobile payments, and cash tabs
      {
        'label': 'payment',
        'icon': Icons.payments_outlined,
        'action': RouteNames.posPayments,
        'param': {},
        'access': _getName(InventoryPermission.manageOrders),
        'description':
            'records payment details for each transaction: payment method and any related information',
      },
      // finance tab
      {
        'label': 'finance',
        'icon': Icons.money,
        'action': RouteNames.posPayments,
        'param': {},
        'access': _getName(InventoryPermission.manageOrders),
        'description':
            'Manages & analyzes company\'s financial resources; budgeting, forecasting, investing',
      },
      // invoice tab
      {
        'label': 'invoice',
        'icon': Icons.receipt,
        'action': RouteNames.invoice,
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
        'action': RouteNames.inventReports,
        'param': {},
        'access': _getName(InventoryPermission.viewReport),
        'description':
            'generate sales reports, inventory status, turnover rates, forecasts, and performance analytics',
      },
      // tracking tab
      {
        'label': 'tracking',
        'icon': Icons.location_on,
        'action': RouteNames.ordersTracking,
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
String _getName(e) => EnumHelper<InventoryPermission>(e).getName;

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

/*/// Returns a list of Inventory-Dashboard-Tiles based on the Inventory license [inventoryTiles]
  Map<EmployeeRole, List<DashboardTile>> get _rbcInventoryTiles {
    final tilesData = [
      // products tab
      {
        'label': 'stocks',
        'icon': Icons.receipt_long,
        'action': RouteNames.products,
        'param': {},
        'access': InventoryPermission.manageStock.name,
        'description': 'add or create new products to the inventory.',
      },
      // orders tab
      {
        'label': 'orders',
        'icon': Icons.shopping_cart,
        'action': RouteNames.orders,
        'param': {},
        'access': InventoryPermission.manageOrders.name,
        'description':
            'create purchase orders (POs), sales orders (SOs), and miscellaneous orders for suppliers or customers',
      },
      // deliveries tab
      {
        'label': 'deliveries',
        'icon': Icons.delivery_dining,
        'action': RouteNames.deliveries,
        'param': {},
        'access': InventoryPermission.manageDeliveries.name,
        'description':
            'add or create delivery of order(s) and update their status.',
      },
      // sales tab
      {
        'label': 'sales',
        'icon': Icons.shopping_basket,
        'action': RouteNames.sales,
        'param': {},
        'access': InventoryPermission.manageSales.name,
        'description': 'keep track of, and oversee the progress of sales.',
      },
      // credit/debit cards, mobile payments, and cash tabs
      {
        'label': 'payment',
        'icon': Icons.payments_outlined,
        'action': RouteNames.posPayments,
        'param': {},
        'access': InventoryPermission.manageOrders.name,
        'description':
            'records payment details for each transaction: payment method and any related information',
      },
      // finance tab
      {
        'label': 'finance',
        'icon': Icons.money,
        'action': RouteNames.posPayments,
        'param': {},
        'access': InventoryPermission.manageOrders.name,
        'description':
            'Manages & analyzes company\'s financial resources; budgeting, forecasting, investing',
      },
      // invoice tab
      {
        'label': 'invoice',
        'icon': Icons.receipt,
        'action': RouteNames.invoice,
        'param': {},
        'access': InventoryPermission.viewInvoice.name,
        'description':
            'keep history of the creation and processing of receipts',
      },
      // report analytics tab
      {
        'label': 'report - Analytics',
        'icon': Icons.add_chart,
        'action': RouteNames.inventReports,
        'param': {},
        'access': InventoryPermission.viewReport.name,
        'description':
            'generate sales reports, inventory status, turnover rates, forecasts, and performance analytics',
      },
      // tracking tab
      {
        'label': 'tracking',
        'icon': Icons.location_on,
        'action': RouteNames.ordersTracking,
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
