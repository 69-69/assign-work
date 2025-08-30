import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/setup/data/models/tax_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';

class TaxBloc extends SetupBloc<Tax> {
  TaxBloc({required super.firestore})
    : super(
        collectionPath: taxesDBCollectionPath,
        fromFirestore: (data, id) => Tax.fromMap(data, id: id),
        toFirestore: (tax) => tax.toMap(),
        toCache: (tax) => tax.toCache(),
      );
}
