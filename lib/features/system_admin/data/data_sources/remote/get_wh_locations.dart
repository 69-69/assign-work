import 'package:assign_erp/features/system_admin/data/models/master_data/wh_location_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/wh_location_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetWHLocations {
  static List<WHLocation>? _allWHLocationsCache;
  static final locBloc = WHLocationBloc(firestore: FirebaseFirestore.instance);

  static Future<List<WHLocation>> load() async {
    if (_allWHLocationsCache != null) return _allWHLocationsCache!;

    // Load all data initially to pass to the search delegate
    locBloc.add(GetSetups<WHLocation>());

    // Ensure to wait for the data to be loaded
    final allData =
        await locBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<WHLocation>,
            )
            as SetupsLoaded<WHLocation>;

    _allWHLocationsCache = allData.data;
    return allData.data;
  }

  /// Get only types(sub-locations) and related codeRanges
  static Future<List<Map<String, dynamic>>> subLocations(
    String warehouseCode,
  ) async {
    final allWHLocations = await byAnyTerm(warehouseCode);
    final codes = allWHLocations
        .map(
          (WHLocation e) => {
            'type': e.customType,
            'codeRanges': e.getCodeRanges,
          },
        )
        .toList();

    return codes;
  }

  /// Get by either type, zoneType, warehouseCode, codeRanges [byAnyTerm]
  /// @Return: `List<WHLocation>`
  static Future<List<WHLocation>> byAnyTerm(term) async {
    // Load all data initially to pass to the search delegate
    locBloc.add(
      SearchSetup<WHLocation>(
        primaryField: 'description',
        secondaryField: 'type',
        tertiaryField: 'codeRanges',
        optionalField: 'warehouseCode',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final allData =
        await locBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<WHLocation>,
            )
            as SetupsLoaded<WHLocation>;

    return allData.data;
  }
}
