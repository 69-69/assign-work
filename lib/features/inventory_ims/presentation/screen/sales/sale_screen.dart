import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/data/models/sale_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/sales/sale_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/sales/create/create_sale.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/sales/list/list_sales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SaleScreen extends StatelessWidget {
  const SaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaleBloc, InventoryState<Sale>>(
      builder: (context, state) => CustomScaffold(
        title: salesScreenTitle.toUpperAll,
        body: _buildBody(),
        floatingActionButton: context.buildFloatingBtn(
          'add sales',
          onPressed: () => context.openAddSales(),
        ),
      ),
    );
  }

  CustomTab _buildBody() {
    return const CustomTab(
      length: 4,
      tabs: [
        {'label': 'Sales', 'icon': Icons.money},
        {'label': 'Cheques', 'icon': Icons.check_box_outlined},
        {'label': 'Installment', 'icon': Icons.compare},
        {'label': 'Credit', 'icon': Icons.credit_card},
        /*{'label': 'Accrual Basis', 'icon': Icons.ac_unit},
        {'label': 'Cash Basis', 'icon': Icons.sports_baseball},*/
      ],
      children: [
        ListSales(),
        Center(child: Text('Cheque')),
        Center(child: Text('Installment')),
        Center(child: Text('Credit')),
        /*Center(child: Text('Accrual Basis')),
        Center(child: Text('Cash Basis')),*/
      ],
    );
  }
}
