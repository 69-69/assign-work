import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/procurement/data/model/purchase_requisition_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';

class ProPurchaseRequisiteBloc extends ProcurementBloc<PurchaseRequisition> {
  ProPurchaseRequisiteBloc({required super.firestore})
    : super(
        collectionPath: purchaseRequisitionDBColPath,
        fromFirestore: (data, id) => PurchaseRequisition.fromMap(data, id: id),
        toFirestore: (pr) => pr.toMap(),
        toCache: (pr) => pr.toCache(),
      );
}
