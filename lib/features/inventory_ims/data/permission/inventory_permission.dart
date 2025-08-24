import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';

/// PERMISSION BASED ACCESS-CONTROL
/*enum InventoryPermission {
  viewItems,
  addItem,
  editItem,
  deleteItem,
  adjustStock,
  transferStock,
  viewStockLevels,
  viewInventoryHistory,
  exportInventoryData,
  manageInventorySettings,
}
*/
enum InventoryPermission {
  manageInventory,
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
  // RFQs = Request for Quotation
  manageRFQs,
  createRFQ,
  viewRFQ,
  updateRFQ,
  deleteRFQ,
  // Item Category
  manageItemCategory,
  // Item Suppliers/Vendors
  manageItemSuppliers,
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
    module: "ims sales",
    title: "Manage sales",
    description: "Allow users to create, edit, and delete sales.",
    access: InventoryPermission.manageSales,
  ),
  AccessControl(
    module: "ims sales",
    title: "Create new sales",
    description: "Allow users to process new sales at any location.",
    access: InventoryPermission.createSale,
  ),
  AccessControl(
    module: "ims sales",
    title: "View sales records",
    description: "Allow access to a list of all completed sales.",
    access: InventoryPermission.viewSale,
  ),
  AccessControl(
    module: "ims sales",
    title: "Edit existing sales",
    description: "Allow users to modify details of an existing sale.",
    access: InventoryPermission.updateSale,
  ),
  AccessControl(
    module: "ims sales",
    title: "Delete sales",
    description: "Allow users to permanently remove a sale record.",
    access: InventoryPermission.deleteSale,
  ),
];

final List<AccessControl> _ordersPermissions = [
  AccessControl(
    module: "ims orders",
    title: "Manage orders",
    description: "Allow users to create, edit, and delete all orders.",
    access: InventoryPermission.manageOrders,
  ),
];

final List<AccessControl> _salesOrderPermissions = [
  AccessControl(
    module: "ims sales orders",
    title: "Manage sales orders",
    description: "Allow users to create, edit, and delete sales orders.",
    access: InventoryPermission.manageSOs,
  ),
  AccessControl(
    module: "ims sales orders",
    title: "Create new sales orders",
    description: "Allow users to process new sales orders at any location.",
    access: InventoryPermission.createSO,
  ),
  AccessControl(
    module: "ims sales orders",
    title: "View sales orders",
    description: "Allow access to a list of all completed sales orders.",
    access: InventoryPermission.viewSO,
  ),
  AccessControl(
    module: "ims sales orders",
    title: "Edit existing sales orders",
    description: "Allow users to modify details of an existing sales order.",
    access: InventoryPermission.updateSO,
  ),
  AccessControl(
    module: "ims sales orders",
    title: "Delete sales orders",
    description: "Allow users to permanently remove a sales order record.",
    access: InventoryPermission.deleteSO,
  ),
];

final List<AccessControl> _purchaseOrderPermissions = [
  AccessControl(
    module: "ims purchase orders",
    title: "Manage purchase orders",
    description: "Allow users to create, edit, and delete purchase orders.",
    access: InventoryPermission.managePOs,
  ),
  AccessControl(
    module: "ims purchase orders",
    title: "Create new purchase orders",
    description: "Allow users to process new purchase orders at any location.",
    access: InventoryPermission.createPO,
  ),
  AccessControl(
    module: "ims purchase orders",
    title: "View purchase orders",
    description: "Allow access to a list of all completed purchase orders.",
    access: InventoryPermission.viewPO,
  ),
  AccessControl(
    module: "ims purchase orders",
    title: "Edit existing purchase orders",
    description: "Allow users to modify details of an existing purchase order.",
    access: InventoryPermission.updatePO,
  ),
  AccessControl(
    module: "ims purchase orders",
    title: "Delete purchase orders",
    description: "Allow users to permanently remove a purchase order record.",
    access: InventoryPermission.deletePO,
  ),
];

final List<AccessControl> _miscOrderPermissions = [
  AccessControl(
    module: "ims misc orders",
    title: "Manage misc orders",
    description: "Allow users to create, edit, and delete misc orders.",
    access: InventoryPermission.manageMOs,
  ),
  AccessControl(
    module: "ims misc orders",
    title: "Create new misc orders",
    description: "Allow users to process new misc orders at any location.",
    access: InventoryPermission.createMO,
  ),
  AccessControl(
    module: "ims misc orders",
    title: "View misc orders",
    description: "Allow access to a list of all completed misc orders.",
    access: InventoryPermission.viewMO,
  ),
  AccessControl(
    module: "ims misc orders",
    title: "Edit existing misc orders",
    description: "Allow users to modify details of an existing misc order.",
    access: InventoryPermission.updateMO,
  ),
  AccessControl(
    module: "ims misc orders",
    title: "Delete misc orders",
    description: "Allow users to permanently remove a misc order record.",
    access: InventoryPermission.deleteMO,
  ),
];

final List<AccessControl> _requestForQuotePermissions = [
  AccessControl(
    module: "ims request for quotes",
    title: "Manage request for quotes",
    description: "Allow users to create, edit, and delete request for quotes.",
    access: InventoryPermission.manageRFQs,
  ),
  AccessControl(
    module: "ims request for quotes",
    title: "Create new request for quotes",
    description:
        "Allow users to process new request for quotes at any location.",
    access: InventoryPermission.createRFQ,
  ),
  AccessControl(
    module: "ims request for quotes",
    title: "View request for quotes",
    description: "Allow access to a list of all completed request for quotes.",
    access: InventoryPermission.viewRFQ,
  ),
  AccessControl(
    module: "ims request for quotes",
    title: "Edit existing request for quotes",
    description:
        "Allow users to modify details of an existing request for quote.",
    access: InventoryPermission.updateRFQ,
  ),
  AccessControl(
    module: "ims request for quotes",
    title: "Delete request for quotes",
    description:
        "Allow users to permanently remove a request for quote record.",
    access: InventoryPermission.deleteRFQ,
  ),
];

final List<AccessControl> _customersPermissions = [
  AccessControl(
    module: "ims customers",
    title: "Manage customers",
    description: "Allow users to create, edit, and delete customers.",
    access: InventoryPermission.manageCustomers,
  ),
  AccessControl(
    module: "ims customers",
    title: "View customers",
    description:
        "Allow access to customer lists, profiles, and contact details.",
    access: InventoryPermission.viewCustomer,
  ),
  AccessControl(
    module: "ims customers",
    title: "Add new customers",
    description: "Allow users to create new customer records.",
    access: InventoryPermission.createCustomer,
  ),
  AccessControl(
    module: "ims customers",
    title: "Edit customer information",
    description: "Allow updates to customer contact info, tags, and notes.",
    access: InventoryPermission.updateCustomer,
  ),
  AccessControl(
    module: "ims customers",
    title: "Delete customers",
    description: "Allow permanent removal of customer records from the system.",
    access: InventoryPermission.deleteCustomer,
  ),
];

final List<AccessControl> _stockPermissions = [
  AccessControl(
    module: "ims stock",
    title: "Manage inventory",
    description: "Allow users to create, edit, and delete inventory items.",
    access: InventoryPermission.manageStock,
  ),
  AccessControl(
    module: "ims stock",
    title: "View inventory",
    description:
        "Allow access to inventory items, stock levels, and product details.",
    access: InventoryPermission.viewStock,
  ),
  AccessControl(
    module: "ims stock",
    title: "Add new inventory items",
    description: "Allow users to create new products or stock items.",
    access: InventoryPermission.createStock,
  ),
  AccessControl(
    module: "ims stock",
    title: "Edit inventory items",
    description: "Allow users to update item names, prices, or stock details.",
    access: InventoryPermission.updateStock,
  ),
  AccessControl(
    module: "ims stock",
    title: "Delete inventory items",
    description: "Allow users to remove items from the inventory database.",
    access: InventoryPermission.deleteStock,
  ),
];

final List<AccessControl> _deliveryPermissions = [
  AccessControl(
    module: "ims delivery",
    title: "Manage deliveries",
    description: "Allow users to create, edit, and delete deliveries.",
    access: InventoryPermission.manageDeliveries,
  ),
  AccessControl(
    module: "ims delivery",
    title: "View delivery records",
    description: "Allow access to a list of all completed deliveries.",
    access: InventoryPermission.viewDelivery,
  ),
  AccessControl(
    module: "ims delivery",
    title: "Create new deliveries",
    description: "Allow users to process new deliveries at any location.",
    access: InventoryPermission.createDelivery,
  ),
  AccessControl(
    module: "ims delivery",
    title: "Edit existing deliveries",
    description: "Allow users to modify details of an existing delivery.",
    access: InventoryPermission.updateDelivery,
  ),
  AccessControl(
    module: "ims delivery",
    title: "Delete deliveries",
    description: "Allow users to permanently remove a delivery record.",
    access: InventoryPermission.deleteDelivery,
  ),
];

final List<AccessControl> _metricsPermissions = [
  AccessControl(
    module: "ims metrics",
    title: "Print Invoices",
    description: "Allow users to view customer invoices and print copies.",
    access: InventoryPermission.printInvoice,
  ),
  AccessControl(
    module: "ims metrics",
    title: "View financial data",
    description: "Allow access to financial reports and summaries.",
    access: InventoryPermission.viewInvoice,
  ),
  AccessControl(
    module: "ims metrics",
    title: "Access reports and analytics",
    description: "Allow users to access sales, order, and product reports.",
    access: InventoryPermission.viewReport,
  ),
];

final List<AccessControl> _secretPermissions = [
  AccessControl(
    module: "IMS Secrets",
    title: "View Item IDs",
    description: "Allow users to view the reference numbers or IDs of items.",
    access: InventoryPermission.viewImsSecrets,
  ),
];

final inventoryDisplayName = 'inventory';

final List<AccessControl> inventoryPermissions = [
  ..._inventoryPermissions,
  ..._stockPermissions,
  ..._ordersPermissions,
  ..._salesPermissions,
  ..._salesOrderPermissions,
  ..._purchaseOrderPermissions,
  ..._miscOrderPermissions,
  ..._requestForQuotePermissions,
  ..._deliveryPermissions,
  ..._customersPermissions,
  ..._metricsPermissions,
  ..._secretPermissions,
];

/* can I use PageStorage to store user permissions...
NOTE: for security issues I don't want to persist
permissions in local storage so user can manipulate the data */
