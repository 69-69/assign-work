import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_requisition/pro_purchase_requisite_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_requisition/list/list_purchase_requisitions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProPurchaseRequisitionScreen extends StatelessWidget {
  const ProPurchaseRequisitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProPurchaseRequisiteBloc>(
      create: (context) =>
          ProPurchaseRequisiteBloc(firestore: FirebaseFirestore.instance)
            ..add(GetProcurements<PurchaseRequisition>()),
      child: CustomScaffold(
        title: purchaseRequisiteScreenTitle.toUpperAll,
        body: _buildBody(),
      ),
    );
  }

  CustomTab _buildBody() {
    return CustomTab(
      length: 2,
      openThisTab: 0,
      tabs: [
        CustomTabModel(
          label: 'Purchase Requisitions',
          icon: Icons.edit_document,
        ),
        CustomTabModel(label: 'Approved PRs', icon: Icons.approval),
      ],
      children: [
        ListPurchaseRequisitions(),
        ListPurchaseRequisitions(isApproved: true),
      ],
    );
  }
}
