import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/index.dart';
import 'package:assign_erp/features/system_admin/data/models/item_master_model.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/item_master/list/list_item_master.dart';
import 'package:flutter/material.dart';

class ItemMasterScreen extends StatelessWidget {
  const ItemMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ItemMasterBloc>(
      create: (context) =>
          ItemMasterBloc(firestore: FirebaseFirestore.instance)
            ..add(GetSetups<ItemMaster>()),
      child: CustomScaffold(
        title: itemMasterScreenTitle.toUpperAll,
        body: ListItemMaster(),
      ),
    );
  }
}
