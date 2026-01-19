import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/warehouse_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';

class WarehouseBloc extends InventoryBloc<Warehouse> {
  WarehouseBloc({required super.firestore})
    : super(
        collectionPath: warehouseDBColPath,
        fromFirestore: (data, id) => Warehouse.fromMap(data, id: id),
        toFirestore: (ware) => ware.toMap(),
        toCache: (ware) => ware.toCache(),
      );
}
