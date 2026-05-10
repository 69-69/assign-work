import 'package:assign_erp/features/system_admin/data/models/company_store_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/company_stores_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetStores {
  static final _storeBloc = CompanyStoresBloc(
    firestore: FirebaseFirestore.instance,
  );

  static Future<List<CompanyStore>> load() async {
    // Load all data initially to pass to the search delegate
    _storeBloc.add(GetSetups<CompanyStore>());

    // Ensure to wait for the data to be loaded
    final allData =
        await _storeBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<CompanyStore>,
            )
            as SetupsLoaded<CompanyStore>;

    return allData.data;
  }

  /// Get by either storeNumber, name, location [byAnyTerm]
  /// @Return: `List<CompanyStores>`
  static Future<List<CompanyStore>> byAnyTerm(term) async {
    // Load all data initially to pass to the search delegate
    _storeBloc.add(
      SearchSetup<CompanyStore>(
        primaryField: 'name',
        optionalField: 'storeNumber',
        secondaryField: 'location',
        tertiaryField: 'phone',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final allData =
        await _storeBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<CompanyStore>,
            )
            as SetupsLoaded<CompanyStore>;

    return allData.data;
  }
}
