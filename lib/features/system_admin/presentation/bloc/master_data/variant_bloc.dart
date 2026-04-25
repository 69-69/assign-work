import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/variant_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class VariantBloc extends SetupBloc<Variant> {
  VariantBloc({required super.firestore})
    : super(
        collectionPath: variantDBColPath,
        fromFirestore: (data, id) => Variant.fromMap(data, id: id),
        toFirestore: (i) => i.toMap(),
        toCache: (i) => i.toCache(),
      );
}
