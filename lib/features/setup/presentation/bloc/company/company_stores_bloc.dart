import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/setup/data/models/company_stores_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';

class CompanyStoresBloc extends SetupBloc<CompanyStores> {
  CompanyStoresBloc({required super.firestore})
    : super(
        collectionPath: storeLocationsDBCollectionPath,
        fromFirestore: (data, id) => CompanyStores.fromMap(data, id: id),
        toFirestore: (store) => store.toMap(),
        toCache: (store) => store.toCache(),
      );
}
