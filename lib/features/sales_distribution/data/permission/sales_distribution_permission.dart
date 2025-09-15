import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';

/// PERMISSION BASED ACCESS-CONTROL
enum SalesDistributionPermission {
  manageSalesDistribution,

  //SOs = Sales Orders
  manageSOs,
  createSO,
  updateSO,
  deleteSO,
  viewSO,
  // Delivery
  manageDeliveries,
  createDelivery,
  updateDelivery,
  deleteDelivery,
  viewDelivery,
  // Invoice
  printInvoice,
  viewInvoice,
  manageTracking,
  // Report
  viewReport,
  viewImsSecrets, // For viewing items IDs
}

final List<AccessControl> _salesDistributionPermissions = [
  AccessControl(
    module: "sales distribution",
    title: "Manage sales distribution",
    description: "Allow users to manage sales and distribution.",
    access: SalesDistributionPermission.manageSalesDistribution,
  ),
];

final List<AccessControl> _salesOrderPermissions = [
  AccessControl(
    module: "sales orders",
    title: "Manage sales orders",
    description: "Allow users to create, edit, and delete sales orders.",
    access: SalesDistributionPermission.manageSOs,
  ),
  AccessControl(
    module: "sales orders",
    title: "Create new sales orders",
    description: "Allow users to process new sales orders at any location.",
    access: SalesDistributionPermission.createSO,
  ),
  AccessControl(
    module: "sales orders",
    title: "View sales orders",
    description: "Allow access to a list of all completed sales orders.",
    access: SalesDistributionPermission.viewSO,
  ),
  AccessControl(
    module: "sales orders",
    title: "Edit existing sales orders",
    description: "Allow users to modify details of an existing sales order.",
    access: SalesDistributionPermission.updateSO,
  ),
  AccessControl(
    module: "sales orders",
    title: "Delete sales orders",
    description: "Allow users to permanently remove a sales order record.",
    access: SalesDistributionPermission.deleteSO,
  ),
];

final List<AccessControl> _deliveryPermissions = [
  AccessControl(
    module: "delivery",
    title: "Manage deliveries",
    description: "Allow users to create, edit, and delete deliveries.",
    access: SalesDistributionPermission.manageDeliveries,
  ),
  AccessControl(
    module: "delivery",
    title: "View delivery records",
    description: "Allow access to a list of all completed deliveries.",
    access: SalesDistributionPermission.viewDelivery,
  ),
  AccessControl(
    module: "delivery",
    title: "Create new deliveries",
    description: "Allow users to process new deliveries at any location.",
    access: SalesDistributionPermission.createDelivery,
  ),
  AccessControl(
    module: "delivery",
    title: "Edit existing deliveries",
    description: "Allow users to modify details of an existing delivery.",
    access: SalesDistributionPermission.updateDelivery,
  ),
  AccessControl(
    module: "delivery",
    title: "Delete deliveries",
    description: "Allow users to permanently remove a delivery record.",
    access: SalesDistributionPermission.deleteDelivery,
  ),
];

final List<AccessControl> _trackingPermissions = [
  AccessControl(
    module: "tracking",
    title: "Manage tracking",
    description: "Allow users to create, edit, and delete tracking records.",
    access: SalesDistributionPermission.manageTracking,
  ),
];

final List<AccessControl> _metricsPermissions = [
  AccessControl(
    module: "metrics",
    title: "Print Invoices",
    description: "Allow users to view customer invoices and print copies.",
    access: SalesDistributionPermission.printInvoice,
  ),
  AccessControl(
    module: "metrics",
    title: "View financial data",
    description: "Allow access to financial reports and summaries.",
    access: SalesDistributionPermission.viewInvoice,
  ),
  AccessControl(
    module: "metrics",
    title: "Access reports and analytics",
    description: "Allow users to access sales, order, and product reports.",
    access: SalesDistributionPermission.viewReport,
  ),
];

final List<AccessControl> _secretPermissions = [
  AccessControl(
    module: "Secrets",
    title: "View Item IDs",
    description: "Allow users to view the reference numbers or IDs of items.",
    access: SalesDistributionPermission.viewImsSecrets,
  ),
];

final salesDistributionDisplayName = 'sales and distribution';

final List<AccessControl> salesDistributionPermissions = [
  ..._salesDistributionPermissions,
  ..._salesOrderPermissions,
  ..._deliveryPermissions,
  ..._trackingPermissions,
  ..._metricsPermissions,
  ..._secretPermissions,
];
