import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/company_stores_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class CompanyStoresBloc extends SetupBloc<CompanyStores> {
  CompanyStoresBloc({required super.firestore})
    : super(
        collectionPath: storeLocationsDBColPath,
        fromFirestore: (data, id) => CompanyStores.fromMap(data, id: id),
        toFirestore: (store) => store.toMap(),
        toCache: (store) => store.toCache(),
      );
}
