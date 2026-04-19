import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/wh_bin_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class WHBinBloc extends SetupBloc<WHBin> {
  WHBinBloc({required super.firestore})
    : super(
        collectionPath: whBinStorageDBColPath,
        fromFirestore: (data, id) => WHBin.fromMap(data, id: id),
        toFirestore: (bin) => bin.toMap(),
        toCache: (bin) => bin.toCache(),
      );
}
