import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/inventory_ims/data/models/sale_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';

class SaleBloc extends InventoryBloc<Sale> {
  SaleBloc({required super.firestore})
    : super(
        collectionPath: salesDBColPath,
        fromFirestore: (data, id) => Sale.fromMap(data, id),
        toFirestore: (sale) => sale.toMap(),
        toCache: (sale) => sale.toCache(),
      );
}
