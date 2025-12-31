import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/features/system_admin/data/permission/setup_permission.dart';
import 'package:flutter/material.dart';

/// Settings Navigation Links [SetupTiles]
extension SetupTiles on dynamic {
  /// Sub Menu Tiles under homeSetupTiles
  List<DashboardTile> get setupTiles {
    final tilesData = [
      {
        'label': 'company . setup',
        'icon': Icons.home_work,
        'action': RouteNames.companyInfo,
        'param': {'openTab': '0'},
        'access': _getName(SetupPermission.manageCompany),
        'description': 'enter organization details; name, logo, address, etc.',
      },
      {
        'label': 'employees',
        'icon': Icons.manage_accounts,
        'action': RouteNames.allEmployees,
        'param': {'openTab': '1'},
        'access': _getName(SetupPermission.manageEmployee),
        'description':
            'create staff attendance, accounts, assign roles for their utilization of the software',
      },
      {
        'label': 'roles . permissions',
        'icon': Icons.admin_panel_settings,
        'action': RouteNames.manageRoles,
        'param': {'openTab': '2'},
        'access': _getName(SetupPermission.manageRole),
        'description':
            'Create, edit, assign roles with specific permissions to control access within your team.',
      },
      {
        'label': 'workflow . approval rules',
        'icon': Icons.approval,
        'action': RouteNames.workflowApprovalRules,
        'param': {'openTab': '3'},
        'access': _getName(SetupPermission.manageWorkflowApproval),
        'description':
            'Define & manage approval workflows that determine who can review, approve, or reject documents at each stage of the procurement process.',
        // 'description': 'Define and manage approval workflows by document type, role, and approval level to ensure proper authorization across your organization.',
      },
      {
        'label': 'Tax . Rates',
        'icon': Icons.calculate,
        'action': RouteNames.manageTaxes,
        'param': {'openTab': '4'},
        'access': _getName(SetupPermission.manageTaxes),
        'description':
            'Manage tax rates (VAT or sales tax). Apply them to items, services, and invoices as needed.',
      },
      {
        'label': 'Items . Preference',
        'icon': Icons.category,
        'action': RouteNames.productConfig,
        'param': {'openTab': '5'},
        'access': _getName(SetupPermission.manageItemCategory),
        'description':
            'Customize item categories, units of measure, and other preferences for inventory management.',
      },
      {
        'label': 'backup',
        'icon': Icons.backup,
        'action': RouteNames.backup,
        'param': {'openTab': '6'},
        'access': _getName(SetupPermission.manageBackup),
        'description':
            'back up local and offline data to a cloud to access from anywhere',
      },
      /*{
        'label': 'license - renewal',
        'icon': Icons.local_police,
        'action': RouteNames.licenseRenewal,
        'param': {'openTab': '6'},
        'access': _getName(SetupPermission.viewLicense),
        'description':
            'renew and activate software licenses, and view the history of previous licenses',
      },*/
    ];

    // return tilesData.map((e) => DashboardTile.fromMap(e)).toList();
    return tilesData.map((e) => DashboardTile.fromMap(e)).toList();
  }
}

// Get name from enum
String _getName(e) => EnumHelper<SetupPermission>(e).getName;
