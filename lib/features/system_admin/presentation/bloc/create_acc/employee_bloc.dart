import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class EmployeeBloc extends SetupBloc<Employee> {
  EmployeeBloc({required super.firestore})
    : super(
        collectionPath: employeesDBColPath,
        fromFirestore: (data, id) => Employee.fromMap(data, id: id),
        toFirestore: (emp) => emp.toMap(),
        toCache: (emp) => emp.toCache(),
      );
}
