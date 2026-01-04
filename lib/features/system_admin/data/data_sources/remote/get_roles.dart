import 'package:assign_erp/features/system_admin/data/models/role_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/create_roles/role_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetRoles {
  static Future<SetupsLoaded<Role>> _dataLoadedState(RoleBloc bloc) async {
    return await bloc.stream.firstWhere((state) => state is SetupsLoaded<Role>)
        as SetupsLoaded<Role>;
  }

  static Future<List<Role>> load() async {
    // Ensure to wait for the data to be loaded
    final state =
        await RoleBloc(
              firestore: FirebaseFirestore.instance,
            ).stream.firstWhere((state) => state is SetupsLoaded<Role>)
            as SetupsLoaded<Role>;

    return state.data.isEmpty ? [] : state.data;
  }

  /// Get by either name [byAnyTerm]
  /// @Return: `List<Role>`
  static Future<List<Role>> byAnyTerm(term) async {
    final itemBloc = RoleBloc(firestore: FirebaseFirestore.instance);

    // Load all data initially to pass to the search delegate
    itemBloc.add(SearchSetup<Role>(primaryField: 'name', query: term));

    // Ensure to wait for the data to be loaded
    final state = await _dataLoadedState(itemBloc);

    return state.data;
  }

  /*/// Get by RoleId [byRoleId]
  static Future<Role> byRoleId(roleId) async {
    final roleBloc = RoleBloc(firestore: FirebaseFirestore.instance);

    // Load all data initially to pass to the search delegate
    roleBloc.add(GetSetupById<Role>(documentId: roleId));

    // Ensure to wait for the data to be loaded
    final state =
        await roleBloc.stream.firstWhere((state) => state is SetupsLoaded<Role>)
            as SetupLoaded<Role>;

    return state.data;
  }*/
}
