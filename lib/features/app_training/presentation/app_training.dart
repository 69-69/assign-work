import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/dashboard_tile_card.dart';
import 'package:assign_erp/features/app_training/presentation/app_training_tiles.dart';
import 'package:flutter/material.dart';

class AppTraining extends StatelessWidget {
  const AppTraining({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      isGradientBg: true,
      title: appTrainingAppTitle,
      tiles: appTrainingTiles,
      body: DashboardTileCard(tiles: appTrainingTiles),
    );
  }
}
