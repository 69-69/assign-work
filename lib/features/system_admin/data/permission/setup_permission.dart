import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';
import 'package:assign_erp/features/system_admin/data/models/permission_model.dart';
import 'package:assign_erp/features/system_admin/data/models/role_model.dart';

/// PERMISSION BASED ACCESS-CONTROL
enum SetupPermission {
  manageSetup,
  manageTaxes,
  // Company Info
  manageCompany,
  createCompanyInfo,
  viewCompanyInfo,
  updateCompanyInfo,
  deleteCompanyInfo,

  // store Location
  manageStoreLocation,
  createStoreLocation,
  viewStoreLocation,
  updateStoreLocation,
  deleteStoreLocation,
  assignStoreLocation,

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

  // item categories
  manageItemCategory,
  createItemCategory,
  viewItemCategory,
  updateItemCategory,
  deleteItemCategory,

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
    module: "store locations",
    title: "Manage store locations",
    description: "Allow users to create, edit, and delete store locations.",
    access: SetupPermission.manageStoreLocation,
  ),
  AccessControl(
    module: "store location",
    title: "Create new store location",
    description: "Allow users to create new store locations.",
    access: SetupPermission.createStoreLocation,
  ),
  AccessControl(
    module: "store location",
    title: "View store locations",
    description: "Allow access to a list of all store locations.",
    access: SetupPermission.viewStoreLocation,
  ),
  AccessControl(
    module: "store location",
    title: "Edit store locations",
    description: "Allow users to modify details of an existing store location.",
    access: SetupPermission.updateStoreLocation,
  ),
  AccessControl(
    module: "store location",
    title: "Delete store locations",
    description: "Allow users to permanently remove a store location record.",
    access: SetupPermission.deleteStoreLocation,
  ),
  AccessControl(
    module: "store location",
    title: "Assign store locations",
    description: "Allow users to assign store locations to employees.",
    access: SetupPermission.assignStoreLocation,
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

final List<AccessControl> _itemCategoryPermissions = [
  AccessControl(
    module: "item category",
    title: "Manage item categories",
    description: "Allow users to create, edit, and delete item categories.",
    access: SetupPermission.manageItemCategory,
  ),
  AccessControl(
    module: "item category",
    title: "Create new item category",
    description: "Allow users to create new item categories.",
    access: SetupPermission.createItemCategory,
  ),
  AccessControl(
    module: "item category",
    title: "View item categories",
    description: "Allow access to a list of all item categories.",
    access: SetupPermission.viewItemCategory,
  ),
  AccessControl(
    module: "item category",
    title: "Edit item categories",
    description: "Allow users to modify details of an existing item category.",
    access: SetupPermission.updateItemCategory,
  ),
  AccessControl(
    module: "item category",
    title: "Delete item categories",
    description: "Allow users to permanently remove a item category record.",
    access: SetupPermission.deleteItemCategory,
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
  ..._taxesPermissions,
  ..._companyInfoPermissions,
  ..._storeLocationPermissions,
  ..._employeePermissions,
  ..._rolePermissions,
  ..._assignPermissions,
  ..._backupPermissions,
  ..._itemSupplierPermissions,
  ..._itemCategoryPermissions,
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

/// [businessOwnerDefaultPermissions] This is the Business owner's default permissions
/// during first-time workspace setup(Workspace Creation)
Map<String, dynamic> businessOwnerDefaultPermissions({required String id}) =>
    Role(
      id: id,
      name: 'business owner',
      permissions: _defaultBusinessOwnerPermissions,
      createdBy: 'system',
    ).toMap();
