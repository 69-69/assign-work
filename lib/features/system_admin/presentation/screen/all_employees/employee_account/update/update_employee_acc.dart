import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/create_acc/employee_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/employee_account/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateEmployeeAccount<T> on BuildContext {
  Future<void> openUpdateEmployee({Employee? employee}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: employee?.fullName.toTitle,
      subtitle: employee?.role.toTitle,
      body: _UpdateEmployeeForm(employee: employee!),
    ),
  );
}

class _UpdateEmployeeForm extends StatefulWidget {
  final Employee employee;

  const _UpdateEmployeeForm({required this.employee});

  @override
  State<_UpdateEmployeeForm> createState() => _UpdateEmployeeFormState();
}

class _UpdateEmployeeFormState extends State<_UpdateEmployeeForm> {
  Employee get _employee => widget.employee;

  String? _selectedStatus;

  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  bool get _isFormValid => _formKey.currentState!.validate();
  late final _nameController = TextEditingController(text: _employee.fullName);
  late final _emailController = TextEditingController(text: _employee.email);
  late final _phoneController = TextEditingController(
    text: _employee.mobileNumber,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_isFormValid || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    /// Update employee account
    final item = _employee.copyWith(
      fullName: _nameController.text,
      email: _emailController.text,
      mobileNumber: _phoneController.text,
      status: _selectedStatus ?? _employee.status,
      updatedBy: context.employee!.fullName,
    );

    context.read<EmployeeBloc>().add(
      UpdateSetup<Employee>(documentId: _employee.id, data: item),
    );
  }

  /// Update Employee Account Status
  void _updateAccountStatus(String status) {
    _employee.copyWith(status: status);
    setState(() => _selectedStatus = status);

    context.read<EmployeeBloc>().add(
      UpdateSetup<Employee>(
        documentId: _employee.id,
        mapData: {'status': status},
      ),
    );
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => Navigator.pop(context));
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, SetupState<Employee> state) {
    switch (state) {
      case SetupUpdated<Employee>(message: var msg):
        _showAlert(msg ?? 'Changes saved successfully');
      case SetupError<Employee>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmployeeBloc, SetupState<Employee>>(
      listener: _handleBlocState,
      child: Form(
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
        if (_employee.canBeReassigned) ...{
          FormGroupCard(
            title: 'Account Status',
            children: [
              AccountStatusDropdown(
                initialValue: _selectedStatus ?? _employee.status,
                onStatusChanged: (v) =>
                    v.isNullOrEmpty ? null : _updateAccountStatus(v!),
              ),
            ],
          ),
        },
        HorizontalDivider(thickness: 8.0),
        FormGroupCard(
          title: 'Employee\'s Details',
          children: [
            NameAndMobile(
              nameController: _nameController,
              mobileController: _phoneController,
              onNameChanged: (s) {
                if (_isFormValid) setState(() {});
              },
              onMobileChanged: (s) {
                if (_isFormValid) setState(() {});
              },
            ),
            const SizedBox(height: 20.0),
            EmailAndPasscode(
              emailController: _emailController,
              onEmailChanged: (s) {
                if (_isFormValid) setState(() {});
              },
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(
          onPressed: _onSubmit,
          isDisabled: _isSubmitting,
          label: _isSubmitting ? 'Updating...' : null,
        ),
      ],
    );
  }
}
