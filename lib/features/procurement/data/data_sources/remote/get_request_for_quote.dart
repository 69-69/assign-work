import 'package:assign_erp/features/index.dart';
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';

class GetRequestForQuote {
  static Future<ProcurementsLoaded<RequestForQuote>> _dataLoadedState(
    ProRequestForQuoteBloc bloc,
  ) async {
    return await bloc.stream.firstWhere(
          (state) => state is ProcurementsLoaded<RequestForQuote>,
        )
        as ProcurementsLoaded<RequestForQuote>;
  }

  /// Get by either rfqNumber or supplierId or departmentCode [byAnyTerm]
  /// @Return: `List<RequestForQuote>`
  static Future<List<RequestForQuote>> byAnyTerm(String term) async {
    final rfqBloc = ProRequestForQuoteBloc(
      firestore: FirebaseFirestore.instance,
    );

    // Load all data initially to pass to the search delegate
    rfqBloc.add(
      SearchProcurement<RequestForQuote>(
        field: 'rfqNumber',
        optField: 'supplierId',
        auxField: 'departmentCode',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(rfqBloc);

    return state.data;
  }
}
