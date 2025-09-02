import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/setup/data/models/permission_model.dart';
import 'package:assign_erp/features/setup/data/models/role_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/create_roles/role_bloc.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/setup/presentation/screen/manage_roles/widget/form_inputs.dart';
import 'package:assign_erp/features/setup/presentation/screen/manage_roles/widget/permission_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateRole<T> on BuildContext {
  Future<void> openUpdateRole({required Role role, bool? isAssign}) =>
      openBottomSheet(
        isExpand: false,
        child: FormBottomSheet(
          title: isAssign == true ? 'Assign Permissions' : 'Edit Role',
          subtitle: role.name,
          body: _UpdateRoleForm(role: role, isAssign: isAssign),
        ),
      );
}

class _UpdateRoleForm extends StatefulWidget {
  final Role role;
  final bool? isAssign;

  const _UpdateRoleForm({required this.role, this.isAssign});

  @override
  State<_UpdateRoleForm> createState() => _UpdateRoleFormState();
}

class _UpdateRoleFormState extends State<_UpdateRoleForm> {
  Role get _role => widget.role;
  final _formKey = GlobalKey<FormState>();
  late Set<Permission> _assignedPermissions = {};
  late final _nameController = TextEditingController(text: _role.name);

  @override
  void initState() {
    _assignedPermissions = Set.from(_role.permissions);
    super.initState();
  }

  Future<void> _onSubmit() async {
    final isRemovingAllPermissions = _assignedPermissions.isEmpty;

    if (isRemovingAllPermissions) {
      final result = await context.confirmAction<bool>(
        const Text('Are you sure you want to remove all permissions?'),
        title: 'Remove All Permissions',
      );
      if (!result) return;
    }

    if (mounted && _formKey.currentState!.validate()) {
      final updatedRole = _role.copyWith(
        name: _nameController.text,
        permissions: _assignedPermissions,
        updatedBy: context.employee?.fullName ?? 'unknown',
      );

      context.read<RoleBloc>().add(
        OverrideSetup<Role>(documentId: _role.id, data: updatedRole),
      );

      _formKey.currentState!.reset();

      context.showAlertOverlay(
        '${_nameController.text.toTitle} role successfully updated',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoleBloc, SetupState<Role>>(
      builder: (context, state) => Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: _buildBody(context),
      ),
    );
  }

  Column _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.isAssign == null) ...[
          const SizedBox(height: 10.0),
          RoleName(
            nameController: _nameController,
            onNameChanged: (s) {
              if (_formKey.currentState!.validate()) setState(() {});
            },
          ),
        ],

        PermissionCard(
          onSelectedFunc: _onSelectedFunc,
          initialPermissions: _assignedPermissions,
        ),
        const SizedBox(height: 10.0),

        context.confirmableActionButton(onPressed: _onSubmit),
        const SizedBox(height: 20.0),
      ],
    );
  }

  void _onSelectedFunc(Set<Permission> permissions, String module) {
    /*// Find all modules involved in this permission set
    final touchedModules = permissions.map((p) => p.module).toSet();
    // Remove all permissions that belong to any of these modules
    _assignedPermissions.removeWhere((p) => touchedModules.contains(p.module));*/

    // Remove all permissions that belong to any of these modules
    _assignedPermissions.removeWhere((p) => p.module == module);

    // Only add new permissions if there are any selected (if `permissions` is empty, don't add anything)
    if (permissions.isNotEmpty) {
      _assignedPermissions.addAll(permissions);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _assignedPermissions.clear();
    super.dispose();
  }
}

/* RULE FOR PERMISSIONS:
match /{subscriber}/{workspaceId}/inventory/{itemId} {
  allow read: if request.auth != null &&
                 exists(/databases/$(database)/documents/subscriber/$(workspaceId)/employees_account_db/$(request.auth.uid)) &&
                 get(/databases/$(database)/documents/subscriber/$(workspaceId))/roles/$(employee.roleId)).data.permissions.hasAny(['inventory.view']);
*/
