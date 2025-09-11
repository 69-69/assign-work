import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/create_acc/employee_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetEmployees {
  static final employeeBloc = EmployeeBloc(
    firestore: FirebaseFirestore.instance,
  );

  static Future<List<Employee>> load() async {
    // Load all data initially to pass to the search delegate
    employeeBloc.add(GetSetups<Employee>());

    // Ensure to wait for the data to be loaded
    final allData =
        await employeeBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<Employee>,
            )
            as SetupsLoaded<Employee>;

    return allData.data;
  }

  /// Get by either name, lead, code [byAnyTerm]
  /// @Return: `List<Employee>`
  static Future<List<Employee>> byAnyTerm(term) async {
    // Load all data initially to pass to the search delegate
    employeeBloc.add(
      SearchSetup<Employee>(
        field: 'fullName',
        optField: 'role',
        auxField: 'employeeId',
        query: term,
      ),
    );

    // Ensure to wait for the data to be loaded
    final allData =
        await employeeBloc.stream.firstWhere(
              (state) => state is SetupsLoaded<Employee>,
            )
            as SetupsLoaded<Employee>;

    return allData.data;
  }
}
