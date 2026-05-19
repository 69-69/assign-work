import 'package:assign_erp/features/system_admin/data/models/master_data/price_list_master_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/price_list_master_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetPriceList {
  static final _priceListBloc = PriceListMasterBloc(
    firestore: FirebaseFirestore.instance,
  );

  static Future<List<PriceListMaster>> load() async {
    // Load all data initially to pass to the search delegate
    _priceListBloc.add(GetSetups<PriceListMaster>());

    // Ensure to wait for the data to be loaded
    final allData =
        await _priceListBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<PriceListMaster>,
            )
            as SetupsLoaded<PriceListMaster>;

    return allData.data;
  }

  /// Get by either storeNumber, name, type [byAnyTerm]
  /// @Return: `List<PriceListMaster>`
  static Future<List<PriceListMaster>> byAnyTerm(term) async {
    // Load all data initially to pass to the search delegate
    _priceListBloc.add(
      SearchSetup<PriceListMaster>(
        primaryField: 'name',
        secondaryField: 'transactionType',
        optionalField: 'storeNumber',
        tertiaryField: 'validUntil',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final allData =
        await _priceListBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<PriceListMaster>,
            )
            as SetupsLoaded<PriceListMaster>;

    return allData.data;
  }
}
