import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/role_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/create_roles/role_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_roles/add/create_role.dart';
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
      anyWidget: _buildAnyWidget(),
      anyWidgetAlignment: WrapAlignment.start,
      rows: roles.map((d) => d.itemAsList()).toList(),
      onEditTap: (List<String> row) async => _onEditTap(roles, row.first),
      onDeleteTap: (List<String> row) async => _onDeleteTap(roles, row.first),
      onChecked: (bool? isChecked, List<String> row) =>
          _onChecked(roles, row.first, isChecked),
    );
  }

  _buildAnyWidget() {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      runAlignment: WrapAlignment.start,
      children: [
        context.elevatedButton(
          'Create Role',
          onPressed: () async => await context.openCreateNewRole(),
          bgColor: kDangerColor,
          txtColor: kWhiteColor,
        ),
        if (_isChecked == true) ...{
          context.elevatedButton(
            'Assign Permission',
            onPressed: () async {
              if (_selectedRole == null) return;

              /// Assign permission to role
              await context.openUpdateRole(
                isAssign: true,
                role: _selectedRole!,
              );
            },
            bgColor: kGrayBlueColor,
            txtColor: kWhiteColor,
          ),
        },
      ],
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
        context.read<RoleBloc>().add(DeleteSetup<String>(documentId: role.id));
        setState(() => roles.remove(role));
      }
    }
  }
}
