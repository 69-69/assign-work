import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/dashboard_tile_card.dart';
import 'package:assign_erp/features/system_admin/presentation/setup_tiles.dart';
import 'package:flutter/material.dart';

class SetupApp extends StatelessWidget {
  const SetupApp({super.key});

  @override
  Widget build(BuildContext context) {
    /*final user = context.read<AuthBloc>().state.user;

    // Assuming you extract the user's setup permissions from user.roles or user.permissions
    final setupPermissions = user.permissions
        .whereType<SetupPermission>()
        .toList();

    final filteredTiles = filterTilesByPermissions<SetupPermission>(
      setupTiles, // your extension
      setupPermissions,
    );*/

    return CustomScaffold(
      isGradientBg: true,
      title: systemAdminAppTitle,
      tiles: setupTiles,
      body: DashboardTileCard(tiles: setupTiles),
    );
  }
}
