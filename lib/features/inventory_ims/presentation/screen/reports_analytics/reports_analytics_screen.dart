import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/item/item_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/reports_analytics/widget/report_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportsAnalyticsScreen extends StatelessWidget {
  final String openTab;

  const ReportsAnalyticsScreen({super.key, this.openTab = '0'});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemBloc, InventoryState<Item>>(
      builder: (context, state) => CustomScaffold(
        title: reportsAnalyticsScreenTitle.toUpperAll,
        subTitle: 'Inventory, sales, turnover, and forecast reports',
        body: const ReportScreen(),
        actions: const [],
      ),
    );
  }

  /*CustomTab _buildBody() {
    final openThisTab = int.tryParse(openTab) ?? 0;

    return CustomTab(
      openThisTab: openThisTab,
      length: 2,
      tabs: const [
        {'label': 'Product Report', 'icon': Icons.analytics},
        {'label': 'Sales Report', 'icon': Icons.analytics},
      ],
      children: const [
        Center(child: Text('Product Report')),
        Center(child: Text('Sales Report')),
      ],
    );
  }*/
}
