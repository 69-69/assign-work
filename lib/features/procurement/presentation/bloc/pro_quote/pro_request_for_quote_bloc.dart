import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';

class ProRequestForQuoteBloc extends ProcurementBloc<RequestForQuote> {
  ProRequestForQuoteBloc({required super.firestore})
    : super(
        collectionPath: requestPriceQuoteDBCollectionPath,
        fromFirestore: (data, id) => RequestForQuote.fromMap(data, id),
        toFirestore: (po) => po.toMap(),
        toCache: (po) => po.toCache(),
      );
}
