import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/inventory_ims/data/permission/inventory_permission.dart';
import 'package:flutter/material.dart';

/// Inventory Management System App(IMS) Dashboard tiles [InventoryTiles]
extension InventoryTiles on dynamic {
  // All Orders types Navigation Links [ordersTiles]
  List<DashboardTile> get ordersTiles {
    final tilesData = [
      {
        'label': 'sales - order',
        'icon': Icons.trending_up,
        'action': RouteNames.salesOrders,
        'param': {},
        'access': _getValue(InventoryPermission.manageSOs),
        'description': 'Create orders for customers or clients',
      },
      {
        'label': 'purchase - order',
        'icon': Icons.paypal,
        'action': RouteNames.imsPurchaseOrders,
        'param': {},
        'access': _getValue(InventoryPermission.managePOs),
        'description': 'generate POs to suppliers to request goods or services',
      },
      {
        'label': 'misc - order',
        'icon': Icons.payments_outlined,
        'action': RouteNames.miscOrders,
        'param': {},
        'access': _getValue(InventoryPermission.manageMOs),
        'description':
            'create additional orders that may include special requests, one-time purchases',
      },
      {
        'label': 'request - for quotes',
        'icon': Icons.request_page_outlined,
        'action': RouteNames.imsRequestForQuote,
        'param': {},
        'access': _getValue(InventoryPermission.manageRFQs),
        'description':
            'create quotation requests to suppliers for pricing and terms',
      },
    ];

    return tilesData.map((e) => DashboardTile.fromMap(e)).toList();
  }

  List<DashboardTile> get inventoryTiles {
    final tilesData = [
      // items tab
      {
        'label': 'stocks',
        'icon': Icons.receipt_long,
        'action': RouteNames.items,
        'param': {},
        'access': _getValue(InventoryPermission.manageStock),
        'description': 'add or create new items to the inventory.',
      },
      // orders tab
      {
        'label': 'orders',
        'icon': Icons.shopping_cart,
        'action': RouteNames.orders,
        'param': {},
        'access': _getValue(InventoryPermission.manageOrders),
        'description':
            'create purchase orders (POs), sales orders (SOs), and miscellaneous orders (MOs) for suppliers or customers',
      },
      {
        'label': 'Item Categories',
        'icon': Icons.dashboard_customize_outlined,
        'action': RouteNames.itemCategories,
        'param': {},
        'access': _getValue(InventoryPermission.manageItemCategory),
        'description':
            'Organize items into categories for easier tracking and reporting.',
      },
      {
        'label': 'Item Suppliers',
        'icon': Icons.local_shipping,
        'action': RouteNames.itemSuppliers,
        'param': {},
        'access': _getValue(InventoryPermission.manageItemSuppliers),
        'description':
            'Manage suppliers linked to specific items for sourcing and restocking.',
      },
      // deliveries tab
      {
        'label': 'deliveries',
        'icon': Icons.delivery_dining,
        'action': RouteNames.deliveries,
        'param': {},
        'access': _getValue(InventoryPermission.manageDeliveries),
        'description':
            'add or create delivery of order(s) and update their status.',
      },
      // sales tab
      {
        'label': 'sales',
        'icon': Icons.shopping_basket,
        'action': RouteNames.sales,
        'param': {},
        'access': _getValue(InventoryPermission.manageSales),
        'description': 'keep track of, and oversee the progress of sales.',
      },
      // credit/debit cards, mobile payments, and cash tabs
      {
        'label': 'payment',
        'icon': Icons.payments_outlined,
        'action': RouteNames.posPayments,
        'param': {},
        'access': _getValue(InventoryPermission.manageOrders),
        'description':
            'records payment details for each transaction: payment method and any related information',
      },
      // finance tab
      {
        'label': 'finance',
        'icon': Icons.money,
        'action': RouteNames.posPayments,
        'param': {},
        'access': _getValue(InventoryPermission.manageOrders),
        'description':
            'Manages & analyzes company\'s financial resources; budgeting, forecasting, investing',
      },
      // invoice tab
      {
        'label': 'invoice',
        'icon': Icons.receipt,
        'action': RouteNames.invoice,
        'param': {},
        'access': _getValue(InventoryPermission.viewInvoice),
        'description':
            'keep history of the creation and processing of receipts',
      },
      // report analytics tab
      {
        'label': 'report - Analytics',
        'icon': Icons.add_chart,
        'action': RouteNames.inventReports,
        'param': {},
        'access': _getValue(InventoryPermission.viewReport),
        'description':
            'generate sales reports, inventory status, turnover rates, forecasts, and performance analytics',
      },
      // tracking tab
      {
        'label': 'tracking',
        'icon': Icons.location_on,
        'action': RouteNames.ordersTracking,
        'param': {},
        'access': _getValue(InventoryPermission.manageOrders),
        'description': 'monitor the progress of order placement and deliveries',
      },
    ];
    final defaultTiles = tilesData
        .map((e) => DashboardTile.fromMap(e))
        .toList();

    return defaultTiles;
  }

  /*/// Returns a list of Inventory-Dashboard-Tiles based on the Inventory license [inventoryTiles]
  Map<EmployeeRole, List<DashboardTile>> get _rbcInventoryTiles {
    final tilesData = [
      // products tab
      {
        'label': 'stocks',
        'icon': Icons.receipt_long,
        'action': RouteNames.products,
        'param': {},
        'access': InventoryPermission.manageStock.name,
        'description': 'add or create new products to the inventory.',
      },
      // orders tab
      {
        'label': 'orders',
        'icon': Icons.shopping_cart,
        'action': RouteNames.orders,
        'param': {},
        'access': InventoryPermission.manageOrders.name,
        'description':
            'create purchase orders (POs), sales orders (SOs), and miscellaneous orders for suppliers or customers',
      },
      // deliveries tab
      {
        'label': 'deliveries',
        'icon': Icons.delivery_dining,
        'action': RouteNames.deliveries,
        'param': {},
        'access': InventoryPermission.manageDeliveries.name,
        'description':
            'add or create delivery of order(s) and update their status.',
      },
      // sales tab
      {
        'label': 'sales',
        'icon': Icons.shopping_basket,
        'action': RouteNames.sales,
        'param': {},
        'access': InventoryPermission.manageSales.name,
        'description': 'keep track of, and oversee the progress of sales.',
      },
      // credit/debit cards, mobile payments, and cash tabs
      {
        'label': 'payment',
        'icon': Icons.payments_outlined,
        'action': RouteNames.posPayments,
        'param': {},
        'access': InventoryPermission.manageOrders.name,
        'description':
            'records payment details for each transaction: payment method and any related information',
      },
      // finance tab
      {
        'label': 'finance',
        'icon': Icons.money,
        'action': RouteNames.posPayments,
        'param': {},
        'access': InventoryPermission.manageOrders.name,
        'description':
            'Manages & analyzes company\'s financial resources; budgeting, forecasting, investing',
      },
      // invoice tab
      {
        'label': 'invoice',
        'icon': Icons.receipt,
        'action': RouteNames.invoice,
        'param': {},
        'access': InventoryPermission.viewInvoice.name,
        'description':
            'keep history of the creation and processing of receipts',
      },
      // report analytics tab
      {
        'label': 'report - Analytics',
        'icon': Icons.add_chart,
        'action': RouteNames.inventReports,
        'param': {},
        'access': InventoryPermission.viewReport.name,
        'description':
            'generate sales reports, inventory status, turnover rates, forecasts, and performance analytics',
      },
      // tracking tab
      {
        'label': 'tracking',
        'icon': Icons.location_on,
        'action': RouteNames.ordersTracking,
        'param': {},
        'access': InventoryPermission.manageOrders.name,
        'description': 'monitor the progress of order placement and deliveries',
      },
    ];
    final defaultTiles = tilesData
        .map((e) => DashboardTile.fromMap(e))
        .toList();

    final productsTile = defaultTiles[0];
    final ordersTile = defaultTiles[1];
    final deliveriesTile = defaultTiles[2];
    final salesTile = defaultTiles[3];
    final paymentTile = defaultTiles[4];
    final financeTile = defaultTiles[5];
    final invoiceTile = defaultTiles[6];
    final reportAnalyticsTile = defaultTiles[7];

    // Role Based Access Control
    return {
      EmployeeRole.businessOwner: defaultTiles,
      EmployeeRole.manager: defaultTiles,
      EmployeeRole.sale: [salesTile],
      EmployeeRole.developer: defaultTiles,
      EmployeeRole.cashier: [paymentTile],
      EmployeeRole.delivery: [deliveriesTile],
      EmployeeRole.stockControl: [productsTile],
      EmployeeRole.procurement: [ordersTile, invoiceTile],
      EmployeeRole.finance: [
        financeTile,
        salesTile,
        invoiceTile,
        reportAnalyticsTile,
      ],
    };
  }

  Map<EmployeeRole, RoleBasedDashboardTile<EmployeeRole>> get inventoryTiles =>
      DashboardTileManager<EmployeeRole>(tiles: _rbcInventoryTiles).create();*/
}

// Get name from enum
String _getValue(e) => getEnumName<InventoryPermission>(e);
