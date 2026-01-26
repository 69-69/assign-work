import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_dialog.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/create_acc/employee_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/search_stores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AssignStoreBranchDialog on BuildContext {
  Future<void> assignEmployeeToStoreBranchDialog({
    required String employeeId,
    String? employeeName,
  }) async => await AssignStoreBranch(
    employeeId: employeeId,
    employeeName: employeeName,
  ).openCustomDialog(this, isScrollControlled: true, constraints: null);
}

class AssignStoreBranch extends StatelessWidget {
  final String employeeId;
  final String? employeeName;

  const AssignStoreBranch({
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
        _showAlert(cxt, 'Something went wrong! Please, try again');
      case _: // no action
    }
  }

  void _showAlert(BuildContext cxt, [String? msg]) {
    return cxt.showAlertOverlay(
      msg ?? '$_employeeName is now working at this branch',
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

  _buildAlertDialog(BuildContext context) {
    return CustomDialog(
      title: DialogTitle(
        title: 'Assign Store Branch',
        subtitle: 'Assign $_employeeName to a store branch',
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
        child: SearchStoreBranches(
          onChanged: (id, store) {
            context.read<EmployeeBloc>().add(
              UpdateSetup<Employee>(
                documentId: employeeId,
                mapData: {'storeNumber': id},
              ),
            );
          },
        ),
      ),
    );
  }
}
