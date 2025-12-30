import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/sales_distribution/data/model/sales_quotation_model.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_distribution_bloc.dart';

class ShippingDeliveryBloc extends SalesDistributionBloc<SalesQuotation> {
  ShippingDeliveryBloc({required super.firestore})
    : super(
        collectionPath: salesShippingDelDBColPath,
        fromFirestore: (data, id) => SalesQuotation.fromMap(data, docId: id),
        toFirestore: (quote) => quote.toMap(),
        toCache: (quote) => quote.toCache(),
      );
}
