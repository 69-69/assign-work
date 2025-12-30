import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/procurement/data/model/pro_purchase_order_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';

class ProPurchaseOrderBloc extends ProcurementBloc<ProPurchaseOrder> {
  ProPurchaseOrderBloc({required super.firestore})
    : super(
        collectionPath: purchaseOrdersDBColPath,
        fromFirestore: (data, id) => ProPurchaseOrder.fromMap(data, docId: id),
        toFirestore: (po) => po.toMap(),
        toCache: (po) => po.toCache(),
      );
}
