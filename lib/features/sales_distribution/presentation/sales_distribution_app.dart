import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/dashboard_tile_card.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:assign_erp/features/sales_distribution/presentation/sales_distribution_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesDistributionApp extends StatelessWidget {
  const SalesDistributionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildBody();
    /*MINE-STEVE
    return BlocProvider(
      create: (context) => AuthBloc(
        authRepository: RepositoryProvider.of<AuthRepository>(context),
      ),
      child: _buildBody(),
    );*/
  }

  BlocBuilder<AuthBloc, AuthState> _buildBody() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return CustomScaffold(
          isGradientBg: true,
          title: salesDistributionAppTitle,
          tiles: salesDistributionTiles,
          body: _buildDashboard(context),
        );
      },
    );
  }

  Widget _buildDashboard(BuildContext context) {
    /* Role Based Access Control
    final employee = context.employee;
    final tiles = [...?salesDistributionTiles[employee?.role]?.tiles]; */
    return DashboardTileCard(
      tiles: salesDistributionTiles,
      metricsTitle: "Sales Distribution Metrics",
      metricsSubtitle: "Metrics for Sales Distribution",
      metrics: {
        "Pending": 34,
        "Processing": 34,
        "Production": 34,
        "To Be Shipped": 18,
        "Delivered": 210,
        "Current Stock": 780,
        "Completed": 192,
        "Cancelled": 5,
        "Returned": 5,
      },
    );
  }
}
