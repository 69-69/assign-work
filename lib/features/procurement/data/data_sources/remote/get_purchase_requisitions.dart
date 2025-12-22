import 'package:assign_erp/features/index.dart';
import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';

class GetPurchaseRequisitions {
  static Future<ProcurementsLoaded<PurchaseRequisition>> _dataLoadedState(
    ProPurchaseRequisiteBloc bloc,
  ) async {
    return await bloc.stream.firstWhere(
          (state) => state is ProcurementsLoaded<PurchaseRequisition>,
        )
        as ProcurementsLoaded<PurchaseRequisition>;
  }

  /// Get by either prNumber or priority or departmentCode [byAnyTerm]
  /// @Return: `List<PurchaseRequisition>`
  static Future<List<PurchaseRequisition>> byAnyTerm(String term) async {
    final prBloc = ProPurchaseRequisiteBloc(
      firestore: FirebaseFirestore.instance,
    );

    // Load all data initially to pass to the search delegate
    prBloc.add(
      SearchProcurement<PurchaseRequisition>(
        field: 'prNumber',
        optField: 'priority',
        auxField: 'departmentCode',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(prBloc);

    return state.data;
  }
}
