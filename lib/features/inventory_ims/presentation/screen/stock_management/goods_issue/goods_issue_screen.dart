import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/index.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_master_model.dart';
import 'package:flutter/material.dart';

class GoodsIssueScreen extends StatelessWidget {
  const GoodsIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ItemMasterBloc>(
      create: (context) =>
          ItemMasterBloc(firestore: FirebaseFirestore.instance)
            ..add(GetInventories<ItemMaster>()),
      child: CustomScaffold(
        title: goodsIssueScreenTitle.toUpperAll,
        body: Center(
          child: Text(
            'Goods Issue Screen',
            style: context.textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}
