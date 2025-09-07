import 'package:assign_erp/features/system_admin/data/models/company_stores_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/company_stores_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetStores {
  static final storeBloc = CompanyStoresBloc(
    firestore: FirebaseFirestore.instance,
  );

  static Future<List<CompanyStores>> load() async {
    // Load all data initially to pass to the search delegate
    storeBloc.add(GetSetups<CompanyStores>());

    // Ensure to wait for the data to be loaded
    final allData =
        await storeBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<CompanyStores>,
            )
            as SetupsLoaded<CompanyStores>;

    return allData.data;
  }

  /// Get by either storeNumber, name, location [byAnyTerm]
  /// @Return: `List<CompanyStores>`
  static Future<List<CompanyStores>> byAnyTerm(term) async {
    // Load all data initially to pass to the search delegate
    storeBloc.add(
      SearchSetup<CompanyStores>(
        field: 'name',
        optField: 'storeNumber',
        auxField: 'location',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final allData =
        await storeBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<CompanyStores>,
            )
            as SetupsLoaded<CompanyStores>;

    return allData.data;
  }
}
