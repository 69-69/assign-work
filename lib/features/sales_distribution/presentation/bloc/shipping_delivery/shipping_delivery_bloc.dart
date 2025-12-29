import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/procurement/data/model/pro_purchase_order_model.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_distribution_bloc.dart';

class ShippingDeliveryBloc extends SalesDistributionBloc<ProPurchaseOrder> {
  ShippingDeliveryBloc({required super.firestore})
    : super(
        collectionPath: salesQuotationDBCollectionPath,
        fromFirestore: (data, id) => ProPurchaseOrder.fromMap(data, docId: id),
        toFirestore: (quote) => quote.toMap(),
        toCache: (quote) => quote.toCache(),
      );
}
