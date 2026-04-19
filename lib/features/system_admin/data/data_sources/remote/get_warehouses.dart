import 'package:assign_erp/features/system_admin/data/models/master_data/warehouse_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/warehouse_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetWarehouses {
  static final wareBloc = WarehouseBloc(firestore: FirebaseFirestore.instance);
  static List<Warehouse>? _allWarehousesCache;

  static Future<List<Warehouse>> load() async {
    if (_allWarehousesCache != null) return _allWarehousesCache!;
    // Load all data initially to pass to the search delegate
    wareBloc.add(GetSetups<Warehouse>());

    // Ensure to wait for the data to be loaded
    final allData =
        await wareBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<Warehouse>,
            )
            as SetupsLoaded<Warehouse>;

    _allWarehousesCache = allData.data;
    return allData.data;
  }

  /// Get by either description, lead, code [byAnyTerm]
  /// @Return: `List<Warehouse>`
  static Future<List<Warehouse>> byAnyTerm(term) async {
    // Load all data initially to pass to the search delegate
    wareBloc.add(
      SearchSetup<Warehouse>(
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
              (state) => state is SetupsLoaded<Warehouse>,
            )
            as SetupsLoaded<Warehouse>;

    return allData.data;
  }
}
