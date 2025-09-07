import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/features/system_admin/data/models/role_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';

class RoleBloc extends SetupBloc<Role> {
  RoleBloc({required super.firestore})
    : super(
        collectionPath: rolesDBCollectionPath,
        fromFirestore: (data, id) => Role.fromMap(data, id: id),
        toFirestore: (role) => role.toMap(),
        toCache: (role) => role.toCache(),
      );
}
