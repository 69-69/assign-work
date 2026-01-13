import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_sale_model.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/pos_bloc.dart';

class POSSaleBloc extends POSBloc<POSSale> {
  // final FirebaseFirestore _firestore;

  POSSaleBloc({required super.firestore})
    : super(
        collectionPath: posSalesDBColPath,
        fromFirestore: (data, id) => POSSale.fromMap(data, id),
        toFirestore: (so) => so.toMap(),
        toCache: (so) => so.toCache(),
      );
}
