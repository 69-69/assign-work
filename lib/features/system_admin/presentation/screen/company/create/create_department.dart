import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/department_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/department_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateDepartment<T> on BuildContext {
  Future<void> openAddDepartment({Department? serverDepartment}) =>
      openBottomSheet(
        isExpand: false,
        child: FormBottomSheet(
          title: '${serverDepartment != null ? 'Edit' : 'Create'} Department',
          body: _AddDepartmentForm(serverDepartment: serverDepartment),
        ),
      );
}

class _AddDepartmentForm extends StatefulWidget {
  final Department? serverDepartment;

  const _AddDepartmentForm({this.serverDepartment});

  @override
  State<_AddDepartmentForm> createState() => _AddDepartmentFormState();
}

class _AddDepartmentFormState extends State<_AddDepartmentForm> {
  final _formKey = GlobalKey<FormState>();
  final List<Department> _departmentList = [];

  Department? get _serverDepartment => widget.serverDepartment;
  bool get _isValid => _formKey.currentState?.validate() ?? false;
  String get _employeeName => context.employee!.fullName;

  void _onSubmit() {
    if (_isValid && _departmentList.isNotEmpty) {
      final bloc = context.read<DepartmentBloc>();

      if (_serverDepartment != null) {
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

  Department _prepareUpdatedDepartment() {
    final updated = _departmentList.first.copyWith(
      id: _serverDepartment!.id,
      code: _serverDepartment!.code,
      updatedBy: _employeeName,
    );
    return updated;
  }

  List<Department> _prepareNewDepartments() {
    // Append department code to each department
    final newDeparts = _departmentList
        .map(
          (e) => e.copyWith(
            code: e.name.generateUniqueCode(),
            createdBy: _employeeName,
          ),
        )
        .toList();
    return newDeparts;
  }

  // load existing departments
  void _loadExistingDeparts() {
    if (_serverDepartment != null) {
      _departmentList
        ..clear()
        ..add(_serverDepartment!);
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
              showButton: _serverDepartment == null,
              title: _serverDepartment?.name ?? 'Organization\'s Departments',
              fieldsConfig: _fieldsConfig,
              initialData: [?_serverDepartment?.toMap()],
              /*initialData: [
              _serverDepartment?.toMap().map((k, v) => MapEntry(k, v.toString())) ?? {};
              ],*/
              onChanged: (List<Map<String, dynamic>> data) {
                if (_isValid) setState(() {});

                // Create a new line item
                _departmentList
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map((e) => Department.fromMap(e)));
              },
            ),
          ],
        ),
        context.confirmableActionButton(
          label: _serverDepartment == null ? 'Create Department' : null,
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  List<FieldGroupConfig> get _fieldsConfig {
    return [
      FieldGroupConfig(
        key: 'name',
        label: 'Department Name',
        type: TextInputType.text,
        helperText: 'Department name',
      ),
      FieldGroupConfig(
        key: 'lead',
        label: 'Department Lead',
        type: TextInputType.text,
        helperText: 'Department Lead name',
      ),
      FieldGroupConfig(
        key: 'description',
        label: 'Description',
        type: TextInputType.multiline,
        isTextArea: true,
        helperText: 'Short description of the department\'s role',
      ),
    ];
  }
}
