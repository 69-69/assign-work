import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/order_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/orders/order_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/so/create/create_order.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/so/list/list_orders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderBloc>(
      create: (context) =>
          OrderBloc(firestore: FirebaseFirestore.instance)
            ..add(GetInventories<Orders>()),
      child: CustomScaffold(
        title: salesOrderScreenTitle.toUpperAll,
        body: _buildBody(),
        floatingActionButton: context.buildFloatingBtn(
          'Place an Order',
          onPressed: () => context.openAddOrder(),
        ),
      ),
    );
  }

  CustomTab _buildBody() {
    return CustomTab(
      length: 4,
      tabs: [
        CustomTabModel(label: 'Orders', icon: Icons.shopping_cart),
        CustomTabModel(label: 'Pending', icon: Icons.pending),
        CustomTabModel(
          label: 'Shipped or Dispatched',
          icon: Icons.local_shipping,
        ),
        CustomTabModel(label: 'Completed', icon: Icons.done_all),
      ],
      children: [
        ListOrders(),
        Center(child: Text('Pending')),
        Center(child: Text('Shipped or Dispatched')),
        Center(child: Text('Completed')),
      ],
    );
  }
}
