import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/constants/main_modules.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/network/data_sources/models/subscription_licenses_enum.dart';
import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/features/system_admin/data/permission/setup_permission.dart';
import 'package:flutter/material.dart';

/// Returns a list of Main-Dashboard-Tiles based on the specified license package [LicenseTiles]
extension LicenseTiles on BuildContext {
  /// Main Home Dashboard
  List<DashboardTile> get licenseTiles {
    final appPackages = [
      // Inventory Package
      {
        'label': MainModuleId.invent.getLabel,
        'icon': MainModuleId.invent.getIcon,
        'action': RouteNames.inventoryApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.inventory),
        'description':
            'Manage stock levels, track items, and oversee warehouse operations.',
      },
      // Procurement Package
      {
        'hasSplit': true,
        'label': MainModuleId.procure.getLabel,
        'icon': MainModuleId.procure.getIcon,
        'action': RouteNames.procurementApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.procurement),
        'description':
            'Oversee purchasing, track orders, and manage supplier data.',
      },
      // POS Package
      {
        'label': MainModuleId.pos.getLabel,
        'icon': MainModuleId.pos.getIcon,
        'action': RouteNames.posApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.pos),
        'description':
            'Handle retail transactions, sales, and customer checkouts.',
      },
      // Sales Distribution Package
      {
        'hasSplit': true,
        'label': MainModuleId.sales.getLabel,
        'icon': MainModuleId.sales.getIcon,
        'action': RouteNames.salesDistributionApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.salesDistribution),
        'description': 'Manage sales orders, deliveries, and tracking.',
      },
      // Warehouse Package
      {
        'label': MainModuleId.warehouse.getLabel,
        'icon': MainModuleId.warehouse.getIcon,
        'action': RouteNames.warehouseApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.warehouse),
        'description':
            'Manage warehouse operations, stock movement, and storage locations.',
      },
      // Customer Package
      {
        'label': MainModuleId.crm.getLabel,
        'icon': MainModuleId.crm.getIcon,
        'action': RouteNames.customersApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.crm),
        'description':
            'Manage customer relationships, profiles, and communication history.',
      },

      /// Not-A-License - Only used for system setup and configuration of Tenant organization\'s workspace
      {
        'hasSplit': true,
        'label': MainModuleId.system.getLabel,
        'icon': MainModuleId.system.getIcon,
        'action': RouteNames.systemAdminApp,
        'param': {},
        'access': EnumHelper<SetupPermission>(
          SetupPermission.manageSetup,
        ).getName,
        'description':
            'system settings, configs, company, backups, and general maintenance',
        // 'company, employees, taxes, roles, permissions, backups, licensing',
      },
      {
        'hasSplit': true,
        'label': MainModuleId.guide.getLabel,
        'icon': MainModuleId.guide.getIcon,
        'action': RouteNames.userGuideApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.paidTraining),
        'description':
            'Video guides: setting up & managing key parts of the software',
      },
      // Live Chat Support Package
      {
        'label': MainModuleId.support.getLabel,
        'icon': MainModuleId.support.getIcon,
        'action': RouteNames.liveChatSupport,
        'param': {},
        'access': _getName(SubscriptionLicenses.paidTraining),
        'description': 'Get 24/7 live chat support from our agents and experts',
      },
      // Agent Package
      {
        'label': MainModuleId.agent.getLabel,
        'icon': MainModuleId.agent.getIcon,
        'action': RouteNames.agent,
        'param': {},
        'access': _getName(SubscriptionLicenses.agent),
        'description': 'setup, oversee, and monitor workspaces for clients',
      },
      // Troubleshoot Package
      {
        'label': MainModuleId.trouble.getLabel,
        'icon': MainModuleId.trouble.getIcon,
        'action': RouteNames.troubleShootingApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.dev),
        'description':
            'Provides access to troubleshooting tools and diagnostics.',
      },
    ];

    /*final visiblePackages = appPackages.where((tile) {
      final access = tile['access'] as String?;
      return access == null || isLicensed(access);
    }).toList();*/

    return appPackages.map((e) => DashboardTile.fromMap(e)).toList();
  }
}

// Get name from enum
String _getName(SubscriptionLicenses e) =>
    EnumHelper<SubscriptionLicenses>(e).getName;
