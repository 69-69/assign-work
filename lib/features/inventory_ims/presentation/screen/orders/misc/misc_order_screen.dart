import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/misc_order_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/orders/misc_order_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/misc/list/list_miscellaneous_orders.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/po/create/create_purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MiscOrderScreen extends StatelessWidget {
  const MiscOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MiscOrderBloc, InventoryState<MiscOrder>>(
      builder: (context, state) => CustomScaffold(
        title: miscOrderScreenTitle.toUpperAll,
        body: _buildBody(),
        floatingActionButton: context.buildFloatingBtn(
          'Create Misc Order',
          onPressed: () => context.openAddPurchaseOrders(),
        ),
      ),
    );
  }

  CustomTab _buildBody() {
    return CustomTab(
      length: 3,
      openThisTab: 0,
      tabs: [
        CustomTabModel(
          label: 'Misc Orders',
          icon: Icons.miscellaneous_services,
        ),
        CustomTabModel(label: 'Approved Misc', icon: Icons.approval),
        CustomTabModel(label: 'Fulfilled Misc', icon: Icons.done_all_sharp),
      ],
      children: [
        ListMiscellaneousOrders(),
        Center(child: Text('Approved MOs')),
        Center(child: Text('Fulfilled MOs')),
      ],
    );
  }
}
