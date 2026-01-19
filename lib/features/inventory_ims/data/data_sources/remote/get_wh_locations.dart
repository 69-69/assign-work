import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_location_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/wh_location_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetWHLocations {
  static final locBloc = WHLocationBloc(firestore: FirebaseFirestore.instance);

  static Future<List<WHLocation>> load() async {
    // Load all data initially to pass to the search delegate
    locBloc.add(GetInventories<WHLocation>());

    // Ensure to wait for the data to be loaded
    final allData =
        await locBloc.stream.firstWhere(
              (state) => state is InventoriesLoaded<WHLocation>,
            )
            as InventoriesLoaded<WHLocation>;

    return allData.data;
  }

  /// Get by either description, warehouseId, code [byAnyTerm]
  /// @Return: `List<WHLocation>`
  static Future<List<WHLocation>> byAnyTerm(term) async {
    // Load all data initially to pass to the search delegate
    locBloc.add(
      SearchInventory<WHLocation>(
        primaryField: 'description',
        optionalField: 'warehouseId',
        secondaryField: 'code',
        tertiaryField: 'type',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final allData =
        await locBloc.stream.firstWhere(
              (state) => state is InventoriesLoaded<WHLocation>,
            )
            as InventoriesLoaded<WHLocation>;

    return allData.data;
  }
}
