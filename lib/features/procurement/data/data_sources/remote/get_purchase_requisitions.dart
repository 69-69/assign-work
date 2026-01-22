import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_requisition/pro_purchase_requisite_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetPurchaseRequisitions {
  static Future<ProcurementsLoaded<PurchaseRequisition>> _dataLoadedState(
    ProPurchaseRequisiteBloc bloc,
  ) async {
    return await bloc.stream.firstWhere(
          (state) => state is ProcurementsLoaded<PurchaseRequisition>,
        )
        as ProcurementsLoaded<PurchaseRequisition>;
  }

  static Future<List<PurchaseRequisition>> load() async {
    final prBloc = ProPurchaseRequisiteBloc(
      firestore: FirebaseFirestore.instance,
    );
    // Load all data initially to pass to the search delegate
    prBloc.add(GetProcurements<PurchaseRequisition>());

    // Ensure to wait for the data to be loaded
    final allData =
        await prBloc.stream.firstWhere(
              (state) => state is ProcurementsLoaded<PurchaseRequisition>,
            )
            as ProcurementsLoaded<PurchaseRequisition>;

    return allData.data;
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
        primaryField: 'prNumber',
        optionalField: 'priority',
        secondaryField: 'status',
        tertiaryField: 'departmentCode',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(prBloc);

    return state.data;
  }
}
