import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/enum_util.dart';
import 'package:assign_erp/features/system_admin/data/permission/setup_permission.dart';
import 'package:flutter/material.dart';

/// Settings Navigation Links [SetupTiles]
extension SetupTiles on dynamic {
  // Master data subRoutes
  List<DashboardTile> get masterDataTiles {
    final tilesData = [
      /*1️⃣ Item / Product Master
          Purpose: Define what the item is -Central definition of everything that can be stocked.
          Key objects:
          Items / Products
          Item Categories
          Units of Measure (UOM)
          Barcodes / SKUs
          Variants (size, color, model)
          Lot / Serial tracking flags
        📌 Shared across Sales, Procurement, POS, Manufacturing.
        =========================
        1️⃣ Item / Product Master
          Purpose: This module acts as the central repository for defining and categorizing all items/products that are stocked, sold, or procured.
          It’s essential for standardizing product information across all other ERP modules.

        Key Objects:
          Items / Products: Defines each individual item in the system.
          Item Categories: Group products by type (e.g., electronics, furniture, raw materials).
          Units of Measure (UOM): Defines how items are measured (e.g., pieces, kilograms, liters).
          Barcodes / SKUs: Unique identifiers for easy tracking and sales processing.
          Variants: Variations of a product like size, color, or model (e.g., “T-shirt (Large, Red)”).
          Lot / Serial Tracking Flags: Helps track inventory at a lot or serial number level for high-value or regulated items.
        Shared Across:
          Sales: Products defined here show up in catalogs and sales orders.
          Procurement: Products managed here are ordered and tracked.
          POS (Point of Sale): Items are identified and sold through POS systems.
          Manufacturing: Products can be raw materials or finished goods.
          Finance: Product costs and inventory valuation affect financial reporting.

        =========================
        /// NOTE: There'll be Horizonal-tabs under the Item/Product Master tab (for: Items Stocking, Expiry, Warranty start/end).
        */
      {
        'hasSplit': true,
        'label': 'Item . Master',
        'icon': Icons.inventory_2,
        'route': RouteNames.itemMaster,
        'param': {},
        'access': _getName(SetupPermission.manageItemMaster),
        'description':
            'Create, update, and manage inventory, SKUs, and attributes.',
      },
      {
        'hasSplit': true,
        'label': 'Tax . master',
        'icon': Icons.calculate,
        'route': RouteNames.taxMaster,
        'param': {},
        'access': _getName(SetupPermission.manageTaxes),
        'description':
            'Manage tax rates (VAT or sales tax). Apply them to items, services, and invoices as needed.',
      },
      {
        'hasSplit': true,
        'label': 'workflow . master',
        'icon': Icons.approval,
        'route': RouteNames.workflowMaster,
        'param': {},
        'access': _getName(SetupPermission.manageWorkflowApproval),
        'description':
            'Define & manage approval workflows that determine who can review, approve, or reject documents at each stage of the procurement process.',
        // 'description': 'Define and manage approval workflows by document type, role, and approval level to ensure proper authorization across your organization.',
      },
      {
        'hasSplit': true,
        'label': 'warehouse . master',
        'icon': Icons.store,
        'route': RouteNames.warehouseMaster,
        'param': {},
        'access': _getName(SetupPermission.manageWarehouseMaster),
        'description':
            'Define physical site or storage facilities such as Main, Store, or Transit warehouses.',
      },
      {
        'hasSplit': true,
        'label': 'storage loc . master',
        'icon': Icons.view_kanban,
        'route': RouteNames.warehouseLocationMaster,
        'param': {},
        'access': _getName(SetupPermission.manageWHLocationMaster),
        'description':
            'Create & organize warehouse sub-levels/divisions/locations: such as zones, aisles, racks, shelves, for structured storage segmentation.',
      },
      {
        'hasSplit': true,
        'label': 'storage bin . master',
        'icon': Icons.inbox,
        'route': RouteNames.warehouseBinMaster,
        'param': {},
        'access': _getName(SetupPermission.manageWHBinMaster),
        'description':
            'Create detailed storage bins & assign unique bin addresses within sub-locations to ensure precise stock placement & tracking.',
      },
      {
        'hasSplit': true,
        'label': 'Pricing & Discount master',
        'icon': Icons.price_change,
        'route': RouteNames.pricingDiscountMaster,
        'param': {},
        'access': _getName(SetupPermission.managePriceMaster),
        'description':
            'Configure and manage price lists, pricing rules, discount groups, and promotional pricing for sales and procurement.',
      },
      {
        'hasSplit': true,
        'label': 'Currency . master',
        'icon': Icons.currency_exchange,
        'route': RouteNames.currencyMaster,
        'param': {},
        'access': _getName(SetupPermission.manageCurrencyMaster),
        'description':
            'Manage supported currencies and exchange rate settings used across the system.',
      },
      {
        'hasSplit': true,
        'label': 'variants master',
        'icon': Icons.palette,
        'route': RouteNames.variantsMaster,
        'param': {},
        'access': _getName(SetupPermission.manageVariants),
        'description':
            'Easily manage items or services options, such as size, color, and material.',
      },
      {
        'hasSplit': true,
        'label': 'reference . master',
        'icon': Icons.link, // Icons.list_alt
        'route': RouteNames.referenceMaster,
        'param': {},
        'access': _getName(SetupPermission.referenceMaster),
        'description':
            'Manage item categories, units of measure, and other reference data used across the system.',
      },
      /*{
        'hasSplit': true,
        'label': 'Variants & Attributes',
        'icon': Icons.tune,
        'route': RouteNames.variantsMaster,
        'param': {'openTab': '1'},
        'access': _getName(SetupPermission.manageVariants),
        'description':
            'Configure item variants and attributes used for product definition and classification.',
      },
      {
        'hasSplit': true,
        'label': 'Units of . Measure',
        'icon': Icons.straighten,
        'route': RouteNames.uomMaster,
        'param': {'openTab': '2'},
        'access': _getName(SetupPermission.manageUOM),
        'description':
            'Define and manage units of measure used across transactions and inventory.',
      },*/
    ];

    return tilesData.map((e) => DashboardTile.fromMap(e)).toList();
  }

  /// Sub Menu Tiles under homeSetupTiles
  List<DashboardTile> get setupTiles {
    final tilesData = [
      {
        'hasSplit': true,
        'label': 'company . setup',
        'icon': Icons.home_work,
        'route': RouteNames.companyInfo,
        'param': {'openTab': '0'},
        'access': _getName(SetupPermission.manageCompany),
        'description': 'enter organization details: name, logo, address, etc.',
      },
      {
        'hasSplit': true,
        'label': 'Master . Data',
        'icon': Icons.storage,
        'route': RouteNames.coreMasterData,
        'param': {},
        'access': _getName(SetupPermission.manageMasterData),
        'description':
            'Manage core data: Item Master, Price Lists, UOM, Variants, Vendors, Taxes, Currencies, etc.',
      },
      {
        'label': 'employees',
        'icon': Icons.manage_accounts,
        'route': RouteNames.allEmployees,
        'param': {'openTab': '1'},
        'access': _getName(SetupPermission.manageEmployee),
        'description':
            'create & manage users permissions, roles, departments for their utilization of the software',
      },
      {
        'hasSplit': true,
        'label': 'roles . permissions',
        'icon': Icons.admin_panel_settings,
        'route': RouteNames.manageRoles,
        'param': {'openTab': '2'},
        'access': _getName(SetupPermission.manageRole),
        'description':
            'Create, edit, assign roles with specific permissions to control access within your team.',
      },
      {
        'label': 'backup',
        'icon': Icons.backup,
        'route': RouteNames.backup,
        'param': {'openTab': '3'},
        'access': _getName(SetupPermission.manageBackup),
        'description':
            'back up local and offline data to a cloud to access from anywhere',
      },
      /*{
        'label': 'license - renewal',
        'icon': Icons.local_police,
        'route': RouteNames.licenseRenewal,
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
String _getName(e) => EnumUtil<SetupPermission>(e).getName;
