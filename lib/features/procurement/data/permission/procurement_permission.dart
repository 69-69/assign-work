import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';

/// PERMISSION BASED ACCESS-CONTROL
enum ProcurementPermission {
  manageProcurement,
  // PR = Purchase Requisition
  managePRs,
  createPR,
  viewPR,
  updatePR,
  deletePR,
  approvePR,
  rejectPR,
  // RFQs = Request for Quotation
  manageRFQs,
  createRFQ,
  viewRFQ,
  updateRFQ,
  deleteRFQ,
  approveRFQ,
  rejectRFQ,
  //POs = Purchase Orders
  managePOs,
  createPO,
  updatePO,
  deletePO,
  viewPO,
  approvePO,
  rejectPO,
  // GRN = Goods Receipt Note
  manageGRN,
  createGRN,
  updateGRN,
  deleteGRN,
  approveGRN,
  rejectGRN,
  // SES = service entry sheet
  manageSES,
  createSES,
  updateSES,
  deleteSES,
  approveSES,
  rejectSES,
  // Suppliers Management
  manageSuppliers,
  createSuppliers,
  viewSuppliers,
  manageContracts,
  evaluateSuppliers,
  // Metrics
  // Invoice
  printInvoice,
  viewInvoice,
  // Report
  viewReport,
  viewImsSecrets, // For viewing items IDs
}

final List<AccessControl> _procurementPermissions = [
  AccessControl(
    module: "procurement",
    title: "Manage procurement",
    description: "Allow users to create, edit, and delete procurement.",
    access: ProcurementPermission.manageProcurement,
  ),
];

final List<AccessControl> _supplierManagementPermissions = [
  AccessControl(
    module: "supplier management",
    title: "Manage suppliers",
    description: "Allow users to create, edit, and delete suppliers.",
    access: ProcurementPermission.manageSuppliers,
  ),
  AccessControl(
    module: "supplier management",
    title: "Create new suppliers",
    description: "Allow users to process new suppliers at any location.",
    access: ProcurementPermission.createSuppliers,
  ),
  AccessControl(
    module: "supplier management",
    title: "View suppliers",
    description: "Allow access to a list of all completed suppliers.",
    access: ProcurementPermission.viewSuppliers,
  ),
  AccessControl(
    module: "supplier management",
    title: "Manage contracts",
    description: "Allow users to manage supplier contracts.",
    access: ProcurementPermission.manageContracts,
  ),
  AccessControl(
    module: "supplier management",
    title: "Evaluate suppliers",
    description: "Allow users to evaluate supplier performance.",
    access: ProcurementPermission.evaluateSuppliers,
  ),
];

final List<AccessControl> _purchaseRequisitionPermissions = [
  AccessControl(
    module: "pro purchase requisition",
    title: "Manage purchase requisition",
    description:
        "Allow users to create, edit, and delete purchase requisition.",
    access: ProcurementPermission.managePRs,
  ),
  AccessControl(
    module: "pro purchase requisition",
    title: "Create new purchase requisition",
    description:
        "Allow users to process new purchase requisition at any location.",
    access: ProcurementPermission.createPR,
  ),
  AccessControl(
    module: "pro purchase requisition",
    title: "View purchase requisition",
    description:
        "Allow access to a list of all completed purchase requisition.",
    access: ProcurementPermission.viewPR,
  ),
  AccessControl(
    module: "pro purchase requisition",
    title: "Edit existing purchase requisition",
    description:
        "Allow users to modify details of an existing purchase requisition.",
    access: ProcurementPermission.updatePR,
  ),
  AccessControl(
    module: "pro purchase requisition",
    title: "Delete purchase requisition",
    description:
        "Allow users to permanently remove a purchase requisition record.",
    access: ProcurementPermission.deletePR,
  ),
  AccessControl(
    module: "pro purchase requisition",
    title: "Approve purchase requisition",
    description: "Allow users to approve purchase requisition.",
    access: ProcurementPermission.approvePR,
  ),
  AccessControl(
    module: "pro purchase requisition",
    title: "Reject purchase requisition",
    description: "Allow users to reject purchase requisition.",
    access: ProcurementPermission.rejectPR,
  ),
];

final List<AccessControl> _requestForQuotePermissions = [
  AccessControl(
    module: "pro request for quotes",
    title: "Manage request for quotes",
    description: "Allow users to create, edit, and delete request for quotes.",
    access: ProcurementPermission.manageRFQs,
  ),
  AccessControl(
    module: "pro request for quotes",
    title: "Create new request for quotes",
    description:
        "Allow users to process new request for quotes at any location.",
    access: ProcurementPermission.createRFQ,
  ),
  AccessControl(
    module: "pro request for quotes",
    title: "View request for quotes",
    description: "Allow access to a list of all completed request for quotes.",
    access: ProcurementPermission.viewRFQ,
  ),
  AccessControl(
    module: "pro request for quotes",
    title: "Edit existing request for quotes",
    description:
        "Allow users to modify details of an existing request for quote.",
    access: ProcurementPermission.updateRFQ,
  ),
  AccessControl(
    module: "pro request for quotes",
    title: "Delete request for quotes",
    description:
        "Allow users to permanently remove a request for quote record.",
    access: ProcurementPermission.deleteRFQ,
  ),
  AccessControl(
    module: "pro request for quotes",
    title: "Approve request for quotes",
    description: "Allow users to approve request for quotes.",
    access: ProcurementPermission.approveRFQ,
  ),
  AccessControl(
    module: "pro request for quotes",
    title: "Reject request for quotes",
    description: "Allow users to reject request for quotes.",
    access: ProcurementPermission.rejectRFQ,
  ),
];

final List<AccessControl> _purchaseOrderPermissions = [
  AccessControl(
    module: "pro purchase orders",
    title: "Manage purchase orders",
    description: "Allow users to create, edit, and delete purchase orders.",
    access: ProcurementPermission.managePOs,
  ),
  AccessControl(
    module: "pro purchase orders",
    title: "Create new purchase orders",
    description: "Allow users to process new purchase orders at any location.",
    access: ProcurementPermission.createPO,
  ),
  AccessControl(
    module: "pro purchase orders",
    title: "View purchase orders",
    description: "Allow access to a list of all completed purchase orders.",
    access: ProcurementPermission.viewPO,
  ),
  AccessControl(
    module: "pro purchase orders",
    title: "Edit existing purchase orders",
    description: "Allow users to modify details of an existing purchase order.",
    access: ProcurementPermission.updatePO,
  ),
  AccessControl(
    module: "pro purchase orders",
    title: "Delete purchase orders",
    description: "Allow users to permanently remove a purchase order record.",
    access: ProcurementPermission.deletePO,
  ),
  AccessControl(
    module: "pro purchase orders",
    title: "Approve purchase orders",
    description: "Allow users to approve purchase orders.",
    access: ProcurementPermission.approvePO,
  ),
  AccessControl(
    module: "pro purchase orders",
    title: "Reject purchase orders",
    description: "Allow users to reject purchase orders.",
    access: ProcurementPermission.rejectPO,
  ),
];

final List<AccessControl> _goodsReceiptNotePermissions = [
  AccessControl(
    module: "goods receipt note",
    title: "Manage goods receipt note",
    description: "Allow users to create, edit, and delete goods receipt note.",
    access: ProcurementPermission.manageGRN,
  ),
  AccessControl(
    module: "goods receipt note",
    title: "Create goods receipt note",
    description:
        "Allow users to process new goods receipt note at any location.",
    access: ProcurementPermission.createGRN,
  ),
  AccessControl(
    module: "goods receipt note",
    title: "Edit goods receipt note",
    description:
        "Allow users to modify details of an existing goods receipt note.",
    access: ProcurementPermission.updateGRN,
  ),
  AccessControl(
    module: "goods receipt note",
    title: "Delete goods receipt note",
    description: "Allow users to permanently remove a goods receipt note.",
    access: ProcurementPermission.deleteGRN,
  ),
  AccessControl(
    module: "goods receipt note",
    title: "Approve goods receipt note",
    description: "Allow users to approve goods receipt note.",
    access: ProcurementPermission.approveGRN,
  ),
  AccessControl(
    module: "goods receipt note",
    title: "Reject goods receipt note",
    description: "Allow users to reject goods receipt note.",
    access: ProcurementPermission.rejectGRN,
  ),
];

final List<AccessControl> _serviceEntrySheetPermissions = [
  AccessControl(
    module: "service entry sheet",
    title: "Manage service entry sheet",
    description: "Allow users to create, edit, and delete service entry sheet.",
    access: ProcurementPermission.manageSES,
  ),
  AccessControl(
    module: "service entry sheet",
    title: "Create service entry sheet",
    description:
        "Allow users to process new service entry sheet at any location.",
    access: ProcurementPermission.createSES,
  ),
  AccessControl(
    module: "service entry sheet",
    title: "Edit service entry sheet",
    description:
        "Allow users to modify details of an existing service entry sheet.",
    access: ProcurementPermission.updateSES,
  ),
  AccessControl(
    module: "service entry sheet",
    title: "Delete service entry sheet",
    description: "Allow users to permanently remove a service entry sheet.",
    access: ProcurementPermission.deleteSES,
  ),
  AccessControl(
    module: "service entry sheet",
    title: "Approve service entry sheet",
    description: "Allow users to approve service entry sheet.",
    access: ProcurementPermission.approveSES,
  ),
  AccessControl(
    module: "service entry sheet",
    title: "Reject service entry sheet",
    description: "Allow users to reject service entry sheet.",
    access: ProcurementPermission.rejectSES,
  ),
];

final List<AccessControl> _metricsPermissions = [
  AccessControl(
    module: "pro metrics",
    title: "Print Invoices",
    description: "Allow users to view customer invoices and print copies.",
    access: ProcurementPermission.printInvoice,
  ),
  AccessControl(
    module: "pro metrics",
    title: "View financial data",
    description: "Allow access to financial reports and summaries.",
    access: ProcurementPermission.viewInvoice,
  ),
  AccessControl(
    module: "pro metrics",
    title: "Access reports and analytics",
    description: "Allow users to access sales, order, and product reports.",
    access: ProcurementPermission.viewReport,
  ),
];

final List<AccessControl> _secretPermissions = [
  AccessControl(
    module: "pro Secrets",
    title: "View Item IDs",
    description: "Allow users to view the reference numbers or IDs of items.",
    access: ProcurementPermission.viewImsSecrets,
  ),
];

final procurementDisplayName = 'procurement & Supplier';

final List<AccessControl> procurementPermission = [
  ..._procurementPermissions,
  ..._purchaseRequisitionPermissions,
  ..._requestForQuotePermissions,
  ..._purchaseOrderPermissions,
  ..._goodsReceiptNotePermissions,
  ..._serviceEntrySheetPermissions,
  ..._supplierManagementPermissions,
  ..._metricsPermissions,
  ..._secretPermissions,
];

/* can I use PageStorage to store user permissions...
NOTE: for security issues I don't want to persist
permissions in local storage so user can manipulate the data */
