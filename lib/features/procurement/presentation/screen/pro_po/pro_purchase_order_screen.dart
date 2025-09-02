import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/purchase_order_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_po/pro_purchase_order_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
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
            ..add(GetProcurements<PurchaseOrder>()),
      child: CustomScaffold(
        title: purchaseOrderScreenTitle.toUpperAll,
        body: Center(child: Text('Procurement Purchase Order')),
      ),
    );
  }
}
