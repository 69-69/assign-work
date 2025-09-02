import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_order_model.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/orders/pos_order_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/pos_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/orders/index.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/orders/widget/group_btn_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PosOrdersScreen extends StatelessWidget {
  const PosOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<POSOrderBloc>(
      create: (context) =>
          POSOrderBloc(firestore: FirebaseFirestore.instance)
            ..add(GetPOSs<POSOrder>()),
      child: CustomScaffold(
        title: posOrdersScreenTitle.toUpperAll,
        body: const ListPOSOrders(),
        floatingActionBtnLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: context.buildPOSGroupBtn(),
      ),
    );
  }
}
