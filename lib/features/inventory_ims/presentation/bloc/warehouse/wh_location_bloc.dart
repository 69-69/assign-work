import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_location_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';

class WHLocationBloc extends InventoryBloc<WHLocation> {
  WHLocationBloc({required super.firestore})
    : super(
        collectionPath: whLocationStorageDBColPath,
        fromFirestore: (data, id) => WHLocation.fromMap(data, id: id),
        toFirestore: (loc) => loc.toMap(),
        toCache: (loc) => loc.toCache(),
      );
}
