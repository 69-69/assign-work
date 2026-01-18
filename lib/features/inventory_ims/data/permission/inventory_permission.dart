import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';

/// PERMISSION BASED ACCESS-CONTROL
enum InventoryPermission {
  manageInventory,
  // Warehouse Management System
  manageWarehouse,
  manageWarehouseAddress,
  manageWHLocation,
  manageWHBin,
  manageWHReceiving,
  manageWHMovement,
  manageWHPickShipping,

  // Stock Management
  manageGoodsIssue,
  manageGoodsReceipt,
  manageServiceReceipt,
  manageStockTransfer,
  manageStockAdjustment,
  manageReserveStocks,
  manageReturns,

  // Stock/Product
  manageStock,
  createStock,
  updateStock,
  deleteStock,
  viewStock,
  // Sale
  manageSales,
  createSale,
  updateSale,
  deleteSale,
  viewSale,
  // Orders = High Level Orders
  manageOrders,
  //SOs = Sales Orders
  manageSOs,
  createSO,
  updateSO,
  deleteSO,
  viewSO,
  //POs = Purchase Orders
  managePOs,
  createPO,
  updatePO,
  deletePO,
  viewPO,
  //MOs = Misc Orders
  manageMOs,
  createMO,
  viewMO,
  updateMO,
  deleteMO,
  // Item Category
  // manageItemCategory,
  // Item Suppliers/Vendors
  // manageItemSuppliers,
  // Customer
  manageCustomers,
  createCustomer,
  viewCustomer,
  updateCustomer,
  deleteCustomer,
  // Delivery
  manageDeliveries,
  createDelivery,
  updateDelivery,
  deleteDelivery,
  viewDelivery,
  // Invoice
  printInvoice,
  viewInvoice,
  // Report
  viewReport,
  viewImsSecrets, // For viewing items IDs
}

final List<AccessControl> _warehousePermissions = [
  // ───────────── Master Data ─────────────
  AccessControl(
    module: "warehouse",
    title: "Manage Warehouse",
    description:
        "Create, edit, and delete warehouse systems for inventory management.",
    access: InventoryPermission.manageWarehouse,
  ),
  AccessControl(
    module: "warehouse",
    title: "Manage Warehouse addresses",
    description:
        "Create, edit, and deactivate warehouses used for inventory storage and operations.",
    access: InventoryPermission.manageWarehouseAddress,
  ),
  AccessControl(
    module: "warehouse",
    title: "Manage Warehouse Locations",
    description:
        "Create, edit, and manage storage locations such as racks, aisles, or shelves within a warehouse.",
    access: InventoryPermission.manageWHLocation,
  ),
  AccessControl(
    module: "warehouse",
    title: "Manage Warehouse Bins",
    description:
        "Create, edit, and manage individual storage bins within warehouse locations.",
    access: InventoryPermission.manageWHBin,
  ),

  // ───────────── Inbound Operations ─────────────
  AccessControl(
    module: "warehouse",
    title: "Execute Receiving",
    description:
        "Receive inbound goods from purchase orders and assign them to warehouse locations or bins.",
    access: InventoryPermission.manageWHReceiving,
  ),

  // ───────────── Internal Operations ─────────────
  AccessControl(
    module: "warehouse",
    title: "Execute Internal Movements",
    description:
        "Move inventory internally between locations or bins within the same warehouse.",
    access: InventoryPermission.manageWHMovement,
  ),

  // ───────────── Outbound Operations ─────────────
  AccessControl(
    module: "warehouse",
    title: "Execute Picking & Shipping",
    description:
        "Pick, pack, and ship goods from the warehouse to fulfill sales orders or transfer requests.",
    access: InventoryPermission.manageWHPickShipping,
  ),
];

final List<AccessControl> _stockManagementPermissions = [
  AccessControl(
    module: "goods issue",
    title: "Manage Goods Issue",
    description:
        "Create and post goods issue transactions to remove inventory for sales, production, transfers, or internal use.",
    access: InventoryPermission.manageGoodsIssue,
  ),
  AccessControl(
    module: "goods receipt",
    title: "Manage Goods Receipt",
    description:
        "Create and post goods receipt transactions to add received items into inventory.",
    access: InventoryPermission.manageGoodsReceipt,
  ),
  AccessControl(
    module: "service receipt",
    title: "Manage Service Entry",
    description:
        "Record and approve vendor service completion without affecting inventory stock levels.",
    access: InventoryPermission.manageServiceReceipt,
  ),
  AccessControl(
    module: "stock transfer",
    title: "Manage Stock Transfer",
    description:
        "Create and post stock transfer transactions to move inventory from one location to another.",
    access: InventoryPermission.manageStockTransfer,
  ),
  AccessControl(
    module: "stock adjustment",
    title: "Manage Stock Adjustment",
    description: "Create and post stock adjustment transactions.",
    access: InventoryPermission.manageStockAdjustment,
  ),
  AccessControl(
    module: "reserve stocks",
    title: "Manage Stock Reservations",
    description:
        "Reserve inventory quantities to control availability for outbound transactions.",
    access: InventoryPermission.manageReserveStocks,
  ),
  AccessControl(
    module: "returns from customers",
    title: "Manage Returns",
    description:
        "Process customer returns and adjust inventory balances accordingly.",
    access: InventoryPermission.manageReturns,
  ),
];

final List<AccessControl> _inventoryPermissions = [
  AccessControl(
    module: "inventory",
    title: "Manage inventory",
    description: "Allow users to create, edit, and delete inventory items.",
    access: InventoryPermission.manageInventory,
  ),
];

final List<AccessControl> _salesPermissions = [
  // Sales
  AccessControl(
    module: "sales",
    title: "Manage sales",
    description: "Allow users to create, edit, and delete sales.",
    access: InventoryPermission.manageSales,
  ),
  AccessControl(
    module: "sales",
    title: "Create new sales",
    description: "Allow users to process new sales at any location.",
    access: InventoryPermission.createSale,
  ),
  AccessControl(
    module: "sales",
    title: "View sales records",
    description: "Allow access to a list of all completed sales.",
    access: InventoryPermission.viewSale,
  ),
  AccessControl(
    module: "sales",
    title: "Edit existing sales",
    description: "Allow users to modify details of an existing sale.",
    access: InventoryPermission.updateSale,
  ),
  AccessControl(
    module: "sales",
    title: "Delete sales",
    description: "Allow users to permanently remove a sale record.",
    access: InventoryPermission.deleteSale,
  ),
];

final List<AccessControl> _ordersPermissions = [
  AccessControl(
    module: "orders",
    title: "Manage orders",
    description: "Allow users to create, edit, and delete all orders.",
    access: InventoryPermission.manageOrders,
  ),
];

final List<AccessControl> _salesOrderPermissions = [
  AccessControl(
    module: "sales orders",
    title: "Manage sales orders",
    description: "Allow users to create, edit, and delete sales orders.",
    access: InventoryPermission.manageSOs,
  ),
  AccessControl(
    module: "sales orders",
    title: "Create new sales orders",
    description: "Allow users to process new sales orders at any location.",
    access: InventoryPermission.createSO,
  ),
  AccessControl(
    module: "sales orders",
    title: "View sales orders",
    description: "Allow access to a list of all completed sales orders.",
    access: InventoryPermission.viewSO,
  ),
  AccessControl(
    module: "sales orders",
    title: "Edit existing sales orders",
    description: "Allow users to modify details of an existing sales order.",
    access: InventoryPermission.updateSO,
  ),
  AccessControl(
    module: "sales orders",
    title: "Delete sales orders",
    description: "Allow users to permanently remove a sales order record.",
    access: InventoryPermission.deleteSO,
  ),
];

final List<AccessControl> _purchaseOrderPermissions = [
  AccessControl(
    module: "purchase orders",
    title: "Manage purchase orders",
    description: "Allow users to create, edit, and delete purchase orders.",
    access: InventoryPermission.managePOs,
  ),
  AccessControl(
    module: "purchase orders",
    title: "Create new purchase orders",
    description: "Allow users to process new purchase orders at any location.",
    access: InventoryPermission.createPO,
  ),
  AccessControl(
    module: "purchase orders",
    title: "View purchase orders",
    description: "Allow access to a list of all completed purchase orders.",
    access: InventoryPermission.viewPO,
  ),
  AccessControl(
    module: "purchase orders",
    title: "Edit existing purchase orders",
    description: "Allow users to modify details of an existing purchase order.",
    access: InventoryPermission.updatePO,
  ),
  AccessControl(
    module: "purchase orders",
    title: "Delete purchase orders",
    description: "Allow users to permanently remove a purchase order record.",
    access: InventoryPermission.deletePO,
  ),
];

final List<AccessControl> _miscOrderPermissions = [
  AccessControl(
    module: "misc orders",
    title: "Manage misc orders",
    description: "Allow users to create, edit, and delete misc orders.",
    access: InventoryPermission.manageMOs,
  ),
  AccessControl(
    module: "misc orders",
    title: "Create new misc orders",
    description: "Allow users to process new misc orders at any location.",
    access: InventoryPermission.createMO,
  ),
  AccessControl(
    module: "misc orders",
    title: "View misc orders",
    description: "Allow access to a list of all completed misc orders.",
    access: InventoryPermission.viewMO,
  ),
  AccessControl(
    module: "misc orders",
    title: "Edit existing misc orders",
    description: "Allow users to modify details of an existing misc order.",
    access: InventoryPermission.updateMO,
  ),
  AccessControl(
    module: "misc orders",
    title: "Delete misc orders",
    description: "Allow users to permanently remove a misc order record.",
    access: InventoryPermission.deleteMO,
  ),
];

final List<AccessControl> _customersPermissions = [
  AccessControl(
    module: "customers",
    title: "Manage customers",
    description: "Allow users to create, edit, and delete customers.",
    access: InventoryPermission.manageCustomers,
  ),
  AccessControl(
    module: "customers",
    title: "View customers",
    description:
        "Allow access to customer lists, profiles, and contact details.",
    access: InventoryPermission.viewCustomer,
  ),
  AccessControl(
    module: "customers",
    title: "Add new customers",
    description: "Allow users to create new customer records.",
    access: InventoryPermission.createCustomer,
  ),
  AccessControl(
    module: "customers",
    title: "Edit customer information",
    description: "Allow updates to customer contact info, tags, and notes.",
    access: InventoryPermission.updateCustomer,
  ),
  AccessControl(
    module: "customers",
    title: "Delete customers",
    description: "Allow permanent removal of customer records from the system.",
    access: InventoryPermission.deleteCustomer,
  ),
];

final List<AccessControl> _stockPermissions = [
  AccessControl(
    module: "stock management",
    title: "Manage inventory",
    description: "Allow users to create, edit, and delete inventory items.",
    access: InventoryPermission.manageStock,
  ),
  AccessControl(
    module: "stock",
    title: "View inventory",
    description:
        "Allow access to inventory items, stock levels, and product details.",
    access: InventoryPermission.viewStock,
  ),
  AccessControl(
    module: "stock",
    title: "Add new inventory items",
    description: "Allow users to create new products or stock items.",
    access: InventoryPermission.createStock,
  ),
  AccessControl(
    module: "stock",
    title: "Edit inventory items",
    description: "Allow users to update item names, prices, or stock details.",
    access: InventoryPermission.updateStock,
  ),
  AccessControl(
    module: "stock",
    title: "Delete inventory items",
    description: "Allow users to remove items from the inventory database.",
    access: InventoryPermission.deleteStock,
  ),
];

final List<AccessControl> _deliveryPermissions = [
  AccessControl(
    module: "delivery",
    title: "Manage deliveries",
    description: "Allow users to create, edit, and delete deliveries.",
    access: InventoryPermission.manageDeliveries,
  ),
  AccessControl(
    module: "delivery",
    title: "View delivery records",
    description: "Allow access to a list of all completed deliveries.",
    access: InventoryPermission.viewDelivery,
  ),
  AccessControl(
    module: "delivery",
    title: "Create new deliveries",
    description: "Allow users to process new deliveries at any location.",
    access: InventoryPermission.createDelivery,
  ),
  AccessControl(
    module: "delivery",
    title: "Edit existing deliveries",
    description: "Allow users to modify details of an existing delivery.",
    access: InventoryPermission.updateDelivery,
  ),
  AccessControl(
    module: "delivery",
    title: "Delete deliveries",
    description: "Allow users to permanently remove a delivery record.",
    access: InventoryPermission.deleteDelivery,
  ),
];

final List<AccessControl> _metricsPermissions = [
  AccessControl(
    module: "metrics",
    title: "Print Invoices",
    description: "Allow users to view customer invoices and print copies.",
    access: InventoryPermission.printInvoice,
  ),
  AccessControl(
    module: "metrics",
    title: "View financial data",
    description: "Allow access to financial reports and summaries.",
    access: InventoryPermission.viewInvoice,
  ),
  AccessControl(
    module: "metrics",
    title: "Access reports and analytics",
    description: "Allow users to access sales, order, and product reports.",
    access: InventoryPermission.viewReport,
  ),
];

final List<AccessControl> _secretPermissions = [
  AccessControl(
    module: "Secrets",
    title: "View Item IDs",
    description: "Allow users to view the reference numbers or IDs of items.",
    access: InventoryPermission.viewImsSecrets,
  ),
];

final inventoryDisplayName = 'inventory';

final List<AccessControl> inventoryPermissions = [
  ..._inventoryPermissions,
  ..._warehousePermissions,
  ..._stockManagementPermissions,
  ..._stockPermissions,
  ..._ordersPermissions,
  ..._salesPermissions,
  ..._salesOrderPermissions,
  ..._purchaseOrderPermissions,
  ..._miscOrderPermissions,
  ..._deliveryPermissions,
  ..._customersPermissions,
  ..._metricsPermissions,
  ..._secretPermissions,
];

/* can I use PageStorage to store user permissions...
NOTE: for security issues I don't want to persist
permissions in local storage so user can manipulate the data */
