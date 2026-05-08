import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/price_list_master_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class PriceMasterBloc extends SetupBloc<PriceMaster> {
  PriceMasterBloc({required super.firestore})
    : super(
        collectionPath: priceListMasterDBColPath,
        fromFirestore: (data, id) => PriceMaster.fromMap(data, id: id),
        toFirestore: (master) => master.toMap(),
        toCache: (master) => master.toCache(),
      );
}
