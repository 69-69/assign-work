import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';

class ItemBloc extends InventoryBloc<Item> {
  ItemBloc({required super.firestore})
    : super(
        collectionPath: itemsDBCollectionPath,
        fromFirestore: (data, id) => Item.fromMap(data, id),
        toFirestore: (product) => product.toMap(),
        toCache: (product) => product.toCache(),
      );
  /*final DataRepository _dataRepository;

  ProductBloc({required DataRepository dataRepository})
      : _dataRepository = dataRepository,
        super(
          dataRepository: dataRepository,
          collectionPath: productsDBCollectionPath,
          fromFirestore: (data, id) => Product.fromMap(data, id),
          toFirestore: (product) => product.toMap(),
          toCache: (product) => product.toCache(),
        );*/
}
