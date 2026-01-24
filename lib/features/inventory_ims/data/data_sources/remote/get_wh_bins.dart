import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_bin_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/warehouse/wh_bin_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetWHBins {
  static List<WHBin>? _allWHBinsCache;
  static final binBloc = WHBinBloc(firestore: FirebaseFirestore.instance);

  static Future<List<WHBin>> load() async {
    if (_allWHBinsCache != null) return _allWHBinsCache!;
    // Load all data initially to pass to the search delegate
    binBloc.add(GetInventories<WHBin>());

    // Ensure to wait for the data to be loaded
    final allData =
        await binBloc.stream.firstWhere(
              (state) => state is InventoriesLoaded<WHBin>,
            )
            as InventoriesLoaded<WHBin>;

    _allWHBinsCache = allData.data;
    return allData.data;
  }

  /// Get by either description, maxItems, code [byAnyTerm]
  /// @Return: `List<WHBin>`
  static Future<List<WHBin>> byAnyTerm(term) async {
    // Load all data initially to pass to the search delegate
    binBloc.add(
      SearchInventory<WHBin>(
        primaryField: 'description',
        optionalField: 'locationId',
        secondaryField: 'code',
        tertiaryField: 'type',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final allData =
        await binBloc.stream.firstWhere(
              (state) => state is InventoriesLoaded<WHBin>,
            )
            as InventoriesLoaded<WHBin>;

    return allData.data;
  }
}
