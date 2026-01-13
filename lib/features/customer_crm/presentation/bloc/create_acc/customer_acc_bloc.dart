import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/customer_crm/data/models/customer_model.dart';
import 'package:assign_erp/features/customer_crm/presentation/bloc/customer_bloc.dart';

class CustomerAccountBloc extends CustomerBloc<Customer> {
  CustomerAccountBloc({required super.firestore})
    : super(
        collectionPath: customersDBColPath,
        fromFirestore: (data, id) => Customer.fromMap(data, id),
        toFirestore: (customer) => customer.toMap(),
        toCache: (customer) => customer.toCache(),
      );
}
