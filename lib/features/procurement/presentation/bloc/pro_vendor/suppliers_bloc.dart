import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/constants/collection_type.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';

class SupplierBloc extends ProcurementBloc<Supplier> {
  SupplierBloc({required super.firestore})
    : super(
        collectionType: CollectionType.workspace,
        collectionPath: supplierDBCollectionPath,
        fromFirestore: (data, id) => Supplier.fromMap(data, id: id),
        toFirestore: (info) => info.toMap(),
        toCache: (info) => info.toCache(),
      );
}
