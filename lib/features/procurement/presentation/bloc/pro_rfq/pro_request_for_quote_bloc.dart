import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';

class ProRequestForQuoteBloc extends ProcurementBloc<RequestForQuote> {
  ProRequestForQuoteBloc({required super.firestore})
    : super(
        collectionPath: requestPriceQuoteDBCollectionPath,
        fromFirestore: (data, id) => RequestForQuote.fromMap(data, docId: id),
        toFirestore: (rfq) => rfq.toMap(),
        toCache: (rfq) => rfq.toCache(),
      );
}
