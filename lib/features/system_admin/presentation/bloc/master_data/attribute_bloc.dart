import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class AttributeBloc extends SetupBloc<Attribute> {
  AttributeBloc({required super.firestore})
    : super(
        collectionPath: attributeDBColPath,
        fromFirestore: (data, id) => Attribute.fromMap(data, id: id),
        toFirestore: (i) => i.toMap(),
        toCache: (i) => i.toCache(),
      );
}
