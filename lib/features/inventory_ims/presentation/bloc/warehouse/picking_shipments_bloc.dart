import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_pick_shipping_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';

class PickingShipmentsBloc extends InventoryBloc<PickList> {
  PickingShipmentsBloc({required super.firestore})
      : super(
    collectionPath: whPickShipmentsDBColPath,
    fromFirestore: (data, id) => PickList.fromMap(data, id:id),
    toFirestore: (ship) => ship.toMap(),
    toCache: (ship) => ship.toCache(),
  );
}
