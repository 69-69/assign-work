import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/setup/data/models/department_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/company/department_bloc.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';
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
  bool isInProgress = false;
  final _formKey = GlobalKey<FormState>();
  final List<Department> _departmentList = [];
  Department? get _serverDepartment => widget.serverDepartment;
  bool get _isValid => _formKey.currentState?.validate() ?? false;

  void _isInProgress() {
    setState(() => isInProgress = !isInProgress);
  }

  void _onSubmit() {
    if (_isValid && _departmentList.isNotEmpty) {
      _isInProgress();
      final bloc = context.read<DepartmentBloc>();

      if (_serverDepartment != null) {
        final updated = _departmentList.first.copyWith(
          id: _serverDepartment!.id,
          code: _serverDepartment!.code,
        );

        bloc.add(
          UpdateSetup<Department>(documentId: updated.id, data: updated),
        );
      } else {
        final newDepartments = _prepareNewDepartment();
        bloc.add(AddSetup<List<Department>>(data: newDepartments));
      }

      _formKey.currentState!.reset();

      context.showAlertOverlay('Department(s) successfully created');
      _isInProgress();
      Navigator.pop(context);
    }
  }

  List<Department> _prepareNewDepartment() {
    // append department code to each department
    final newDeparts = _departmentList
        .map((e) => e.copyWith(code: e.name.generateUniqueCode()))
        .toList();
    return newDeparts;
  }

  // load existing departments
  void _loadExisting() {
    if (_serverDepartment != null) {
      _departmentList.clear();
      _departmentList.add(_serverDepartment!);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isInProgress,
      child: Opacity(
        opacity: isInProgress ? 0.5 : 1.0,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: _buildBody(context),
        ),
      ),
    );
  }

  Column _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FormGroupCard(
          children: [
            DynamicTextFields(
              title: _serverDepartment?.name ?? 'Organization\'s Departments',
              showButton: _serverDepartment != null,
              fieldsConfig: _fieldsConfig,
              initialData: [
                _serverDepartment?.toMap().map(
                      (key, value) => MapEntry(key, value.toString()),
                    ) ??
                    {},
              ],
              onChanged: (List<Map<String, String>> data) {
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

  List<FieldConfig> get _fieldsConfig {
    return [
      FieldConfig(
        key: 'name',
        type: TextInputType.text,
        helperText: 'Department name',
      ),
      FieldConfig(
        key: 'lead',
        type: TextInputType.text,
        helperText: 'Department Lead name',
      ),
      FieldConfig(
        key: 'description',
        type: TextInputType.multiline,
        maxLines: 3,
        helperText: 'Short description of the department\'s role',
      ),
    ];
  }
}
