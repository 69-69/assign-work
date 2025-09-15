import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';

class RequestForQuoteBloc extends InventoryBloc<RequestForQuote> {
  RequestForQuoteBloc({required super.firestore})
    : super(
        collectionPath: requestPriceQuoteDBCollectionPath,
        fromFirestore: (data, id) => RequestForQuote.fromMap(data, docId: id),
        toFirestore: (req) => req.toMap(),
        toCache: (req) => req.toCache(),
      );
}
