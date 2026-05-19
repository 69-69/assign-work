import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/discount_group_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class DiscountGroupMasterBloc extends SetupBloc<DiscountGroup> {
  DiscountGroupMasterBloc({required super.firestore})
    : super(
        collectionPath: discountGroupMasterDBColPath,
        fromFirestore: (data, id) => DiscountGroup.fromMap(data, id: id),
        toFirestore: (master) => master.toMap(),
        toCache: (master) => master.toCache(),
      );
}
