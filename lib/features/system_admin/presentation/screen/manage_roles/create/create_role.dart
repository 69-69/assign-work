import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/data/models/permission_model.dart';
import 'package:assign_erp/features/system_admin/data/models/role_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/create_roles/role_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_roles/widget/form_inputs.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_roles/widget/permission_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateNewRole<T> on BuildContext {
  Future<void> openCreateNewRole() => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: 'Create New Role',
      body: _CreateNewRoleForm(),
    ),
  );
}

class _CreateNewRoleForm extends StatefulWidget {
  const _CreateNewRoleForm();

  @override
  State<_CreateNewRoleForm> createState() => _CreateNewRoleFormState();
}

class _CreateNewRoleFormState extends State<_CreateNewRoleForm> {
  bool _isSubmitting = false;
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();
  final Set<Permission> _assignedPermissions = {};
  final _nameController = TextEditingController();

  Employee? get _employee => context.employee;
  String get _employeeId => _employee!.employeeId;
  String get _employeeName => _employee!.fullName;

  Future<void> _onSubmit() async {
    final noPermissionsSelected = _assignedPermissions.isEmpty;

    if (_isSubmitting) return;
    if (noPermissionsSelected) {
      bool result = await _warnUser();
      if (!result) return;
    }

    if (mounted && _formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      /// Create New Role
      _createNewRole();
    }
  }

  Future<bool> _warnUser() async {
    final result = await context.confirmAction<bool>(
      const Text('Permissions are required to create a role.'),
      title: 'Assign Permissions',
    );
    return result;
  }

  void _createNewRole() {
    final newRole = Role(
      name: _nameController.text,
      permissions: _assignedPermissions,
      createdBy: _employeeName,
      history: [AuditLog(action: AuditAction.created, actionBy: _employeeId)],
    );
    context.read<RoleBloc>().add(AddSetup<Role>(data: newRole));
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _assignedPermissions.clear();
      });
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => _resetForm());
  }

  void _handleBlocState(BuildContext cxt, SetupState<Role> state) {
    switch (state) {
      case SetupAdded<Role>(message: var msg):
        _showAlert(msg ?? 'Role created successfully');
      case SetupError<Role>():
        _showAlert('Error saving changes');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoleBloc, SetupState<Role>>(
      listener: _handleBlocState,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: KeyedSubtree(key: _formResetKey, child: _buildBody(context)),
      ),
    );
  }

  Column _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 10.0),
        RoleName(
          nameController: _nameController,
          onNameChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        PermissionCard(onSelectedFunc: _onSelectedFunc),
        const SizedBox(height: 10.0),

        context.confirmableActionButton(
          label: _isSubmitting ? 'Creating...' : 'Create Role',
          isDisabled: _isSubmitting,
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  void _onSelectedFunc(Set<Permission> permissions, String module) {
    // Remove all permissions that belong to any of these modules
    _assignedPermissions.removeWhere((p) => p.module == module);

    // Only add new permissions if there are any selected (if `permissions` is empty, don't add anything)
    if (permissions.isNotEmpty) {
      _assignedPermissions.addAll(permissions);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

/*I have an ERP software (POS, Inventory, Warehouse and CRM)
with multi-tenants or workspaces developed with flutter and
firestore db. how do I allow subscribers or tenants to create
employees roles and attached permissions so that when an employee
or staff signs in...it allow features based on your role and
permissions

========

To implement a **role-based access control (RBAC)** system for your multi-tenant ERP app built with **Flutter and Firestore**, you'll need to design your Firestore structure and app logic to handle:

1. **Roles and permissions per tenant**
2. **Employee-to-role mapping**
3. **Permission checks at runtime**

---

### ✅ Step-by-Step Guide

#### 1. **Define Role and Permission Structure**

Each tenant (workspace) can have its own set of roles and permissions.

##### Firestore structure:

```plaintext
tenants (collection)
 └── tenantId (document)
     └── roles (subcollection)
         └── roleId (document)
             └── name: "Cashier"
             └── permissions: ["pos.read", "inventory.view"]
     └── employees (subcollection)
         └── employeeId (document)
             └── userId: authUid
             └── roleId: "cashier"
```

---

#### 2. **Design a Permissions Map (Reference)**

Use a fixed map of permissions across the app. For example:

```dart
const permissionsMap = {
  "pos.read": "Can view POS",
  "pos.write": "Can operate POS",
  "inventory.view": "Can view inventory",
  "inventory.edit": "Can edit inventory",
  "crm.access": "Can access CRM",
  "warehouse.manage": "Can manage warehouse",
};
```

---

#### 3. **On Login: Fetch Role and Permissions**

When an employee logs in:

* Get the `employee` record under the tenant.
* Use the `roleId` to fetch the `role` document.
* Attach the permissions list to the app session.

```dart
Future<List<String>> getUserPermissions(String tenantId, String userId) async {
  final employeeDoc = await FirebaseFirestore.instance
    .collection('tenants')
    .doc(tenantId)
    .collection('employees')
    .where('userId', isEqualTo: userId)
    .limit(1)
    .get();

  if (employeeDoc.docs.isEmpty) return [];

  final roleId = employeeDoc.docs.first['roleId'];

  final roleDoc = await FirebaseFirestore.instance
    .collection('tenants')
    .doc(tenantId)
    .collection('roles')
    .doc(roleId)
    .get();

  return List<String>.from(roleDoc.data()?['permissions'] ?? []);
}
```

---

#### 4. **Restrict Feature Access Based on Permissions**

Use helper functions in your Flutter widgets to determine access:

```dart
bool hasPermission(String permission, List<String> userPermissions) {
  return userPermissions.contains(permission);
}

// Usage in UI
if (hasPermission("inventory.view", userPermissions)) {
  showInventoryWidget();
}
```

---

#### 5. **Role and Permission Management UI**

Build admin-only screens to:

* Create roles
* Assign permissions to roles
* Assign roles to employees

Only allow admins to access this screen (e.g., by checking if they have `admin.role.manage` permission).

---

### ⚠️ Security Considerations

* **Never rely solely on client-side checks.** Secure access via Firestore security rules too.
* Example Firestore rule (simplified):

```js
match /tenants/{tenantId}/inventory/{itemId} {
  allow read: if request.auth != null &&
                 exists(/databases/$(database)/documents/tenants/$(tenantId)/employees/$(request.auth.uid)) &&
                 get(/databases/$(database)/documents/tenants/$(tenantId)/roles/$(employee.roleId)).data.permissions.hasAny(['inventory.view']);
}
```

You’d need to structure security rules to fetch role and permissions securely.

---

### ✅ Optional Enhancements

* Add a UI for **custom role creation** per tenant.
* Use a `permissions` field on the employee directly to allow **overrides or fine-grained control**.
* Cache permissions client-side using `Provider` or `Riverpod` for performance.

---

Would you like a **sample Firestore data structure in JSON** or a **Flutter provider setup** for managing roles and permissions in memory?


========

Great! Below is both:

---

## ✅ 1. **Sample Firestore Data Structure (JSON-like)**

Assuming each tenant has their own isolated set of roles and employees:

### 🔹 `/tenants/{tenantId}/roles/{roleId}`

```json
{
  "name": "Inventory Manager",
  "permissions": [
    "inventory.view",
    "inventory.edit",
    "warehouse.manage"
  ]
}
```

---

### 🔹 `/tenants/{tenantId}/employees/{employeeId}`

```json
{
  "userId": "authUID_of_employee",
  "roleId": "inventory_manager"
}
```

---

### 🔹 Master Permissions Map (Optional static collection)

If you want to store the full list of permission labels:

**`/permissions/{permissionId}`**

```json
{
  "id": "inventory.edit",
  "description": "Can edit inventory items"
}
```

This is useful if you want to allow UI-based role editing with checkboxes for each permission.

---

## ✅ 2. **Flutter Provider Setup to Manage Roles & Permissions**

This uses `provider` package to hold the current user's permissions after login.

---

### 🧩 `auth_provider.dart` (simplified)

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  String? _userId;
  String? _tenantId;
  List<String> _permissions = [];

  List<String> get permissions => _permissions;

  Future<void> initialize(String userId, String tenantId) async {
    _userId = userId;
    _tenantId = tenantId;

    final employeeQuery = await FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection('employees')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (employeeQuery.docs.isEmpty) return;

    final employeeData = employeeQuery.docs.first.data();
    final roleId = employeeData['roleId'];

    final roleDoc = await FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection('roles')
        .doc(roleId)
        .get();

    _permissions = List<String>.from(roleDoc.data()?['permissions'] ?? []);
    notifyListeners();
  }

  bool hasPermission(String permission) => _permissions.contains(permission);
}
```

---

### 🧩 Usage in Widgets

```dart
final authProvider = Provider.of<AuthProvider>(context);

if (authProvider.hasPermission("inventory.edit")) {
  return ElevatedButton(
    onPressed: () {
      // show inventory editing UI
    },
    child: Text("Edit Inventory"),
  );
} else {
  return Text("You don't have access to edit inventory");
}
```

---

### 🧩 Initialize on Login

After FirebaseAuth login and determining `tenantId`:

```dart
await Provider.of<AuthProvider>(context, listen: false)
    .initialize(user.uid, tenantId);
```

---

## ✅ 3. Optional: Permissions as Constants

Create a file like `permissions.dart`:

```dart
class Permissions {
  static const posRead = "pos.read";
  static const posWrite = "pos.write";
  static const inventoryView = "inventory.view";
  static const inventoryEdit = "inventory.edit";
  static const warehouseManage = "warehouse.manage";
  static const crmAccess = "crm.access";
}
```

So you can call:

```dart
if (authProvider.hasPermission(Permissions.inventoryView)) { ... }
```

---

Would you like:

* A full UI screen for **creating roles with checkboxes for permissions**?
* Firestore **security rules template** for this role-permission structure?
* Or a **FlutterFire CLI setup for multi-tenant Firebase Auth**?




*/
