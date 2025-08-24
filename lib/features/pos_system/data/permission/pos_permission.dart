import 'package:assign_erp/features/access_control/data/model/access_control_model.dart';

/// PERMISSION BASED ACCESS-CONTROL
/*
enum PosPermission {
  createPosSale,
  viewSalesHistory,
  applyDiscount,
  refundTransaction,
  holdSale,
  reopenSale,
  reprintReceipt,
  manageCashDrawer,
  closeRegister,
  openRegister,
  viewZReports,
  exportSalesData,
}
*/
enum PosPermission {
  managePointOfSales,

  /*🔹 Sales:
    A sale represents a transaction where goods or services are sold to a customer.
    It records what was sold, how much was sold, and at what price.
    A sale includes details like:
    Items purchased
    Quantity
    Discounts
    Tax
    Total amount owed by the customer
  */
  managePosSales,
  createPosSale,
  viewPosSale,
  updatePosSale,
  deletePosSale,
  applyDiscount,
  // Order
  managePosOrders,
  viewPosOrder,
  createPosOrder,
  updatePosOrder,
  deletePosOrder,
  // Customer
  createPosCustomer,
  viewPosCustomer,
  updatePosCustomer,
  deletePosCustomer,
  // Inventory
  viewPosInventory,
  createPosInventory,
  updatePosInventory,
  deletePosInventory,
  // Transaction
  /*🔹 Payment
    A payment is the money received from the customer to settle the sale.
    It can be:
    In full or partial
    In various forms: cash, credit card, debit, gift card, mobile payment, etc.
    A payment is what clears the customer’s debt from the sale.
  */
  managePosPayments,

  /*🔹 3. Finance (in POS context)
    Definition: This refers to the financial management features within or connected to the POS system.

    Covers:
    Sales summaries
    Cash flow tracking
    Accounts receivable (credit sales)
    Loans, credit terms, or installment plans
    Profit & loss reporting
    Integration with accounting software (e.g., QuickBooks, Xero)
    Example: A POS may show total revenue this month, outstanding payments (credit sales), expenses, and net profit.
    ✅ Key Role in POS: Enables businesses to understand financial health and plan accordingly.
   */
  managePosFinance,

  reprintReceipt,
  viewSalesHistory,
  viewPosReport,
  viewPosSecrets, // For viewing items IDs
}

final List<AccessControl> _posPermissions = [
  AccessControl(
    module: "pos",
    title: "Manage point of sales",
    description:
        "Grants users the ability to create, update, and delete point of sale entries.",
    access: PosPermission.managePointOfSales,
  ),
];

final List<AccessControl> _salesPermissions = [
  // Sales
  AccessControl(
    module: "all sales",
    title: "Manage sales",
    description:
        "Allow users to create, update, and delete sales, including discounts and refunds.",
    access: PosPermission.managePosSales,
  ),
  AccessControl(
    module: "pos sales",
    title: "Create new sales",
    description: "Allow users to process new sales at any location.",
    access: PosPermission.createPosSale,
  ),
  AccessControl(
    module: "pos sales",
    title: "View sales records",
    description: "Allow access to a list of all completed sales.",
    access: PosPermission.viewPosSale,
  ),
  AccessControl(
    module: "pos sales",
    title: "Edit existing sales",
    description: "Allow users to modify details of an existing sale.",
    access: PosPermission.updatePosSale,
  ),
  AccessControl(
    module: "pos sales",
    title: "Delete sales",
    description: "Allow users to permanently remove a sale record.",
    access: PosPermission.deletePosSale,
  ),
  AccessControl(
    module: "pos discounts",
    title: "Apply Discount",
    description: "Allow users to apply discounts to items or total.",
    access: PosPermission.applyDiscount,
  ),
];

final List<AccessControl> _ordersPermissions = [
  AccessControl(
    module: "all orders",
    title: "Manage orders",
    description: "Allow users to create, update, and delete orders.",
    access: PosPermission.managePosOrders,
  ),
  AccessControl(
    module: "pos orders",
    title: "View order details",
    description: "Allow access to a list of placed and fulfilled orders.",
    access: PosPermission.viewPosOrder,
  ),
  AccessControl(
    module: "pos orders",
    title: "Create new orders",
    description: "Allow users to place new customer orders.",
    access: PosPermission.createPosOrder,
  ),
  AccessControl(
    module: "pos orders",
    title: "Edit existing orders",
    description: "Allow users to update order details or statuses.",
    access: PosPermission.updatePosOrder,
  ),
  AccessControl(
    module: "pos orders",
    title: "Delete orders",
    description: "Allow users to delete orders from the system.",
    access: PosPermission.deletePosOrder,
  ),
];

final List<AccessControl> _customersPermissions = [
  AccessControl(
    module: "pos customers",
    title: "View customers",
    description:
        "Allow access to customer lists, profiles, and contact details.",
    access: PosPermission.viewPosCustomer,
  ),
  AccessControl(
    module: "pos customers",
    title: "Add new customers",
    description: "Allow users to create new customer records.",
    access: PosPermission.createPosCustomer,
  ),
  AccessControl(
    module: "pos customers",
    title: "Edit customer information",
    description: "Allow updates to customer contact info, tags, and notes.",
    access: PosPermission.updatePosCustomer,
  ),
  AccessControl(
    module: "pos customers",
    title: "Delete customers",
    description: "Allow permanent removal of customer records from the system.",
    access: PosPermission.deletePosCustomer,
  ),
];

final List<AccessControl> _inventoryPermissions = [
  AccessControl(
    module: "pos inventory",
    title: "View inventory",
    description:
        "Allow access to inventory items, stock levels, and product details.",
    access: PosPermission.viewPosInventory,
  ),
  AccessControl(
    module: "pos inventory",
    title: "Add new inventory items",
    description: "Allow users to create new products or stock items.",
    access: PosPermission.createPosInventory,
  ),
  AccessControl(
    module: "pos inventory",
    title: "Edit inventory items",
    description: "Allow users to update item names, prices, or stock details.",
    access: PosPermission.updatePosInventory,
  ),
  AccessControl(
    module: "pos inventory",
    title: "Delete inventory items",
    description: "Allow users to remove items from the inventory database.",
    access: PosPermission.deletePosInventory,
  ),
];

final List<AccessControl> _metricsPermissions = [
  AccessControl(
    module: "pos transactions",
    title: "Manage payments",
    description:
        "Allow users to manage payment methods and transactions in various forms: cash, credit card, debit, gift card, mobile payment.",
    access: PosPermission.managePosPayments,
  ),
  AccessControl(
    module: "pos transactions",
    title: 'Manage finance',
    description:
        'Allow users to manage financial transactions, like Sales summaries, Cash flow tracking, Accounts receivable (credit sales), Loans, credit terms, or installment plans, Profit & loss reporting.',
    access: PosPermission.managePosFinance,
  ),
  AccessControl(
    module: "pos transactions",
    title: "Print receipts",
    description: "Allow users to view customer receipts and print copies.",
    access: PosPermission.reprintReceipt,
  ),
  AccessControl(
    module: "pos transactions",
    title: "View Sales History",
    description: "Allow users to browse past sales transactions.",
    access: PosPermission.viewSalesHistory,
  ),
  AccessControl(
    module: "pos transactions",
    title: "Access reports and analytics",
    description: "Allow users to access sales, order, and product reports.",
    access: PosPermission.viewPosReport,
  ),
];

final List<AccessControl> _secretPermissions = [
  AccessControl(
    module: "POS Secrets",
    title: "View POS IDs",
    description: "Allow users to view the reference numbers or IDs of items.",
    access: PosPermission.viewPosSecrets,
  ),
];

final posDisplayName = 'point of sales';

final List<AccessControl> posPermissions = [
  ..._posPermissions,
  ..._salesPermissions,
  ..._ordersPermissions,
  ..._customersPermissions,
  ..._inventoryPermissions,
  ..._metricsPermissions,
  ..._secretPermissions,
];

/*/// Set Up Permissions for Each Role [rolePermissions]
final Map<EmployeeRole, RolePermissionContext<PosPermission>> rolePermissions =
    {
      EmployeeRole.businessOwner: RolePermissionContext<PosPermission>(
        role: EmployeeRole.businessOwner,
        permissions: PosPermission.values.toSet(),
      ),
      EmployeeRole.manager: RolePermissionContext<PosPermission>(
        role: EmployeeRole.manager,
        permissions: PosPermission.values.toSet(),
      ),
      EmployeeRole.developer: RolePermissionContext<PosPermission>(
        role: EmployeeRole.developer,
        permissions: PosPermission.values.toSet(),
      ),
      EmployeeRole.tester: RolePermissionContext<PosPermission>(
        role: EmployeeRole.tester,
        permissions: {PosPermission.createPosSale},
      ),
    };

/// Check Permissions [hasPOSPermission]
bool hasPOSPermission(Employee employee, {required PosPermission perm}) {
  final rolePerms = rolePermissions[employee.role];
  return hasPermission<PosPermission>(rolePerms, perm: perm);
}*/

/* USAGE Example: Implement Permission-Access Control in Your App
  * final currentUser = Employee(userpermission: 'JohnDoe', role: EmployeeRole.developer,  email: 'john.doe@example.com',);
  * if (hasPermission(currentUser, perm: Permission.read))
              Text('You have read access.'),
  * if (hasPermission(currentUser, perm: Permission.write))
              ElevatedButton(
                onPressed: () {},
                child: Text('Content Editor'),
              ),
  * if (hasPermission(currentUser, perm: Permission.execute))
              ElevatedButton(
                onPressed: () {},
                child: Text('Content Editor'),
              ),
  * */

/* FIRESTORE IMPLEMENTATION OF ROLE-BASE:
*
* First, you need to define roles for your users. This typically involves storing
* role information either within Firestore or in Firebase Authentication custom claims.
*
* FIRESTORE-DB COLLECTION-STRUCTURE:
* {
  "users": {
  * // Users Collection: users/{userId}
    "userId1": {
      "username": "john_doe",
      "role": "administrator"
    },
    "userId2": {
      "username": "jane_smith",
      "role": "manager"
    }
    // Documents Collection: documents/{documentId}:
  }
}

* * FIRESTORE-DB SECURITY RULE
*
// Firestore Security Rules
*
* You can check the state of the authentication request itself, such as whether a user is authenticated or not.
* service cloud.firestore {
  match /databases/{database}/documents {
    match /documents/{documentId} {
      allow read: if request.auth != null && request.auth.token.email_verified == true;
    }
  }
}

*
* You can design more complex role-based access control by combining multiple roles and permissions.
service cloud.firestore {
  match /databases/{database}/documents {
    match /documents/{documentId} {
      allow read: if hasReadAccess() && isUserVerified();
      allow write: if hasWriteAccess() && isUserVerified();

      function isUserVerified() {
        return request.auth.token.email_verified == true;
      }

      function hasReadAccess() {
        return request.auth != null &&
               (isAdmin() || isManager() || isCollaborator());
      }

      function hasWriteAccess() {
        return request.auth != null &&
               (isAdmin() || isManager());
      }

      function isAdmin() {
        return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'administrator';
      }

      function isManager() {
        return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'manager';
      }

      function isCollaborator() {
        return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'collaborator';
      }
    }
  }
}

*
*
service cloud.firestore {
  match /databases/{database}/documents {

    // Allow access to the 'workspace' collection
    // workspaceId: is the ID assign company or firm that uses my software
    match /works_pace_auth_db/{workspaceId} {
      allow read, write: if request.auth != null && request.auth.uid == workspaceId && isUserVerified();
    }

    // General rules for documents based on roles
    match /documents/{documentId} {
      allow read: if hasReadAccess();
      allow write: if hasWriteAccess();
    }

    function isUserVerified() {
      return request.auth.token.email_verified == true;
    }

    function hasReadAccess() {
      return request.auth != null &&
             get(/databases/$(database)/documents/users_auth_db/$(request.auth.uid)).data.role in ['administrator', 'manager', 'developer'];
    }

    function hasWriteAccess() {
      return request.auth != null &&
             get(/databases/$(database)/documents/users_auth_db/$(request.auth.uid)).data.role in ['administrator', 'manager'];
    }
  }
}
*
* Practical Example::
* /databases/{database}/documents/projects/projectA — This is a document with ID projectA within the projects collection.
* /databases/{database}/documents/projects/projectB — This is another document with ID projectB within the projects collection.
*
* get(/databases/$(database)/documents/projects/$(projectId)).data.members[request.auth.uid] == true:
* Checks if the authenticated user (identified by request.auth.uid) is listed as a member of the project document being accessed. The members field in the document should be a map where each key is a user ID and the value is true if the user is a member.
*
* Suppose you have the following documents in your projects collection:
* Document projectA: {
  "members": {
    "user123": true,
    "user456": false
  },
  "admins": ["user123"]
}
*
* Document projectB:
* {
  "members": {
    "user123": false,
    "user789": true
  },
  "admins": ["user789"]
}
*
* How Rules Apply

* For projectA:
* A user with uid = user123 can read and write if authenticated, because user123 is in both the members and admins fields.
* A user with uid = user456 can read but cannot write, because user456 is not in the admins field.
* For projectB:
* A user with uid = user123 cannot read or write to projectB, because user123 is not listed as a member or admin for projectB.
* A user with uid = user789 can read and write to projectB, because user789 is listed as an admin and a member.
*
* service cloud.firestore {
  match /databases/{database}/documents {
    match /projects/{projectId} {
      allow read: if request.auth != null && get(/databases/$(database)/documents/projects/$(projectId)).data.members[request.auth.uid] == true;
      allow write: if request.auth != null && request.auth.uid in get(/databases/$(database)/documents/projects/$(projectId)).data.admins;
    }
  }
}


* * DATA-REPOSITORY IMPLEMENTATION:
*
*
// Function to get documents based on user role
Future<void> fetchDocumentsBasedOnRole() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userSnapshot = await userDoc.get();

    if (userSnapshot.exists) {
      final userRole = userSnapshot.data()?['role'];
      QuerySnapshot documentsSnapshot;

      if (userRole == 'administrator' || userRole == 'manager') {
        documentsSnapshot = await FirebaseFirestore.instance.collection('documents').get();
      } else if (userRole == 'developer') {
        documentsSnapshot = await FirebaseFirestore.instance.collection('documents').where('category', isEqualTo: 'development').get();
      } else {
        documentsSnapshot = await FirebaseFirestore.instance.collection('documents').where('visibility', isEqualTo: 'public').get();
      }

      // Handle the documents snapshot
      documentsSnapshot.docs.forEach((doc) {
        print(doc.data());
      });
    }
  }
}

* */
