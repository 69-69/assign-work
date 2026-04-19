import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/warehouse_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class WarehouseBloc extends SetupBloc<Warehouse> {
  WarehouseBloc({required super.firestore})
    : super(
        collectionPath: warehouseDBColPath,
        fromFirestore: (data, id) => Warehouse.fromMap(data, id: id),
        toFirestore: (ware) => ware.toMap(),
        toCache: (ware) => ware.toCache(),
      );
}
