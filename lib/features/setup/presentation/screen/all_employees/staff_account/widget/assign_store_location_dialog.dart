import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_dialog.dart';
import 'package:assign_erp/features/setup/data/models/employee_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/create_acc/employee_bloc.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/setup/presentation/screen/company/widget/search_stores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AssignStoreLocationDialog on BuildContext {
  Future<void> assignEmployeeToStoreLocationDialog({
    required String employeeId,
    String? employeeName,
  }) => showModalBottomSheet(
    context: this,
    isDismissible: false,
    isScrollControlled: true,
    backgroundColor: kTransparentColor,
    builder: (_) =>
        AssignStoreLocation(employeeId: employeeId, employeeName: employeeName),
  );
}

class AssignStoreLocation extends StatelessWidget {
  final String employeeId;
  final String? employeeName;

  const AssignStoreLocation({
    super.key,
    required this.employeeId,
    this.employeeName,
  });

  String get _employeeName => (employeeName ?? 'Employee').toTitleCase;

  @override
  Widget build(BuildContext context) {
    return _buildAlertDialog(context);
  }

  _buildAlertDialog(BuildContext context) {
    return CustomDialog(
      title: DialogTitle(
        title: 'Assign Store Location',
        subtitle: 'Assign store to $_employeeName',
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
        child: SearchStores(
          onChanged: (id, store) {
            context.read<EmployeeBloc>().add(
              UpdateSetup<Employee>(
                documentId: employeeId,
                mapData: {'storeNumber': id},
              ),
            );

            context.showCustomSnackBar(
              'Store Location assigned to $_employeeName successfully',
            );
          },
        ),
      ),
    );
  }
}
