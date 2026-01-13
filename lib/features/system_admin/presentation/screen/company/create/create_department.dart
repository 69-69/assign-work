import 'package:assign_erp/core/constants/app_colors.dart';
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
  Future<void> openAddDepartment({Department? serverDepart}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: serverDepart != null
          ? 'Edit ${serverDepart.name}'
          : 'Create Department',
      body: _AddDepartmentForm(serverDepart: serverDepart),
    ),
  );
}

class _AddDepartmentForm extends StatefulWidget {
  final Department? serverDepart;

  const _AddDepartmentForm({this.serverDepart});

  @override
  State<_AddDepartmentForm> createState() => _AddDepartmentFormState();
}

class _AddDepartmentFormState extends State<_AddDepartmentForm> {
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();
  final List<Department> _departments = [];

  Department? get _serverDepart => widget.serverDepart;

  bool get _isFormValid => _formKey.currentState?.validate() ?? false;

  Employee? get _employee => context.employee;

  DepartmentBloc get _bloc => context.read<DepartmentBloc>();

  bool get _nullServer => _serverDepart == null;

  void _onSubmit() {
    // Case 1: Update existing department
    if (_serverDepart != null) {
      _updateDepartment();
      return;
    }

    // Case 2: Form validation or empty departments
    if (!_isFormValid && _departments.isNotEmpty) {
      _showErrorAlert('Please enter all required fields', kDangerColor);
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
            code: e.name.generateUniqueCode(),
            createdBy: _employee!.fullName,
            history: history(),
          ),
        )
        .toList();

    _bloc.add(AddSetup<List<Department>>(data: newDeparts));
    _showSuccessAlert('Department(s) successfully created');
  }

  void _updateDepartment() {
    final updated = _departments.first.copyWith(
      id: _serverDepart!.id,
      code: _serverDepart!.code,
      updatedBy: _employee!.fullName,
      history: history(AuditAction.updated),
    );

    _bloc.add(UpdateSetup<Department>(documentId: updated.id, data: updated));
    _showSuccessAlert('Changes successfully saved');
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    AuditLog(action: action, actionBy: _employee!.employeeId),
  ];

  void _showSuccessAlert(String message) {
    context.showAlertOverlay(
      message,
      onCallback: () =>
          _serverDepart != null ? Navigator.pop(context) : _resetForm(),
    );
  }

  void _showErrorAlert(String message, Color bgColor) {
    context.showAlertOverlay(message, bgColor: bgColor);
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _formResetKey = UniqueKey(); // 💥 full rebuild
      _departments.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: KeyedSubtree(key: _formResetKey, child: _buildBody(context)),
    );
  }

  Column _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FormGroupCard(
          showCollapseButton: _nullServer,
          title: 'Department(s)',
          subTitle: '\nInternal departments within your company',
          children: [_buildForm()],
        ),
        context.confirmableActionButton(
          label: _nullServer ? 'Create Department' : null,
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  DynamicTextFields _buildForm() {
    return DynamicTextFields(
      showButton: _nullServer,
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
