import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_inbound_receive_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';

class InboundReceivingBloc extends InventoryBloc<InBoundReceive> {
  InboundReceivingBloc({required super.firestore})
      : super(
    collectionPath: whInboundReceivingDBColPath,
    fromFirestore: (data, id) => InBoundReceive.fromMap(data, id:id),
    toFirestore: (bound) => bound.toMap(),
    toCache: (bound) => bound.toCache(),
  );
}
