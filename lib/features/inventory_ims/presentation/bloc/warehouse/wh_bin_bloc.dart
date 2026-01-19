import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_bin_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';

class WHBinBloc extends InventoryBloc<WHBin> {
  WHBinBloc({required super.firestore})
    : super(
        collectionPath: whBinStorageDBColPath,
        fromFirestore: (data, id) => WHBin.fromMap(data, id: id),
        toFirestore: (bin) => bin.toMap(),
        toCache: (bin) => bin.toCache(),
      );
}
