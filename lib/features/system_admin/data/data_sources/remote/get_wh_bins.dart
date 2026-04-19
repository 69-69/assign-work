import 'package:assign_erp/features/system_admin/data/models/master_data/wh_bin_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/wh_bin_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetWHBins {
  static List<WHBin>? _allWHBinsCache;
  static final binBloc = WHBinBloc(firestore: FirebaseFirestore.instance);

  static Future<List<WHBin>> load() async {
    if (_allWHBinsCache != null) return _allWHBinsCache!;
    // Load all data initially to pass to the search delegate
    binBloc.add(GetSetups<WHBin>());

    // Ensure to wait for the data to be loaded
    final allData =
        await binBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<WHBin>,
            )
            as SetupsLoaded<WHBin>;

    _allWHBinsCache = allData.data;
    return allData.data;
  }

  /// Get by either description, maxItems, code [byAnyTerm]
  /// @Return: `List<WHBin>`
  static Future<List<WHBin>> byAnyTerm(term) async {
    // Load all data initially to pass to the search delegate
    binBloc.add(
      SearchSetup<WHBin>(
        primaryField: 'description',
        optionalField: 'warehouseCode',
        secondaryField: 'fullBinLocations',
        tertiaryField: 'binLocationCode',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final allData =
        await binBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<WHBin>,
            )
            as SetupsLoaded<WHBin>;

    return allData.data;
  }
}
