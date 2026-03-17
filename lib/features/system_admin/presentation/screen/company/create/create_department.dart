import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/department_model.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/department_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/widget/company_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateDepartment<T> on BuildContext {
  Future<void> openDepartmentForm({
    Department? serverDepart,
    List<String>? existingCodes,
  }) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: serverDepart != null
          ? 'Edit ${serverDepart.name}'
          : 'Create Department',
      body: _AddDepartmentForm(
        serverDepart: serverDepart,
        existingCodes: existingCodes,
      ),
    ),
  );
}

class _AddDepartmentForm extends StatefulWidget {
  final Department? serverDepart;
  final List<String>? existingCodes;

  const _AddDepartmentForm({this.serverDepart, this.existingCodes});

  @override
  State<_AddDepartmentForm> createState() => _AddDepartmentFormState();
}

class _AddDepartmentFormState extends State<_AddDepartmentForm> {
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();
  final List<Department> _departments = [];

  Department? get _serverDepart => widget.serverDepart;

  bool get _isServerNull => _serverDepart == null;

  List<String>? get _existingCodes => widget.existingCodes;

  bool get _isFormValid => _formKey.currentState?.validate() ?? false;

  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  String get _employeeId => _employee!.employeeId;

  DepartmentBloc get _bloc => context.read<DepartmentBloc>();

  void _onSubmit() {
    // Case 1: Update existing department
    if (!_isServerNull) {
      _updateDepartment();
      return;
    }

    // Case 2: Form validation or empty departments
    if (!_isFormValid && _departments.isNotEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Add new departments
    _addNewDepartments();
  }

  void _addNewDepartments() {
    // Append department code to each department
    final newDeparts = _departments
        .map(
          (e) => e.copyWith(
            code: e.name.nextCode(existingCodes: _existingCodes),
            createdBy: _employeeName,
            history: history(),
          ),
        )
        .toList();

    _bloc.add(AddSetup<List<Department>>(data: newDeparts));
  }

  void _updateDepartment() {
    final updated = _departments.first.copyWith(
      id: _serverDepart!.id,
      code: _serverDepart!.code,
      createdBy: _serverDepart?.createdBy,
      updatedBy: _employeeName,
      history: history(AuditAction.updated),
    );

    _bloc.add(UpdateSetup<Department>(documentId: updated.id, data: updated));
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    if (!_isServerNull) ..._serverDepart!.history,
    AuditLog(action: action, actionBy: _employeeId),
  ];

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _formResetKey = UniqueKey(); // 💥 full rebuild
      _departments.clear();
    });
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(
      msg,
      onCallback: () => _isServerNull ? _resetForm() : Navigator.pop(context),
    );
  }

  void _handleBlocState(BuildContext cxt, SetupState<Department> state) {
    final note = _isServerNull ? 'Department created' : 'Changes saved';

    switch (state) {
      case SetupAdded<Department>(message: var msg):
      case SetupUpdated<Department>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<Department>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DepartmentBloc, SetupState<Department>>(
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
      mainAxisSize: MainAxisSize.min,
      children: [
        FormGroupCard(
          showCollapseButton: _isServerNull,
          title: 'Department(s)',
          subTitle: '\nInternal departments within your company',
          children: [_buildForm()],
        ),
        context.confirmableActionButton(
          label: _isServerNull ? 'Create Department' : null,
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  DynamicTextFields _buildForm() {
    return DynamicTextFields(
      showButton: _isServerNull,
      fieldsConfig: CompanyFormInputs.departmentsFields,
      initialData: [?_serverDepart?.toMap()],
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        CompanyFormInputs.updateListFromData<Department>(
          _departments,
          map: data,
          fromMap: (map, id) => Department.fromMap(map),
        );
      },
    );
  }
}
