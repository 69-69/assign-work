import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/features/customer_crm/data/permission/crm_permission.dart';
import 'package:flutter/material.dart';

/// Customer Management System App(IMS) Navigation Links [CustomerTiles]
extension CustomerTiles on dynamic {
  /// Sub Menu Tiles under Customer Dashboard
  List<DashboardTile> get customerTiles {
    final tilesData = [
      {
        'hasSplit': true,
        'label': 'manage - account',
        'icon': Icons.group,
        'route': RouteNames.createCustomer,
        'param': {'openTab': '0'},
        'access': CrmPermission.createCustomer.name,
        'description':
            'Create a new customer account, modify, or remove it as needed',
      },
      {
        'label': 'activities',
        'icon': Icons.account_tree,
        'route': RouteNames.createCustomer,
        'param': {'openTab': '1'},
        'access': CrmPermission.viewLeads.name,
        'description': 'track customer activities throughout the software',
      },
      {
        'hasSplit': true,
        'label': 'Statement - of Account',
        'icon': Icons.pending_actions,
        'route': RouteNames.createCustomer,
        'param': {'openTab': '2'},
        'access': CrmPermission.viewCustomerProfile.name,
        'description':
            'Statement detailing purchases, outstanding balances, and due dates',
      },
    ];

    final defaultTiles = tilesData
        .map((e) => DashboardTile.fromMap(e))
        .toList();
    return defaultTiles;
  }

  /*   // rbc: Role Based Access Control (RBAC)
  Map<EmployeeRole, List<DashboardTile>> get _rbcCRMTiles {
    final tilesData = [
      {
        'label': 'manage - account',
        'icon': Icons.group,
        'route': RouteNames.createCustomer,
        'param': {'openTab': '0'},
        'description':
            'Create a new customer account, modify, or remove it as needed',
      },
      {
        'label': 'activities',
        'icon': Icons.account_tree,
        'route': RouteNames.createCustomer,
        'param': {'openTab': '1'},
        'description': 'track customer activities throughout the software',
      },
      {
        'label': 'Statement - of Account',
        'icon': Icons.pending_actions,
        'route': RouteNames.createCustomer,
        'param': {'openTab': '2'},
        'description':
            'Statement detailing purchases, outstanding balances, and due dates',
      },
    ];

    final defaultTiles = tilesData
        .map((e) => DashboardTile.fromMap(e))
        .toList();

    final activityTile = DashboardTile.filter(defaultTiles, ['activities']);
    final statementTile = DashboardTile.filter(defaultTiles, ['activities']);

    return {
      EmployeeRole.businessOwner: defaultTiles,
      EmployeeRole.manager: defaultTiles,
      EmployeeRole.developer: defaultTiles,
      EmployeeRole.sale: defaultTiles,
      EmployeeRole.finance: defaultTiles,
      EmployeeRole.supportStaff: activityTile,
      EmployeeRole.marketing: activityTile,
      EmployeeRole.auditor: statementTile,
      EmployeeRole.systemAnalyst: defaultTiles,
      EmployeeRole.dataAnalyst: defaultTiles,
      EmployeeRole.complianceOfficer: defaultTiles,
      EmployeeRole.contentEditor: defaultTiles,
      EmployeeRole.delivery: defaultTiles,
      EmployeeRole.hrManager: defaultTiles,
      EmployeeRole.itSupport: defaultTiles,
      EmployeeRole.tester: defaultTiles,
      EmployeeRole.stockControl: [],
      EmployeeRole.cashier: [],
      EmployeeRole.procurement: [],
    };
  }

  Map<EmployeeRole, RoleBasedDashboardTile<EmployeeRole>> get customerTiles =>
      DashboardTileManager<EmployeeRole>(tiles: _rbcCRMTiles).create();*/
}
