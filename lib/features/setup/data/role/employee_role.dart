/*const appRoles = [
  'admin',
  'sales',
  'hr',
  'it',
  'auditor',
  'finance',
  'manager',
  'ceo',
];

const appPermissions = [
  'admin', // Full access
  'user', // Read-only access
  'sales', //
  'hr',
  'it',
  'auditor',
  'finance',
  'manager', // Create, read, update, delete (CRUD)
  'ceo',
];

enum EmployeeRole {
  /* 1- Full access to read, write, and execute operations.*/
  businessOwner,
  /* 2- Read and write access, suitable for overseeing team and project data.*/
  manager,
  /* 3- Full access to read, write, and handles the management of inventory levels, including stocking items, ordering new products, tracking stock levels*/
  stockControl,
  /* 4- Full access to read, write, and handles orders; Sales order, Purchase order, Request for quote, misc orders.*/
  procurement,
  /* 5- Read-only access, to assist with user support and troubleshooting.*/
  supportStaff,
  /* 6- Read-only access, suitable for auditing and compliance checks.*/
  auditor,
  /* 7- Read and write access, for analyzing and proposing system improvements.*/
  systemAnalyst,
  /* 8- Read-only access, to analyze and interpret data.*/
  dataAnalyst,
  /* 9- Read-only access, to ensure compliance with regulations.*/
  complianceOfficer,
  /* 10- Read and write access, to create and manage content.*/
  contentEditor,
  /* 11- Read and write access, for managing marketing campaigns and materials.*/
  marketing,
  /* 12- Read and write access, for handling financial data and transactions.*/
  finance,
  /* 13- Read and write access, for handling products or services sales.*/
  sale,
  /* 14- Read and write access, for handling payment.*/
  cashier,
  /* 15- Read and write access, for handling products delivery.*/
  delivery,
  /* 16- Read and write access, to manage employee records and HR processes.*/
  hrManager,
  /* 17- Read and write access, to resolve technical issues and maintain system settings.*/
  itSupport,
  /* 18 - Full access to read, write, and execute, for development tasks and managing code.*/
  developer,
  /* 19- Read-only access, primarily for testing purposes.*/
  tester,
  unknown,
}

/// Function to convert enum values to a list of strings [employeeRolesToList]

List<String> employeeRolesToList<T>() {
  // Convert the unmodifiable list to a modifiable list
  List<EmployeeRole> modifiableRoles = List.from(EmployeeRole.values);

  // Remove the unwanted roles
  modifiableRoles
    ..remove(EmployeeRole.developer)
    ..remove(EmployeeRole.tester);

  // Convert the modified list to a list of strings
  return modifiableRoles.map((e) => Employee.roleAsString(e)).toList();
}*/
