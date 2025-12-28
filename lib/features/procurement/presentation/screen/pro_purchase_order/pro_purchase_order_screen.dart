import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/features/procurement/data/model/pro_purchase_order_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_po/pro_purchase_order_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_order/list/list_purchase_orders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProPurchaseOrderScreen extends StatelessWidget {
  const ProPurchaseOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProPurchaseOrderBloc>(
      create: (context) =>
          ProPurchaseOrderBloc(firestore: FirebaseFirestore.instance)
            ..add(GetProcurements<ProPurchaseOrder>()),
      child: CustomScaffold(
        title: purchaseOrderScreenTitle.toUpperAll,
        body: _buildBody(),
      ),
    );
  }

  CustomTab _buildBody() {
    return CustomTab(
      length: 2,
      openThisTab: 0,
      tabs: [
        CustomTabModel(label: 'Purchase Orders', icon: Icons.shopping_cart),
        CustomTabModel(label: 'Approved POs', icon: Icons.approval),
      ],
      children: [ListPurchaseOrders(), ListPurchaseOrders(isApproved: true)],
    );
  }
}
