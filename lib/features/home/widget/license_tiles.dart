import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/network/data_sources/models/subscription_licenses_enum.dart';
import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/features/system_admin/presentation/setup_tiles.dart';
import 'package:flutter/material.dart';

/// Returns a list of Main-Dashboard-Tiles based on the specified license package [LicenseTiles]
extension LicenseTiles on BuildContext {
  /// Main Home Dashboard
  List<DashboardTile> get licenseTiles {
    final appPackages = [
      // Inventory Package
      {
        'label': 'inventory',
        'icon': Icons.inventory_sharp,
        'action': RouteNames.inventoryApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.inventory),
        'description':
            'Manage stock levels, track items, and oversee warehouse operations.',
      },
      // Procurement Package
      {
        'label': 'procurement & supplier',
        'icon': Icons.add_shopping_cart,
        'action': RouteNames.procurementApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.procurement),
        'description':
            'Oversee purchasing, track orders, and manage supplier data.',
      },
      // POS Package
      {
        'label': 'POS',
        'icon': Icons.point_of_sale,
        'action': RouteNames.posApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.pos),
        'description':
            'Handle retail transactions, sales, and customer checkouts.',
      },
      // Sales Distribution Package
      {
        'label': 'sales & distribution',
        'icon': Icons.local_shipping,
        'action': RouteNames.salesDistributionApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.salesDistribution),
        'description': 'Manage sales orders, deliveries, and tracking.',
      },
      // Warehouse Package
      {
        'label': 'warehouse',
        'icon': Icons.warehouse,
        'action': RouteNames.warehouseApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.warehouse),
        'description':
            'Manage warehouse operations, stock movement, and storage locations.',
      },
      // Customer Package
      {
        'label': 'crm',
        'icon': Icons.group,
        'action': RouteNames.customersApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.crm),
        'description':
            'Manage customer relationships, profiles, and communication history.',
      },

      /// Not-A-License - Only used for system setup and configuration of Tenant organization\'s workspace.
      homeSetupTiles,
      {
        'label': 'user . guide',
        'icon': Icons.library_books,
        'action': RouteNames.userGuideApp,
        'param': {},
        'access': _getName(SubscriptionLicenses.training),
        'description':
            'Video guides: setting up & managing key parts of the software',
      },
      // Live Chat Support Package
      {
        'label': 'support . (Live Chat)',
        'icon': Icons.support_agent,
        'action': RouteNames.liveChatSupport,
        'param': {},
        'access': _getName(SubscriptionLicenses.training),
        'description': 'Get 24/7 live chat support from our agents and experts',
      },
      // Agent Package
      {
        'label': 'agent',
        'icon': Icons.real_estate_agent_outlined,
        'action': RouteNames.agent,
        'param': {},
        'access': _getName(SubscriptionLicenses.agent),
        'description': 'setup, oversee, and monitor workspaces for clients',
      },
      // Troubleshoot Package
      {
        'label': 'troubleshoot',
        'icon': Icons.troubleshoot,
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
String _getName(e) => EnumHelper<SubscriptionLicenses>(e).getName;

/*extension LicenseTiles on dynamic {
  Map<SubscriptionLicenses, List<DashboardTile>> get _licensePackages {
    /// Agent / Developer license (includes all individual packages plus agent/dev package)
    final appPackages = [
      // Agent Package
      {
        'label': 'agent',
        'icon': Icons.real_estate_agent_outlined,
        'action': RouteNames.agent,
        'param': {},
        'access': SubscriptionLicenses.agent.name,
        'description': 'setup, oversee, and monitor workspaces for clients',
      },
      // Inventory Package
      {
        'label': 'inventory',
        'icon': Icons.inventory_sharp,
        'action': RouteNames.inventoryApp,
        'param': {},
        'access': SubscriptionLicenses.inventory.name,
        'description': 'stocks, orders, deliveries, sales, invoices, tracking',
      },
      // POS Package
      {
        'label': 'pos',
        'icon': Icons.point_of_sale,
        'action': RouteNames.posApp,
        'param': {},
        'access': SubscriptionLicenses.pos.name,
        'description':
            'Provides access to point of sale tools for transaction processing and sales management.',
      },
      // Warehouse Package
      {
        'label': 'warehouse',
        'icon': Icons.warehouse,
        'action': RouteNames.warehouseApp,
        'param': {},
        'access': SubscriptionLicenses.warehouse.name,
        'description':
            'Grants access to warehouse management tools for inventory control and order processing.',
      },
      // Customer Package
      {
        'label': 'crm',
        'icon': Icons.group,
        'action': RouteNames.customersApp,
        'param': {},
        'access': SubscriptionLicenses.crm.name,
        'description':
            'Provides access to CRM features for managing customer interactions, sales, and support.',
      },
      // Troubleshoot Package
      {
        'label': 'troubleshoot',
        'icon': Icons.troubleshoot,
        'action': RouteNames.troubleShootingApp,
        'param': {},
        'access': SubscriptionLicenses.dev.name,
        'description':
            'Provides access to troubleshooting tools and diagnostics.',
      },
      {
        'label': 'user - guide',
        'icon': Icons.library_books,
        'action': RouteNames.userGuideApp,
        'param': {},
        'access': SubscriptionLicenses.training.name,
        'description':
            'Video guides: setting up & managing key parts of the software',
      },
    ];

    final defaultPackages = appPackages
        .map((e) => DashboardTile.fromMap(e))
        .toList();

    // Index references for clarity
    final inventoryAppPackage = defaultPackages[1];
    final posAppPackage = defaultPackages[2];
    final warehouseAppPackage = defaultPackages[3];
    final customerAppPackage = defaultPackages[4];
    final liveChatSupport = defaultPackages[6];
    // Agent: excludes troubleshoot & live support
    final agentAppPackage = DashboardTile.filter(defaultPackages, [
      'troubleshoot',
      'live chat support',
    ], exclude: true);

    // Subscription Licenses Package Restrictions
    return {
      SubscriptionLicenses.onboarding: [],

      SubscriptionLicenses.dev: defaultPackages,

      SubscriptionLicenses.agent: agentAppPackage,

      SubscriptionLicenses.pos: [posAppPackage, liveChatSupport],

      SubscriptionLicenses.crm: [customerAppPackage, liveChatSupport],

      SubscriptionLicenses.inventory: [inventoryAppPackage, liveChatSupport],

      SubscriptionLicenses.warehouse: [warehouseAppPackage, liveChatSupport],

      SubscriptionLicenses.full: [
        inventoryAppPackage,
        posAppPackage,
        warehouseAppPackage,
        customerAppPackage,
        liveChatSupport,
      ],
    };
  }

  /// Returns structured dashboard tiles based on the license type.
  Map<SubscriptionLicenses, RoleBasedDashboardTile<SubscriptionLicenses>>
  get licenseTiles => DashboardTileManager<SubscriptionLicenses>(
    tiles: _licensePackages,
  ).create();
}*/
