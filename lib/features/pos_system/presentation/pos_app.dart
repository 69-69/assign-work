import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/dashboard_tile_card.dart';
import 'package:assign_erp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/pos_tiles.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/orders/widget/group_btn_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class POSApp extends StatelessWidget {
  const POSApp({super.key});

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
          title: posAppTitle,
          tiles: posTiles,
          body: _buildDashboard(context),
          floatingActionBtnLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: context.buildPOSGroupBtn(),
        );
      },
    );
  }

  Widget _buildDashboard(BuildContext context) {
    /* Role Based Access Control
    final employee = context.employee;
    final tiles = [...?posTiles[employee?.role]?.tiles]; */

    return DashboardTileCard(
      tiles: posTiles,
      metricsTitle: "POS Metrics",
      metricsSubtitle: "Track sales, revenue, refunds, and daily transactions.",
      metrics: {
        "Total Sales": 34,
        "Daily Sales": 34,
        "Monthly Revenue": 34,
        "Refunds": 210,
        "Top Item": 780,
        "customers Today": 5,
      },
    );
  }
}
