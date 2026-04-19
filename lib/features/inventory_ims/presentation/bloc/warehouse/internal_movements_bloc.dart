import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_movement_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';

class InternalMovementsBloc extends InventoryBloc<WHMovement> {
  InternalMovementsBloc({required super.firestore})
      : super(
    collectionPath: whInternalMovementsDBColPath,
    fromFirestore: (data, id) => WHMovement.fromMap(data, id: id),
    toFirestore: (move) => move.toMap(),
    toCache: (move) => move.toCache(),
  );
}
