import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/item_master_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class ItemMasterBloc extends SetupBloc<ItemMaster> {
  ItemMasterBloc({required super.firestore})
    : super(
        collectionPath: itemMasterDBColPath,
        fromFirestore: (data, id) => ItemMaster.fromMap(data, id: id),
        toFirestore: (master) => master.toMap(),
        toCache: (master) => master.toCache(),
      );
}
