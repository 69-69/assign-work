import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/dashboard_tile_card.dart';
import 'package:assign_erp/features/procurement/presentation/procurement_tiles.dart';
import 'package:flutter/material.dart';

class ProSupplierManagementScreen extends StatelessWidget {
  const ProSupplierManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      isGradientBg: true,
      title: supplierManagementScreenTitle.toUpperAll,
      body: DashboardTileCard(tiles: supplierManagementTiles),
    );
  }
}
