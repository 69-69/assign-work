import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_vendor/suppliers_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetSuppliers {
  // static  final supplierBloc = SupplierBloc(firestore: FirebaseFirestore.instance);

  static Future<ProcurementsLoaded<Supplier>> _dataLoadedState(
    SupplierBloc bloc,
  ) async {
    return await bloc.stream.firstWhere(
          (state) => state is ProcurementsLoaded<Supplier>,
        )
        as ProcurementsLoaded<Supplier>;
  }

  static Future<List<Supplier>> load() async {
    final supplierBloc = SupplierBloc(firestore: FirebaseFirestore.instance);

    // Load all data initially to pass to the search delegate
    supplierBloc.add(GetProcurements<Supplier>());

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
      SearchProcurement<Supplier>(
        field: 'name',
        optField: 'phone',
        auxField: 'contactPersons',
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

    supplierBloc.add(GetProcurementById<Supplier>(documentId: supplierId));

    try {
      final state = await supplierBloc.stream.firstWhere(
        (state) => state is ProcurementsLoaded<Supplier>,
        orElse: () => Supplier.empty,
      );

      if (state is ProcurementsLoaded<Supplier>) {
        final data = state.data;
        return data.isNotEmpty ? data.first : Supplier.empty;
      }
    } catch (e) {
      prettyPrint('Error fetching supplier', '$e');
    }

    return Supplier.empty;
  }
}
