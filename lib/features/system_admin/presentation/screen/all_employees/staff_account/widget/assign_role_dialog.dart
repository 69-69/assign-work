import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_dialog.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/create_acc/employee_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/staff_account/widget/search_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AssignRoleDialog on BuildContext {
  Future<void> openAssignEmployeeRoleDialog({
    required String employeeId,
    String? employeeName,
  }) async =>
      await AssignEmployeeRole(
        employeeId: employeeId,
        employeeName: employeeName,
      ).openCustomDialog(
        this,
        isDismissible: true,
        isScrollControlled: true,
        constraints: null,
      );
}

class AssignEmployeeRole extends StatelessWidget {
  final String employeeId;
  final String? employeeName;

  const AssignEmployeeRole({
    super.key,
    required this.employeeId,
    this.employeeName,
  });

  String get _employeeName => (employeeName ?? 'Employee').toTitle;

  @override
  Widget build(BuildContext context) {
    return _buildAlertDialog(context);
  }

  _buildAlertDialog(BuildContext context) {
    return CustomDialog(
      title: DialogTitle(
        title: 'Assign Role',
        subtitle: 'Assign role to $_employeeName',
      ),
      body: _buildBody(context),
      actions: [],
    );
  }

  Container _buildBody(BuildContext context) {
    return Container(
      width: context.screenWidth,
      padding: EdgeInsets.only(bottom: context.bottomInsetPadding),
      child: AutofillGroup(
        child: SearchRole(
          onChanged: (id, role) {
            context.read<EmployeeBloc>().add(
              UpdateSetup<Employee>(
                documentId: employeeId,
                mapData: {'roleId': id, 'role': role},
              ),
            );

            context.showAlertOverlay(
              'Role assigned to $_employeeName successfully',
            );
          },
        ),
      ),
    );
  }
}
