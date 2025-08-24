import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/features/setup/data/models/supplier_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/product_config/suppliers_bloc.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetSuppliers {
  // static  final supplierBloc = SupplierBloc(firestore: FirebaseFirestore.instance);

  static Future<SetupsLoaded<Supplier>> _dataLoadedState(
    SupplierBloc bloc,
  ) async {
    return await bloc.stream.firstWhere(
          (state) => state is SetupsLoaded<Supplier>,
        )
        as SetupsLoaded<Supplier>;
  }

  static Future<List<Supplier>> load() async {
    final supplierBloc = SupplierBloc(firestore: FirebaseFirestore.instance);

    // Load all data initially to pass to the search delegate
    supplierBloc.add(GetSetups<Supplier>());

    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(supplierBloc);

    return state.data;
  }

  /// Get by either name, phone, contactPersonName [byAnyTerm]
  /// @Return: `List<Supplier>`
  static Future<List<Supplier>> byAnyTerm(term) async {
    final supplierBloc = SupplierBloc(firestore: FirebaseFirestore.instance);

    // Load all data initially to pass to the search delegate
    supplierBloc.add(
      SearchSetup<Supplier>(
        field: 'name',
        optField: 'phone',
        auxField: 'contactPersonName',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(supplierBloc);

    return state.data;
  }

  /// Get by supplierId [bySupplierId]
  static Future<Supplier> bySupplierId(String supplierId) async {
    final supplierBloc = SupplierBloc(firestore: FirebaseFirestore.instance);

    supplierBloc.add(GetSetupById<Supplier>(documentId: supplierId));

    try {
      final state = await supplierBloc.stream.firstWhere(
        (state) => state is SetupsLoaded<Supplier>,
        orElse: () => Supplier.notFound,
      );

      if (state is SetupsLoaded<Supplier>) {
        final data = state.data;
        return data.isNotEmpty ? data.first : Supplier.notFound;
      }
    } catch (e) {
      prettyPrint('Error fetching supplier', '$e');
    }

    return Supplier.notFound;
  }
}
