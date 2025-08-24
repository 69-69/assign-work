import 'package:assign_erp/features/customer_crm/data/models/customer_model.dart';
import 'package:assign_erp/features/customer_crm/presentation/bloc/create_acc/customer_acc_bloc.dart';
import 'package:assign_erp/features/customer_crm/presentation/bloc/customer_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetAllCustomers {
  // Dispatch an event to load the data
  // static final customerBloc = CustomerAccountBloc(firestore: FirebaseFirestore.instance);

  static Future<CustomersLoaded<Customer>> _dataLoadedState(
    CustomerBloc bloc,
  ) async {
    return await bloc.stream.firstWhere(
          (state) => state is CustomersLoaded<Customer>,
        )
        as CustomersLoaded<Customer>;
  }

  static Future<List<Customer>> load() async {
    final customerBloc = CustomerAccountBloc(
      firestore: FirebaseFirestore.instance,
    );

    // Load all data initially to pass to the search delegate
    customerBloc.add(GetCustomers<Customer>());

    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(customerBloc);

    return state.data;
  }

  /// Get by either customerId, name, phone_number [byAnyTerm]
  /// @Return: `List<Customer>`
  static Future<List<Customer>> byAnyTerm(term) async {
    final customerBloc = CustomerAccountBloc(
      firestore: FirebaseFirestore.instance,
    );

    // Load all data initially to pass to the search delegate
    customerBloc.add(
      SearchCustomers<Customer>(
        field: 'customerId',
        optField: 'name',
        auxField: 'phone',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(customerBloc);

    return state.data;
  }

  static Future<Customer> byCustomerId(customerId) async {
    final customerBloc = CustomerAccountBloc(
      firestore: FirebaseFirestore.instance,
    );

    // Load all data initially to pass to the search delegate
    customerBloc.add(
      GetCustomerById<Customer>(field: 'customerId', documentId: customerId),
    );

    // Ensure to wait for the data to be loaded
    final state =
        await customerBloc.stream.firstWhere(
              (state) => state is CustomerLoaded<Customer>,
            )
            as CustomerLoaded<Customer>;

    return state.data.isEmpty ? Customer.notFound : state.data;
  }
}
