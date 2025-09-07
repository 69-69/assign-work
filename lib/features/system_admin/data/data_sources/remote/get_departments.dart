import 'package:assign_erp/features/system_admin/data/models/department_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/department_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetDepartments {
  static final departBloc = DepartmentBloc(
    firestore: FirebaseFirestore.instance,
  );

  static Future<List<Department>> load() async {
    // Load all data initially to pass to the search delegate
    departBloc.add(GetSetups<Department>());

    // Ensure to wait for the data to be loaded
    final allData =
        await departBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<Department>,
            )
            as SetupsLoaded<Department>;

    return allData.data;
  }

  /// Get by either name, lead, code [byAnyTerm]
  /// @Return: `List<Department>`
  static Future<List<Department>> byAnyTerm(term) async {
    // Load all data initially to pass to the search delegate
    departBloc.add(
      SearchSetup<Department>(
        field: 'name',
        optField: 'lead',
        auxField: 'code',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final allData =
        await departBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<Department>,
            )
            as SetupsLoaded<Department>;

    return allData.data;
  }
}
