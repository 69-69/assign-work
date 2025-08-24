import 'package:assign_erp/features/inventory_ims/data/models/item_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/item/item_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetItems {
  // static final itemBloc = ItemBloc(firestore: FirebaseFirestore.instance);

  static Future<InventoriesLoaded<Item>> _dataLoadedState(ItemBloc bloc) async {
    return await bloc.stream.firstWhere(
          (state) => state is InventoriesLoaded<Item>,
        )
        as InventoriesLoaded<Item>;
  }

  static Future<List<Item>> load() async {
    final itemBloc = ItemBloc(firestore: FirebaseFirestore.instance);

    // Load all data initially to pass to the search delegate
    itemBloc.add(GetInventories<Item>());

    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(itemBloc);

    return state.data;
  }

  static Future<Item?> byItemId(itemId, {Object? field}) async {
    final itemBloc = ItemBloc(firestore: FirebaseFirestore.instance);

    // Load all data initially to pass to the search delegate
    itemBloc.add(GetInventoryById<Item>(field: field, documentId: itemId));

    // Ensure to wait for the data to be loaded
    final state =
        await itemBloc.stream.firstWhere(
              (state) => state is InventoryLoaded<Item>,
            )
            as InventoryLoaded<Item>;

    return state.data.isEmpty ? null : state.data;
  }

  /// Get by either documentId, batchId, sku [byAnyTerm]
  /// @Return: `List<Item>`
  static Future<List<Item>> byAnyTerm(term) async {
    final itemBloc = ItemBloc(firestore: FirebaseFirestore.instance);

    // Load all data initially to pass to the search delegate
    itemBloc.add(
      SearchInventory<Item>(
        field: 'sku',
        optField: 'batchId',
        auxField: 'name',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(itemBloc);

    return state.data.isEmpty ? [] : state.data;
  }

  /*void _updateInventory(String barcode) {
    // Fetch product by barcode and update its quantity
    // final productBloc = BlocProvider.of<ProductBloc>(context);
    final productBloc = ProductBloc(firestore: FirebaseFirestore.instance);

    // Load all data initially to pass to the search delegate
    final products = (productBloc.state as InventoryLoaded<Product>).data;

    final product = products.firstWhere(
      (product) => product.barcode == barcode,
      orElse: () => Product.notFound,
    );

    if (product.id.isNotEmpty) {
      // Update existing product
      productBloc.add(
        UpdateInventory<Product>(
          documentId: product.id,
          data: product.copyWith(quantity: product.quantity + 1),
        ),
      );
    } else {
      // Add new product (you may want to show a form to enter product details)
      productBloc
          .add(AddInventory<Product>(data: product.copyWith(quantity: 1)));
    }
  }*/

  static Future<Item?> findByBarcode(String barcode) async {
    // Fetch product by barcode and update its quantity
    // final itemBloc = BlocProvider.of<ProductBloc>(context);
    final itemBloc = ItemBloc(firestore: FirebaseFirestore.instance);

    // Load all data initially to pass to the search delegate
    itemBloc.add(GetInventoryById<Item>(field: 'barcode', documentId: barcode));

    // Ensure to wait for the data to be loaded
    final state =
        await itemBloc.stream.firstWhere(
              (state) => state is InventoryLoaded<Item>,
            )
            as InventoryLoaded<Item>;

    final item = state.data;

    return item.isNotEmpty ? item : null;
  }
}
