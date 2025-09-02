import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/dashboard_tile_card.dart';
import 'package:assign_erp/features/inventory_ims/presentation/inventory_tiles.dart';
import 'package:flutter/material.dart';

/// All ORDERS: Sales Order, purchase Order & Misc Order
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      isGradientBg: true,
      title: allOrderScreenTitle.toUpperAll,
      body: DashboardTileCard(tiles: ordersTiles),
    );
  }
}
