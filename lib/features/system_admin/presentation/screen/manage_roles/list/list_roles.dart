import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/nav/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/role_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/create_roles/role_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_roles/create/create_role.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_roles/update/update_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListRoles extends StatefulWidget {
  const ListRoles({super.key});

  @override
  State<ListRoles> createState() => _ListRolesState();
}

class _ListRolesState extends State<ListRoles> {
  bool? _isChecked;
  Role? _selectedRole;
  RoleBloc get _bloc => context.read<RoleBloc>();

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  BlocBuilder<RoleBloc, SetupState<Role>> _buildBody() {
    return BlocBuilder<RoleBloc, SetupState<Role>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<Role>() => context.loader,
          SetupsLoaded<Role>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Role',
                    onPressed: () => context.openCreateNewRole(),
                  )
                : _buildCard(context, results),
          SetupError<Role>(error: final error) => context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  _buildCard(BuildContext c, List<Role> roles) {
    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 1,
      headers: Role.dataTableHeader,
      toolbar: _buildToolbar(roles),
      toolbarAlignment: WrapAlignment.start,
      rows: roles.map((d) => d.itemAsList).toList(),
      onEditTap: (List<String> row) async => _onEditTap(roles, row.first),
      onDeleteTap: (List<String> row) async => _onDeleteTap(roles, row.first),
      onChecked: (bool? isChecked, List<String> row) =>
          _onChecked(roles, row.first, isChecked),
    );
  }

  _buildToolbar(List<Role> roles) {
    return ListToolbarButtons(
      createLabel: 'Create Role',
      refreshLabel: 'Refresh Roles',
      dataLength: roles.length,
      onCreate: () => context.openCreateNewRole(),
      onRefresh: () => _bloc.add(RefreshSetups<Role>()),
      optLabel: 'Assign Permission',
      optTooltip: 'Assign new permissions to role',
      optIcon: Icons.security,
      optOnPressed: _isChecked == true
          ? () async {
              if (_selectedRole == null) return;

              /// Assign permission to role
              await context.openUpdateRole(
                isAssign: true,
                role: _selectedRole!,
              );
            }
          : null,
    );
  }

  // Handle onChecked orders
  void _onChecked(List<Role> roles, String id, bool? isChecked) async {
    final role = _findRole(id: id, roles);

    setState(() {
      _isChecked = isChecked;

      if (_isChecked == true) {
        _selectedRole = role;
      }
    });
  }

  Role? _findRole(List<Role> roles, {required String id}) =>
      Role.findById(roles, id);

  Future<void> _onEditTap(List<Role> roles, String id) async {
    Role? role = _findRole(id: id, roles);

    if (role != null) {
      /// Update specific role
      await context.openUpdateRole(role: role);
    }
  }

  Future<void> _onDeleteTap(List<Role> roles, String id) async {
    {
      Role? role = _findRole(id: id, roles);
      if (role == null) return;

      final isConfirmed = await context.confirmUserActionDialog();
      if (mounted && isConfirmed) {
        /// Delete specific role
        _bloc.add(DeleteSetup<String>(documentId: role.id));
        setState(() => roles.remove(role));
      }
    }
  }
}
