import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_dialog.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/create_acc/employee_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/search_departments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AssignDepartmentDialog on BuildContext {
  Future<void> openAssignEmployeeDepartmentDialog({
    required String employeeId,
    String? employeeName,
  }) async => await AssignEmployeeDepartment(
    employeeId: employeeId,
    employeeName: employeeName,
  ).openCustomDialog(this, isScrollControlled: true, constraints: null);
}

class AssignEmployeeDepartment extends StatelessWidget {
  final String employeeId;
  final String? employeeName;

  const AssignEmployeeDepartment({
    super.key,
    required this.employeeId,
    this.employeeName,
  });

  String get _employeeName => (employeeName ?? 'Employee').toTitle;

  void _handleBlocState(BuildContext cxt, SetupState<Employee> state) {
    switch (state) {
      case SetupUpdated<Employee>(message: _):
        _showAlert(cxt);
      case SetupError<Employee>():
        _showAlert(cxt, 'Error saving changes');
      case _: // no action
    }
  }

  void _showAlert(BuildContext cxt, [String? msg]) {
    return cxt.showAlertOverlay(
      msg ?? 'Department successfully assigned to $_employeeName',
      onCallback: () => Navigator.pop(cxt),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmployeeBloc, SetupState<Employee>>(
      listener: _handleBlocState,
      child: _buildAlertDialog(context),
    );
  }

  Widget _buildAlertDialog(BuildContext context) {
    return CustomDialog(
      title: DialogTitle(
        title: 'Assign Department',
        subtitle: 'Assign department to $_employeeName',
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
        child: SearchDepartments(
          onChanged: (id, code, department) {
            context.read<EmployeeBloc>().add(
              UpdateSetup<Employee>(
                documentId: employeeId,
                mapData: {'departmentCode': code},
              ),
            );
          },
        ),
      ),
    );
  }
}
