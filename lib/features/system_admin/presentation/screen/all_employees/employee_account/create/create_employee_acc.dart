import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/account_status.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/extensions/form_validity.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/secret_hasher.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/auto_id_field.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
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
  String _selectedRoleId = '';
  String _selectedRole = '';
  String _selectedDepartCode = '';
  String _selectedStoreNumber = '';
  String _newEmployeeId = '';

  bool _isSubmitting = false;
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passcodeController = TextEditingController();

  bool _isFormValid = false; // _formKey.currentState?.validate() ?? false;
  EmployeeBloc get _bloc => context.read<EmployeeBloc>();

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

  void _syncValidity() => _formKey.syncValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

  void _onSubmit() {
    if (!_isFormValid || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    /// Create employee account
    final item = _employee;

    _bloc.add(AddSetup<Employee>(data: item));
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _isFormValid = false;
      });
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

  Column _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AutoIDField(
          label: 'Employee ID',
          onGenerate: () async => await DocType.employee.getShortUID,
          onChanged: (id) {
            setState(() => _newEmployeeId = id);
            _syncValidity();
          },
        ),
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
              onEmailChanged: (s) => _syncValidity(),
              onPasscodeChanged: (s) => _syncValidity(),
            ),
          ],
        ),
        FormGroupCard(
          isExpanded: false,
          title: 'Role & Permission',
          children: [
            StoreBranchesAndDepartment(
              onDepartChanged: (id, code, name) {
                setState(() => _selectedDepartCode = code);
                _syncValidity();
              },
              onStoresChange: (id, store) {
                setState(() => _selectedStoreNumber = id);
                _syncValidity();
              },
            ),
            const SizedBox(height: 20.0),
            EmployeeRoleDropdown(
              onRoleChanged: (id, role) {
                setState(() {
                  _selectedRoleId = id ?? '';
                  _selectedRole = role ?? '';
                });
                _syncValidity();
              },
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        context.confirmableActionButton(
          submitLabel: _isSubmitting ? 'Creating...' : 'Create Employee',
          isDisabled: _isSubmitting || !_isFormValid,
          onSubmit: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}
