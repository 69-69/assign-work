import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/data/models/permission_model.dart';
import 'package:assign_erp/features/system_admin/data/models/role_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/create_roles/role_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_roles/widget/form_inputs.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_roles/widget/permission_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateRole<T> on BuildContext {
  Future<void> openUpdateRole({required Role role, bool? isAssignRole}) =>
      openBottomSheet(
        isExpand: false,
        child: BottomSheetScaffold(
          title: isAssignRole == true ? 'Assign Permissions' : 'Edit Role',
          subtitle: role.name,
          body: _UpdateRoleForm(role: role, isAssignRole: isAssignRole),
        ),
      );
}

class _UpdateRoleForm extends StatefulWidget {
  final Role role;
  final bool? isAssignRole;

  const _UpdateRoleForm({required this.role, this.isAssignRole});

  @override
  State<_UpdateRoleForm> createState() => _UpdateRoleFormState();
}

class _UpdateRoleFormState extends State<_UpdateRoleForm> {
  bool _isSubmitting = false;
  Role get _role => widget.role;
  final _formKey = GlobalKey<FormState>();
  late Set<Permission> _assignedPermissions = {};
  late final _nameController = TextEditingController(text: _role.name);

  Employee? get _employee => context.employee;
  String get _employeeId => _employee!.employeeId;
  String get _employeeName => _employee!.fullName;

  Future<void> _onSubmit() async {
    final isRemovingAllPermissions = _assignedPermissions.isEmpty;

    if (!isRemovingAllPermissions || _isSubmitting) return;

    bool result = await _warnUser();
    if (!result) return;

    setState(() => _isSubmitting = true);

    if (mounted && _formKey.currentState!.validate()) {
      _updatedRole();
    }
  }

  Future<bool> _warnUser() async {
    final result = await context.confirmAction<bool>(
      const Text('Are you sure you want to remove all permissions?'),
      title: 'Remove All Permissions',
    );
    return result;
  }

  void _updatedRole() {
    final updatedRole = _role.copyWith(
      name: _nameController.text,
      permissions: _assignedPermissions,
      updatedBy: _employeeName,
      history: [
        ..._role.history,
        AuditLog(action: AuditAction.updated, actionBy: _employeeId),
      ],
    );

    context.read<RoleBloc>().add(
      OverrideSetup<Role>(documentId: _role.id, data: updatedRole),
    );
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => Navigator.pop(context));
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, SetupState<Role> state) {
    switch (state) {
      case SetupUpdated<Role>(message: var msg):
        _showAlert(msg ?? 'Changes saved');
      case SetupError<Role>():
        _showAlert('Error saving changes');
      case _: // no action
    }
  }

  @override
  void initState() {
    _assignedPermissions = Set.from(_role.permissions);
    super.initState();
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
      builder: (context, state) => Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: _buildCard(context),
      ),
    );
  }

  Column _buildCard(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.isAssignRole == null) ...[
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

        context.confirmableActionButton(
          onPressed: _onSubmit,
          isDisabled: _isSubmitting,
          label: _isSubmitting ? 'Updating...' : null,
        ),
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
