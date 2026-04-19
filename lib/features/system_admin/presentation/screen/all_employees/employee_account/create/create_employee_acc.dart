import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/account_status.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/secret_hasher.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/create_acc/employee_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/employee_account/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateEmployeeAcc<T> on BuildContext {
  Future<void> openCreateEmployee() => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: 'New Employee Account',
      body: _CreateEmployeeForm(),
    ),
  );
}

class _CreateEmployeeForm extends StatefulWidget {
  const _CreateEmployeeForm();

  @override
  State<_CreateEmployeeForm> createState() => _CreateEmployeeFormState();
}

class _CreateEmployeeFormState extends State<_CreateEmployeeForm> {
  bool _isSubmitting = false;
  Key _formResetKey = UniqueKey();
  String _selectedRoleId = '';
  String _selectedRole = '';
  String _selectedDepartCode = '';
  String _selectedStoreNumber = '';
  String _newEmployeeId = '';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passcodeController = TextEditingController();

  void _generateEmployeeId() async {
    await DocType.employee.getShortUID(
      onChanged: (s) => setState(() => _newEmployeeId = s),
    );
  }

  Employee get _employee => Employee(
    employeeId: _newEmployeeId,
    fullName: _nameController.text,
    email: _emailController.text,
    mobileNumber: _phoneController.text,
    storeNumber: _selectedStoreNumber,
    roleId: _selectedRoleId,
    role: _selectedRole,
    departmentCode: _selectedDepartCode,
    status: AccountStatus.enabled.getName,
    workspaceId: context.workspace!.id,
    passCode: SecretHasher.hash(_passcodeController.text),
    createdBy: context.employee!.fullName,
    history: [
      AuditLog(
        action: AuditAction.created,
        actionBy: context.employee!.employeeId,
      ),
    ],
  );

  void _onSubmit() {
    if (!_isFormValid || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    /// Create employee account
    final item = _employee;

    context.read<EmployeeBloc>().add(AddSetup<Employee>(data: item));
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
      });
      _generateEmployeeId();
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => _resetForm());
  }

  void _handleBlocState(BuildContext cxt, SetupState<Employee> state) {
    switch (state) {
      case SetupAdded<Employee>(message: var msg):
        _showAlert(msg ?? 'Employee created successfully');
      case SetupError<Employee>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    _generateEmployeeId();
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmployeeBloc, SetupState<Employee>>(
      listener: _handleBlocState,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: KeyedSubtree(key: _formResetKey, child: _buildBody(context)),
      ),
    );
  }

  _buildEmployeeId() => Align(
    alignment: Alignment.topLeft,
    child: FittedBox(
      child: context.actionInfoButton(
        'Refresh Employee ID',
        count: _newEmployeeId,
        bgColor: kPrimaryColor,
        isTotal: false,
        onPressed: _generateEmployeeId,
      ),
    ),
  );

  Column _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildEmployeeId(),
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
              passcodeController: _passcodeController,
              onEmailChanged: (s) {
                if (_isFormValid) setState(() {});
              },
              onPasscodeChanged: (s) {
                if (_isFormValid) setState(() {});
              },
            ),
          ],
        ),
        FormGroupCard(
          title: 'Role & Permission',
          children: [
            StoreBranchesAndDepartment(
              onDepartChanged: (id, code, name) {
                if (_isFormValid) setState(() => _selectedDepartCode = code);
              },
              onStoresChange: (id, store) =>
                  setState(() => _selectedStoreNumber = id),
            ),
            const SizedBox(height: 20.0),
            EmployeeRoleDropdown(
              onRoleChanged: (id, role) => setState(() {
                _selectedRoleId = id ?? '';
                _selectedRole = role ?? '';
              }),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        context.confirmableActionButton(
          label: _isSubmitting ? 'Submitting...' : 'Create Employee',
          isDisabled: _isSubmitting,
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  bool get _isFormValid => _formKey.currentState!.validate();
}
