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
  final _formKey = GlobalKey<FormState>();
  final List<Department> _departments = [];
  Department? get _serverDepart => widget.serverDepart;
  bool get _isValid => _formKey.currentState?.validate() ?? false;
  Employee? get _employee => context.employee;

  void _onSubmit() {
    if (_isValid && _departments.isNotEmpty) {
      final bloc = context.read<DepartmentBloc>();

      if (_serverDepart != null) {
        final updated = _prepareUpdatedDepartment();

        bloc.add(
          UpdateSetup<Department>(documentId: updated.id, data: updated),
        );
        context.showAlertOverlay('Changes successfully saved');
      } else {
        final newDepartments = _prepareNewDepartments();
        bloc.add(AddSetup<List<Department>>(data: newDepartments));

        _formKey.currentState!.reset();
        context.showAlertOverlay('Department(s) successfully created');
        Navigator.pop(context);
      }
    }
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    AuditLog(action: action, actionBy: _employee!.employeeId),
  ];

  Department _prepareUpdatedDepartment() {
    final updated = _departments.first.copyWith(
      id: _serverDepart!.id,
      code: _serverDepart!.code,
      updatedBy: _employee!.fullName,
      history: history(),
    );
    return updated;
  }

  List<Department> _prepareNewDepartments() {
    // Append department code to each department
    final newDeparts = _departments
        .map(
          (e) => e.copyWith(
            code: e.name.generateUniqueCode(),
            createdBy: _employee!.fullName,
            history: history(AuditAction.updated),
          ),
        )
        .toList();
    return newDeparts;
  }

  // load existing departments
  void _loadExistingDeparts() {
    if (_serverDepart != null) {
      _departments
        ..clear()
        ..add(_serverDepart!);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExistingDeparts();
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
      children: [
        FormGroupCard(
          children: [
            DynamicTextFields(
              showButton: _serverDepart == null,
              title: 'Company\'s Department(s)',
              fieldsConfig: CompanyFormInputs.departmentsFields,
              initialData: [?_serverDepart?.toMap()],
              onChanged: (List<Map<String, dynamic>> data) {
                if (_isValid) setState(() {});

                // Create a new line item
                _departments
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map((e) => Department.fromMap(e)));
              },
            ),
          ],
        ),
        context.confirmableActionButton(
          label: _serverDepart == null ? 'Create Department' : null,
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}
