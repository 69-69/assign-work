import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/purchase_order_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/orders/purchase_order_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/po/add/add_purchase_order.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/po/list/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PurchaseOrderScreen extends StatelessWidget {
  const PurchaseOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PurchaseOrderBloc>(
      create: (context) =>
          PurchaseOrderBloc(firestore: FirebaseFirestore.instance)
            ..add(GetInventories<PurchaseOrder>()),
      child: CustomScaffold(
        title: purchaseOrderScreenTitle.toUpperAll,
        body: _buildBody(),
        floatingActionButton: context.buildFloatingBtn(
          'Create PO',
          onPressed: () => context.openAddPurchaseOrders(),
        ),
      ),
    );
  }

  CustomTab _buildBody() {
    return const CustomTab(
      length: 3,
      openThisTab: 0,
      tabs: [
        {'label': 'POs', 'icon': Icons.shopping_cart},
        {'label': 'Approved POs', 'icon': Icons.approval},
        {'label': 'Fulfilled POs', 'icon': Icons.done_all_sharp},
      ],
      children: [
        ListPOByDate(),
        ListApprovedPO(),
        Center(child: Text('Fulfilled POs')),
      ],
    );
  }
}
