import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/features/pos_system/data/permission/pos_permission.dart';
import 'package:flutter/material.dart';

// Get name from enum
String _getValue(e) => EnumHelper<PosPermission>(e).getValue;

/// POS Navigation Links [POSTiles]
extension POSTiles on dynamic {
  List<DashboardTile> get posTiles {
    final tilesData = [
      {
        'label': 'orders',
        'icon': Icons.shopping_cart,
        'action': RouteNames.posOrders,
        'param': {},
        'access': _getValue(PosPermission.managePosOrders),
        'description':
            'place an order for a customer and then update its status.',
      },
      {
        'label': 'sales',
        'icon': Icons.shopping_basket,
        'action': RouteNames.posSales,
        'param': {},
        'access': _getValue(PosPermission.managePosSales),
        'description': 'keep track of, and oversee the progress of sales.',
      },
      {
        'label': 'report - Analytics',
        'icon': Icons.add_chart,
        'action': RouteNames.posReports,
        'param': {},
        'access': _getValue(PosPermission.viewPosReport),
        'description':
            'generate sales report, turnover rates, forecasts and performance analytics',
      },
      // Payments tab
      {
        'label': 'payment',
        'icon': Icons.payments_outlined,
        'action': RouteNames.posPayments,
        'param': {},
        'access': _getValue(PosPermission.managePosPayments),
        'description':
            'records payment details for each transaction: payment method and any related information',
      },
      // Receipt tab
      {
        'label': 'receipt',
        'icon': Icons.receipt,
        'action': RouteNames.posReceipt,
        'param': {},
        'access': _getValue(PosPermission.reprintReceipt),
        'description':
            'keep history of the creation and processing of receipts',
      },
      // Finance tab
      {
        'label': 'finance',
        'icon': Icons.money,
        'action': RouteNames.posPayments,
        'param': {},
        'access': _getValue(PosPermission.managePosFinance),
        'description':
            'Manages & analyzes company\'s financial resources; budgeting, forecasting, investing',
      },
    ];

    final defaultTiles = tilesData
        .map((e) => DashboardTile.fromMap(e))
        .toList();

    return defaultTiles;
  }

  /* rbc: Role Based Dashboard Tiles
  Map<EmployeeRole, List<DashboardTile>> get _rbcPOSTiles {
    final tilesData = [
      // Orders tab
      {
        'label': 'orders',
        'icon': Icons.shopping_cart,
        'action': RouteNames.posOrders,
        'param': {},
        'description':
            'place an order for a customer and then update its status.',
      },
      // POS tab
      {
        'label': 'sales',
        'icon': Icons.shopping_basket,
        'action': RouteNames.posSales,
        'param': {},
        'description': 'keep track of, and oversee the progress of sales.',
      },
      {
        'label': 'report - Analytics',
        'icon': Icons.add_chart,
        'action': RouteNames.posReports,
        'param': {},
        'description':
            'generate sales report, turnover rates, forecasts and performance analytics',
      },
      // Payments tab
      {
        'label': 'payment',
        'icon': Icons.payments_outlined,
        'action': RouteNames.posPayments,
        'param': {},
        'description':
            'records payment details for each transaction: payment method and any related information',
      },
      // Receipt tab
      {
        'label': 'receipt',
        'icon': Icons.receipt,
        'action': RouteNames.posReceipt,
        'param': {},
        'description':
            'keep history of the creation and processing of receipts',
      },
      // Finance tab
      {
        'label': 'finance',
        'icon': Icons.money,
        'action': RouteNames.posPayments,
        'param': {},
        'description':
            'Manages & analyzes company\'s financial resources; budgeting, forecasting, investing',
      },
    ];
    final defaultTiles = tilesData
        .map((e) => DashboardTile.fromMap(e))
        .toList();

    final posSalesTiles = defaultTiles[0];
    final posOrdersTiles = defaultTiles[1];
    final posReportAnalyticTiles = defaultTiles[2];
    final posPaymentTiles = defaultTiles[3];
    final posReceiptTiles = defaultTiles[4];
    final posFinanceTiles = defaultTiles[5];

    return {
      EmployeeRole.businessOwner: defaultTiles,
      EmployeeRole.manager: defaultTiles,
      EmployeeRole.developer: defaultTiles,
      EmployeeRole.sale: [posSalesTiles],
      EmployeeRole.cashier: [posPaymentTiles],
      EmployeeRole.procurement: [posOrdersTiles, posReceiptTiles],
      EmployeeRole.finance: [
        posFinanceTiles,
        posSalesTiles,
        posReceiptTiles,
        posReportAnalyticTiles,
      ],
    };
  }

  Map<EmployeeRole, RoleBasedDashboardTile<EmployeeRole>> get posTiles =>
      DashboardTileManager<EmployeeRole>(tiles: _rbcPOSTiles).create();*/
}
