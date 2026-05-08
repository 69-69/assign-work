import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/price_list_master_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class PriceListEntryBloc extends SetupBloc<PriceEntry> {
  PriceListEntryBloc({required super.firestore})
    : super(
        collectionPath: priceListEntryDBColPath,
        fromFirestore: (data, id) => PriceEntry.fromMap(data, id: id),
        toFirestore: (entry) => entry.toMap(),
        toCache: (entry) => entry.toCache(),
      );
}
