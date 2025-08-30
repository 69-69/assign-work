import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/form_group_card.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/setup/data/models/employee_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/create_acc/employee_bloc.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/setup/presentation/screen/all_employees/staff_account/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateStaffAccount<T> on BuildContext {
  Future<void> openUpdateStaffAcc({Employee? employee}) => openBottomSheet(
    isExpand: false,
    child: FormBottomSheet(
      title: "Edit Employee's Account",
      subtitle: employee?.fullName,
      body: _UpdateStaffAccForm(employee: employee!),
    ),
  );
}

class _UpdateStaffAccForm extends StatefulWidget {
  final Employee employee;

  const _UpdateStaffAccForm({required this.employee});

  @override
  State<_UpdateStaffAccForm> createState() => _UpdateStaffAccFormState();
}

class _UpdateStaffAccFormState extends State<_UpdateStaffAccForm> {
  Employee get _employee => widget.employee;

  String? _selectedStatus;

  final _formKey = GlobalKey<FormState>();
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

  Future<void> _onSubmit() async {
    if (_isValid) {
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

      _formKey.currentState!.reset();

      if (mounted) {
        _toastMsg('account');

        Navigator.pop(context);
      }
    }
  }

  void _toastMsg(String title) {
    context.showAlertOverlay(
      '${_employee.fullName.toTitleCase} $title updated',
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

    _toastMsg('status');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _buildBody(context),
    );
  }

  Column _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
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
        HorizontalDivider(thickness: 8.0),
        FormGroupCard(
          title: 'Employee\'s Details',
          children: [
            NameAndMobile(
              nameController: _nameController,
              mobileController: _phoneController,
              onNameChanged: (s) {
                if (_isValid) setState(() {});
              },
              onMobileChanged: (s) {
                if (_isValid) setState(() {});
              },
            ),
            const SizedBox(height: 20.0),
            EmailAndPasscode(
              emailController: _emailController,
              onEmailChanged: (s) {
                if (_isValid) setState(() {});
              },
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(onPressed: _onSubmit),
      ],
    );
  }

  bool get _isValid => _formKey.currentState!.validate();
}
