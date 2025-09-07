import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class TaxBloc extends SetupBloc<Tax> {
  TaxBloc({required super.firestore})
    : super(
        collectionPath: taxesDBCollectionPath,
        fromFirestore: (data, id) => Tax.fromMap(data, id: id),
        toFirestore: (tax) => tax.toMap(),
        toCache: (tax) => tax.toCache(),
      );
}
