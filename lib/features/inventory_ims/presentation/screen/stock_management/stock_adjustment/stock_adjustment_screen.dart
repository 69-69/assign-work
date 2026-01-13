import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/index.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_master_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/stock_management/item_master/list/list_item_master.dart';
import 'package:flutter/material.dart';

class GoodsReceiptScreen extends StatelessWidget {
  const GoodsReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ItemMasterBloc>(
      create: (context) =>
          ItemMasterBloc(firestore: FirebaseFirestore.instance)
            ..add(GetInventories<ItemMaster>()),
      child: CustomScaffold(
        title: goodsReceiptScreenTitle.toUpperAll,
        body: ListItemMaster(),
      ),
    );
  }
}
