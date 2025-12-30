import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/misc_order_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';

class MiscOrderBloc extends InventoryBloc<MiscOrder> {
  MiscOrderBloc({required super.firestore})
    : super(
        collectionPath: purchaseOrdersDBColPath,
        fromFirestore: (data, id) => MiscOrder.fromMap(data, id),
        toFirestore: (misc) => misc.toMap(),
        toCache: (misc) => misc.toCache(),
      );
}
