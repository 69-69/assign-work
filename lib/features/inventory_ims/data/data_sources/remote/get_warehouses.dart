import 'package:assign_erp/features/inventory_ims/data/models/warehouse/warehouse_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/warehouse_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetWarehouses {
  static final wareBloc = WarehouseBloc(firestore: FirebaseFirestore.instance);

  static Future<List<Warehouse>> load() async {
    // Load all data initially to pass to the search delegate
    wareBloc.add(GetInventories<Warehouse>());

    // Ensure to wait for the data to be loaded
    final allData =
        await wareBloc.stream.firstWhere(
              (state) => state is InventoriesLoaded<Warehouse>,
            )
            as InventoriesLoaded<Warehouse>;

    return allData.data;
  }

  /// Get by either description, lead, code [byAnyTerm]
  /// @Return: `List<Warehouse>`
  static Future<List<Warehouse>> byAnyTerm(term) async {
    // Load all data initially to pass to the search delegate
    wareBloc.add(
      SearchInventory<Warehouse>(
        primaryField: 'description',
        optionalField: 'maxItems',
        secondaryField: 'code',
        tertiaryField: 'type',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final allData =
        await wareBloc.stream.firstWhere(
              (state) => state is InventoriesLoaded<Warehouse>,
            )
            as InventoriesLoaded<Warehouse>;

    return allData.data;
  }
}
