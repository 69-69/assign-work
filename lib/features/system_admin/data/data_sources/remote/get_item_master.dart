import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/item_master_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/item_master_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetItemMaster {
  static List<ItemMaster>? _itemsCache;
  static final _itemBloc = ItemMasterBloc(
    firestore: FirebaseFirestore.instance,
  );

  static Future<List<ItemMaster>> load() async {
    if (_itemsCache != null) return _itemsCache!;

    // Load all data initially to pass to the search delegate
    _itemBloc.add(GetSetups<ItemMaster>());

    // Ensure to wait for the data to be loaded
    final allData =
        await _itemBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<ItemMaster>,
            )
            as SetupsLoaded<ItemMaster>;

    _itemsCache = allData.data;
    return allData.data;
  }

  /// Get by either name, lead, code [byAnyTerm]
  /// @Return: `List<ItemMaster>`
  static Future<List<ItemMaster>> byAnyTerm(term) async {
    // Load all data initially to pass to the search delegate
    _itemBloc.add(
      SearchSetup<ItemMaster>(
        primaryField: 'name',
        secondaryField: 'sku',
        tertiaryField: 'storeNumber',
        optionalField: 'id',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final allData =
        await _itemBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<ItemMaster>,
            )
            as SetupsLoaded<ItemMaster>;

    return allData.data;
  }

  /// Get by Item Master by id [byItemId]
  static Future<ItemMaster> byItemId(String empId) async {
    _itemBloc.add(GetSetupById<ItemMaster>(documentId: empId));

    try {
      final state = await _itemBloc.stream.firstWhere(
        (state) => state is SetupsLoaded<ItemMaster>,
        orElse: () => SetupsLoaded<ItemMaster>([]),
      );

      if (state is SetupsLoaded<ItemMaster>) {
        final data = state.data;
        return data.isNotEmpty ? data.first : ItemMaster.empty;
      }
    } catch (e) {
      prettyPrint('Error fetching item master', '$e');
    }

    return ItemMaster.empty;
  }
}
