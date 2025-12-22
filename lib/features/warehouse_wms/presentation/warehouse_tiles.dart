import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/network/data_sources/models/dashboard_model.dart';
import 'package:assign_erp/core/util/enum_helper.dart';
import 'package:assign_erp/features/warehouse_wms/data/permission/warehouse_permission.dart';
import 'package:flutter/material.dart';

/// Warehouse Management System App(WMS) Navigation Links [WarehouseTiles]
extension WarehouseTiles on dynamic {
  List<DashboardTile> get warehouseTiles {
    final tileData = [
      {
        'label': 'stocks',
        'icon': Icons.receipt_long,
        'action': RouteNames.warehouseProducts,
        'param': {'openTab': '0'},
        'access': _getName(WarehousePermission.manageWarehouse),
        'description': 'add inventory to the warehouse.',
      },
      {
        'label': 'supplies',
        'icon': Icons.shopping_cart,
        'action': RouteNames.warehouseSupply,
        'param': {'openTab': '1'},
        'access': _getName(WarehousePermission.manageWarehouse),
        'description': 'add supply products and update their status as needed.',
      },
      {
        'label': 'deliveries',
        'icon': Icons.delivery_dining,
        'action': RouteNames.warehouseDeliveries,
        'param': {'openTab': '2'},
        'access': _getName(WarehousePermission.manageWarehouse),
        'description':
            'create or add delivery of supplies and then update their status',
      },
    ];

    return tileData.map((e) => DashboardTile.fromMap(e)).toList();
  }
}

// Get name from enum
String _getName(e) => EnumHelper<WarehousePermission>(e).getName;
