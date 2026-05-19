import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';
import 'package:assign_erp/features/system_admin/data/models/permission_model.dart';
import 'package:assign_erp/features/system_admin/data/models/role_model.dart';

/// PERMISSION BASED ACCESS-CONTROL
enum SetupPermission {
  manageSetup,
  manageTaxes,
  manageMasterData,
  manageItemMaster,
  manageWarehouseMaster,
  manageWHLocationMaster,
  manageWHBinMaster,
  managePriceMaster,
  manageCurrencyMaster,
  referenceMaster,
  manageVariants,
  manageUOM,
  // Company Info
  manageCompany,
  createCompanyInfo,
  viewCompanyInfo,
  updateCompanyInfo,
  deleteCompanyInfo,

  // store Branch
  manageStoreBranch,
  createStoreBranch,
  viewStoreBranch,
  updateStoreBranch,
  deleteStoreBranch,
  assignStoreBranch,

  // Employee
  manageEmployee,
  createEmployee,
  viewEmployee,
  updateEmployee,
  deleteEmployee,

  // Role
  manageRole,
  createRole,
  viewRole,
  updateRole,
  deleteRole,

  // Workflow Approval
  manageWorkflowApproval,
  createWorkflowApproval,
  viewWorkflowApproval,
  updateWorkflowApproval,
  deleteWorkflowApproval,
  assignWorkflowApproval,

  // Assign Permission
  assignPermission,

  // backup
  manageBackup,
  createBackup,
  deleteBackup,
  restoreBackup,
  historyBackup,

  // license
  viewLicense,

  // item suppliers
  manageItemSupplier,
  createItemSupplier,
  viewItemSupplier,
  updateItemSupplier,
  deleteItemSupplier,

  // print settings
  updatePrintSetting,
  viewSetupSecrets, // For viewing configuration IDs
  // For unspecified permissions
}

final List<AccessControl> _setupPermissions = [
  AccessControl(
    module: "setup",
    title: "Manage setup",
    description:
        "Grants users the ability to create, modify, and remove workspace setup configurations",
    access: SetupPermission.manageSetup,
  ),
];

final List<AccessControl> _taxesPermissions = [
  AccessControl(
    module: "taxes",
    title: "Manage taxes",
    description: "Allow users to create, edit, and delete taxes.",
    access: SetupPermission.manageTaxes,
  ),
];

final List<AccessControl> _masterDataPermissions = [
  AccessControl(
    module: "master data",
    title: "Manage core master data",
    description: "Allow users to create, edit, and delete ERP master data.",
    access: SetupPermission.manageMasterData,
  ),
  AccessControl(
    module: "master data",
    title: "Manage item master",
    description: "Allow users to create, edit, and delete item master data.",
    access: SetupPermission.manageItemMaster,
  ),
  AccessControl(
    module: "master data",
    title: "Manage Warehouse Sites",
    description:
    "Create, edit, and deactivate warehouses used for inventory storage and operations.",
    access: SetupPermission.manageWarehouseMaster,
  ),
  AccessControl(
    module: "master data",
    title: "Manage Warehouse Locations",
    description:
    "Create, edit, and manage storage locations such as racks, aisles, or shelves within a warehouse.",
    access: SetupPermission.manageWHLocationMaster,
  ),
  AccessControl(
    module: "master data",
    title: "Manage Warehouse Bins",
    description:
    "Create, edit, and manage individual storage bins within warehouse locations.",
    access: SetupPermission.manageWHBinMaster,
  ),
];

final List<AccessControl> _priceListMasterPermissions = [
  AccessControl(
    module: "pricing",
    title: "Manage pricing",
    description:
    "Allow users to create, edit, and delete price lists, pricing tiers, and discounts.",
    access: SetupPermission.managePriceMaster,
  ),
];

final List<AccessControl> _currenciesMasterPermissions = [
  AccessControl(
    module: "currencies",
    title: "Manage currencies master",
    description: "Allow users to create, edit, and delete currencies.",
    access: SetupPermission.manageCurrencyMaster,
  ),
];

final List<AccessControl> _referenceMasterPermissions = [
  AccessControl(
    module: "reference master",
    title: "Manage reference master",
    description: "Allow users to create, edit, and delete reference master.",
    access: SetupPermission.referenceMaster,
  ),
  AccessControl(
    module: "variants",
    title: "Manage variants",
    description: "Allow users to create, edit, and delete variants.",
    access: SetupPermission.manageVariants,
  ),
  AccessControl(
    module: "Unit of Measure",
    title: "Manage UOM",
    description: "Allow users to create, edit, and delete UOM.",
    access: SetupPermission.manageUOM,
  ),
];

final List<AccessControl> _companyInfoPermissions = [
  AccessControl(
    module: "company info",
    title: "Manage company info",
    description: "Allow users to create, edit, and delete company information.",
    access: SetupPermission.manageCompany,
  ),
  AccessControl(
    module: "company info",
    title: "Create company info",
    description: "Allow users to create new company information.",
    access: SetupPermission.createCompanyInfo,
  ),
  AccessControl(
    module: "company info",
    title: "View company info",
    description: "Allow access to a list of all company information.",
    access: SetupPermission.viewCompanyInfo,
  ),
  AccessControl(
    module: "company info",
    title: "Edit company info",
    description: "Allow users to modify details of an existing company info.",
    access: SetupPermission.updateCompanyInfo,
  ),
  AccessControl(
    module: "company info",
    title: "Delete company info",
    description: "Allow users to permanently remove a company info record.",
    access: SetupPermission.deleteCompanyInfo,
  ),
];

final List<AccessControl> _storeLocationPermissions = [
  AccessControl(
    module: "stores",
    title: "Manage store branches",
    description: "Allow users to create, edit, and delete store branches.",
    access: SetupPermission.manageStoreBranch,
  ),
  AccessControl(
    module: "stores",
    title: "Create new store branch",
    description: "Allow users to create new store branches.",
    access: SetupPermission.createStoreBranch,
  ),
  AccessControl(
    module: "stores",
    title: "View store branches",
    description: "Allow access to a list of all store branches.",
    access: SetupPermission.viewStoreBranch,
  ),
  AccessControl(
    module: "stores",
    title: "Edit store branches",
    description: "Allow users to modify details of an existing store branch.",
    access: SetupPermission.updateStoreBranch,
  ),
  AccessControl(
    module: "stores",
    title: "Delete store branches",
    description: "Allow users to permanently remove a store branch record.",
    access: SetupPermission.deleteStoreBranch,
  ),
  AccessControl(
    module: "stores",
    title: "Assign store branches",
    description: "Allow users to assign store branches to employees.",
    access: SetupPermission.assignStoreBranch,
  ),
];

final List<AccessControl> _employeePermissions = [
  AccessControl(
    module: "employee",
    title: "Manage employees",
    description: "Allow users to create, edit, and delete employees.",
    access: SetupPermission.manageEmployee,
  ),
  AccessControl(
    module: "employee",
    title: "Create new employee",
    description: "Allow users to create new employees account.",
    access: SetupPermission.createEmployee,
  ),
  AccessControl(
    module: "employee",
    title: "View employees",
    description: "Allow access to a list of all employees account.",
    access: SetupPermission.viewEmployee,
  ),
  AccessControl(
    module: "employee",
    title: "Edit employees",
    description:
        "Allow users to modify details of an existing employee account.",
    access: SetupPermission.updateEmployee,
  ),
  AccessControl(
    module: "employee",
    title: "Delete employees",
    description: "Allow users to permanently remove an employee record.",
    access: SetupPermission.deleteEmployee,
  ),
];

final List<AccessControl> _rolePermissions = [
  AccessControl(
    module: "role",
    title: "roles & permissions",
    description: "Allow users to create, edit, and delete roles.",
    access: SetupPermission.manageRole,
  ),
  AccessControl(
    module: "role",
    title: "Create new role",
    description: "Allow users to create new roles.",
    access: SetupPermission.createRole,
  ),
  AccessControl(
    module: "role",
    title: "View roles",
    description: "Allow access to a list of all roles.",
    access: SetupPermission.viewRole,
  ),
  AccessControl(
    module: "role",
    title: "Edit roles",
    description: "Allow users to modify details of an existing role.",
    access: SetupPermission.updateRole,
  ),
  AccessControl(
    module: "role",
    title: "Delete roles",
    description: "Allow users to permanently remove a role record.",
    access: SetupPermission.deleteRole,
  ),
];

final List<AccessControl> _workflowApprovalPermissions = [
  AccessControl(
    module: "workflow approval",
    title: "Manage workflow approval",
    description: "Allow users to create, edit, and delete workflow approvals.",
    access: SetupPermission.manageWorkflowApproval,
  ),
  AccessControl(
    module: "workflow approval",
    title: "Create new workflow approval",
    description: "Allow users to create new workflow approvals.",
    access: SetupPermission.createWorkflowApproval,
  ),
  AccessControl(
    module: "workflow approval",
    title: "View workflow approvals",
    description: "Allow access to a list of all workflow approvals.",
    access: SetupPermission.viewWorkflowApproval,
  ),
  AccessControl(
    module: "workflow approval",
    title: "Edit workflow approvals",
    description:
        "Allow users to modify details of an existing workflow approval.",
    access: SetupPermission.updateWorkflowApproval,
  ),
  AccessControl(
    module: "workflow approval",
    title: "Delete workflow approvals",
    description:
        "Allow users to permanently remove a workflow approval record.",
    access: SetupPermission.deleteWorkflowApproval,
  ),
];

final List<AccessControl> _assignPermissions = [
  AccessControl(
    module: "assign permission",
    title: "Assign permissions to roles",
    description: "Allow users to assign permissions to roles.",
    access: SetupPermission.assignPermission,
  ),
];

final List<AccessControl> _backupPermissions = [
  AccessControl(
    module: "backup",
    title: "Manage backups",
    description: "Allow users to create, edit, and delete backups.",
    access: SetupPermission.manageBackup,
  ),
  AccessControl(
    module: "backup",
    title: "Create new backup",
    description: "Allow users to create new backups.",
    access: SetupPermission.createBackup,
  ),
  AccessControl(
    module: "backup",
    title: "Restore backups",
    description: "Allow users to restore backups from a cloud.",
    access: SetupPermission.restoreBackup,
  ),
  AccessControl(
    module: "backup",
    title: "backup history",
    description: "Allow users to view the history of previous backups.",
    access: SetupPermission.historyBackup,
  ),
  AccessControl(
    module: "backup",
    title: "Delete backups",
    description: "Allow users to permanently remove a backup record.",
    access: SetupPermission.deleteBackup,
  ),
];

final List<AccessControl> _itemSupplierPermissions = [
  AccessControl(
    module: "item supplier",
    title: "Manage item suppliers",
    description: "Allow users to create, edit, and delete item suppliers.",
    access: SetupPermission.manageItemSupplier,
  ),
  AccessControl(
    module: "item supplier",
    title: "Create new item supplier",
    description: "Allow users to create new item suppliers.",
    access: SetupPermission.createItemSupplier,
  ),
  AccessControl(
    module: "item supplier",
    title: "View item suppliers",
    description: "Allow access to a list of all item suppliers.",
    access: SetupPermission.viewItemSupplier,
  ),
  AccessControl(
    module: "item supplier",
    title: "Edit item suppliers",
    description: "Allow users to modify details of an existing item supplier.",
    access: SetupPermission.updateItemSupplier,
  ),
  AccessControl(
    module: "item supplier",
    title: "Delete item suppliers",
    description: "Allow users to permanently remove a item supplier record.",
    access: SetupPermission.deleteItemSupplier,
  ),
];

final List<AccessControl> _printSettingPermissions = [
  AccessControl(
    module: "print setting",
    title: "Update print settings",
    description: "Allow users to update print settings.",
    access: SetupPermission.updatePrintSetting,
  ),
];

final List<AccessControl> _licensePermissions = [
  AccessControl(
    module: "license",
    title: "View license",
    description: "Allow users to view the license.",
    access: SetupPermission.viewLicense,
  ),
];

final List<AccessControl> _secretPermissions = [
  AccessControl(
    module: "Setup Secrets",
    title: "View Configuration IDs",
    description: "Allow users to view the IDs of configuration.",
    access: SetupPermission.viewSetupSecrets,
  ),
];

final systemAdminDisplayName = 'system admin';

/// High-level = access the section (Manage)
/// Low-level = control button-level permissions (Create, Edit, Delete)
final List<AccessControl> setupPermissions = [
  ..._setupPermissions,
  ..._masterDataPermissions,
  ..._taxesPermissions,
  ..._companyInfoPermissions,
  ..._storeLocationPermissions,
  ..._employeePermissions,
  ..._rolePermissions,
  ..._workflowApprovalPermissions,
  ..._assignPermissions,
  ..._backupPermissions,
  ..._referenceMasterPermissions,
  ..._priceListMasterPermissions,
  ..._currenciesMasterPermissions,
  ..._itemSupplierPermissions,
  ..._printSettingPermissions,
  ..._licensePermissions,
  ..._secretPermissions,
];

Set<Permission> _defaultBusinessOwnerPermissions = setupPermissions
    .map(
      (permission) => Permission(
        module: permission.module,
        permission: permission.accessName,
      ),
    )
    .toSet();

/// Creates the default permission set for the business owner
/// during initial workspace setup (first-time tenant creation).
/// System-defined role with full tenant privileges.
/// NOTE: Created automatically and not user-editable.
Map<String, dynamic> createBusinessOwnerRoleAndPerm({required String id}) =>
    Role(
      id: id,
      isPrimary: true, // Business Owner Role: Primary Role (Cannot be deleted)
      name: 'business owner',
      permissions: _defaultBusinessOwnerPermissions,
      createdBy: 'system',
    ).toMap();
