import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
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

  void _showAlert(String msg) {
    context.showAlertOverlay(msg);
  }

  void _handleBlocState(BuildContext cxt, SetupState<Role> state) {
    switch (state) {
      case SetupDeleted<Role>(message: var msg):
        _showAlert(msg ?? 'Deleted successfully');
      case SetupError<Role>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoleBloc, SetupState<Role>>(
      listener: _handleBlocState,
      child: _buildBody(),
    );
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

  Widget _buildCard(BuildContext c, List<Role> roles) {
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
      primaryLabel: 'Create Role',
      refreshLabel: 'Refresh Roles',
      dataLength: roles.length,
      tertiaryIcon: Icons.security,
      secondaryLabel: 'Edit Role',
      secondaryIcon: Icons.edit,
      tertiaryLabel: 'Assign Permission',
      tertiaryTooltip: 'Assign new permissions to role',
      onPrimary: () => context.openCreateNewRole(),
      onRefresh: () => _bloc.add(RefreshSetups<Role>()),
      onSecondary: _isChecked == true
          ? () async => _onEditTap(roles, _selectedRole?.id ?? '')
          : null,
      onTertiary: _isChecked == true
          ? () async =>
                // Assign role & permission to the selected user
                _onEditTap(roles, _selectedRole?.id ?? '', isAssignRole: true)
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

  Future<void> _onEditTap(
    List<Role> roles,
    String id, {
    bool? isAssignRole,
  }) async {
    if (id.isEmpty || roles.isEmpty) return;

    Role? role = _findRole(id: id, roles);

    if (role != null) {
      /// Update specific role
      await context.openUpdateRole(isAssignRole: isAssignRole, role: role);
    }
  }

  Future<void> _onDeleteTap(List<Role> roles, String id) async {
    {
      Role? role = _findRole(id: id, roles);
      if (role == null) return;
      if (!_guardPrimaryRole(role)) return;

      final isConfirmed = await context.confirmUserActionDialog();
      if (mounted && isConfirmed) {
        /// Delete specific role
        _bloc.add(DeleteSetup<String>(documentId: role.id));
        setState(() => roles.remove(role));
      }
    }
  }

  // Prevent deletion of the primary Role associated with the [business owner]
  bool _guardPrimaryRole(Role role) {
    if (!role.canBeDeleted) {
      context.showAlertOverlay(
        'Default Role is associated with ${role.name.toUpperAll} and cannot be deleted.',
        bgColor: kDangerColor,
      );
      return false;
    }
    return true;
  }
}
