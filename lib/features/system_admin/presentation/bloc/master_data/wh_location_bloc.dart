import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/wh_location_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class WHLocationBloc extends SetupBloc<WHLocation> {
  WHLocationBloc({required super.firestore})
    : super(
        collectionPath: whStorageLocationDBColPath,
        fromFirestore: (data, id) => WHLocation.fromMap(data, id: id),
        toFirestore: (loc) => loc.toMap(),
        toCache: (loc) => loc.toCache(),
      );
}
