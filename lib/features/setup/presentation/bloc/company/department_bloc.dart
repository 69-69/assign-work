import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/setup/data/models/department_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';

class DepartmentBloc extends SetupBloc<Department> {
  DepartmentBloc({required super.firestore})
    : super(
        collectionPath: departmentsDBCollectionPath,
        fromFirestore: (data, id) => Department.fromMap(data, id: id),
        toFirestore: (depart) => depart.toMap(),
        toCache: (depart) => depart.toCache(),
      );
}
