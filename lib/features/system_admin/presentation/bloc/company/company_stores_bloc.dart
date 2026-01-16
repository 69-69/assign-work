import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/company_store_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class CompanyStoresBloc extends SetupBloc<CompanyStore> {
  CompanyStoresBloc({required super.firestore})
    : super(
        collectionPath: storeLocationsDBColPath,
        fromFirestore: (data, id) => CompanyStore.fromMap(data, id: id),
        toFirestore: (store) => store.toMap(),
        toCache: (store) => store.toCache(),
      );
}
