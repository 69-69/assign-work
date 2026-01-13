import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_master_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';

class ItemMasterBloc extends InventoryBloc<ItemMaster> {
  ItemMasterBloc({required super.firestore})
    : super(
        collectionPath: itemMasterDBColPath,
        fromFirestore: (data, id) => ItemMaster.fromMap(data, id: id),
        toFirestore: (master) => master.toMap(),
        toCache: (master) => master.toCache(),
      );
}
