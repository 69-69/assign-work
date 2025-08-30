import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/setup/data/permission/setup_permission.dart';
import 'package:flutter/material.dart';

/// Settings Navigation Links [SetupTiles]
extension SetupTiles on dynamic {
  /// [homeSetupTiles] Used for system setup and configuration of Tenant organization\'s workspace
  get homeSetupTiles => {
    'label': 'setup',
    'icon': Icons.settings,
    'action': RouteNames.setupApp,
    'param': {},
    'access': _getValue(SetupPermission.manageSetup),
    'description':
        'company, employees, accounts, backups, licensing, & software update',
  };

  List<DashboardTile> get setupTiles {
    final tilesData = [
      {
        'label': 'company',
        'icon': Icons.home_work,
        'action': RouteNames.companyInfo,
        'param': {'openTab': '0'},
        'access': _getValue(SetupPermission.manageCompany),
        'description': 'enter organization details; name, logo, address, etc.',
      },
      {
        'label': 'employees',
        'icon': Icons.manage_accounts,
        'action': RouteNames.allEmployees,
        'param': {'openTab': '1'},
        'access': _getValue(SetupPermission.manageEmployee),
        'description':
            'create staff attendance, accounts, assign roles for their utilization of the software',
      },
      {
        'label': 'roles - permissions',
        'icon': Icons.admin_panel_settings,
        'action': RouteNames.manageRoles,
        'param': {'openTab': '2'},
        'access': _getValue(SetupPermission.manageRole),
        'description':
            'Create, edit, assign roles with specific permissions to control access within your team.',
      },
      {
        'label': 'Tax - Rates',
        'icon': Icons.calculate,
        'action': RouteNames.manageTaxes,
        'param': {'openTab': '3'},
        'access': _getValue(SetupPermission.manageTaxes),
        'description':
            'Manage tax rates (VAT or sales tax). Apply them to items, services, and invoices as needed.',
      },
      {
        'label': 'Product - config',
        'icon': Icons.category,
        'action': RouteNames.productConfig,
        'param': {'openTab': '4'},
        'access': _getValue(SetupPermission.manageItemCategory),
        'description':
            "add suppliers & product categories to fit the company's specific needs",
      },
      {
        'label': 'back - up',
        'icon': Icons.backup,
        'action': RouteNames.backup,
        'param': {'openTab': '5'},
        'access': _getValue(SetupPermission.manageBackup),
        'description':
            'back up local and offline data to a cloud to access from anywhere',
      },
      {
        'label': 'license - renewal',
        'icon': Icons.local_police,
        'action': RouteNames.licenseRenewal,
        'param': {'openTab': '6'},
        'access': _getValue(SetupPermission.viewLicense),
        'description':
            'renew and activate software licenses, and view the history of previous licenses',
      },
    ];

    // return tilesData.map((e) => DashboardTile.fromMap(e)).toList();
    return tilesData.map((e) => DashboardTile.fromMap(e)).toList();
  }
}

// Get name from enum
String _getValue(e) => getEnumName<SetupPermission>(e);
