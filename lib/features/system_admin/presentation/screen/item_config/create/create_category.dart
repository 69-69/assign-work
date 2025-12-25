import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/category_model.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/item_config/category_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/item_config/widget/item_pref_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateCategory<T> on BuildContext {
  Future<void> openAddCategory({Category? serverCategory}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: serverCategory != null
          ? 'Edit ${serverCategory.name}'
          : 'Create Category',
      body: _AddCategoryForm(serverCategory: serverCategory),
    ),
  );
}

class _AddCategoryForm extends StatefulWidget {
  final Category? serverCategory;

  const _AddCategoryForm({this.serverCategory});

  @override
  State<_AddCategoryForm> createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends State<_AddCategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final List<Category> _categories = [];

  Category? get _serverCategory => widget.serverCategory;
  Employee? get _employee => context.employee;
  bool get _isValid => _formKey.currentState?.validate() ?? false;

  void _onSubmit() {
    if (_isValid && _categories.isNotEmpty) {
      final bloc = context.read<CategoryBloc>();

      if (_serverCategory != null) {
        final updated = _prepareUpdatedCategory();

        bloc.add(UpdateSetup<Category>(documentId: updated.id, data: updated));
        context.showAlertOverlay('Changes successfully saved');
      } else {
        final categories = _prepareNewCategories();
        bloc.add(AddSetup<List<Category>>(data: categories));

        _formKey.currentState!.reset();
        context.showAlertOverlay('Categories successfully created');
        Navigator.pop(context);
      }
    }
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    AuditLog(action: action, actionBy: _employee!.employeeId),
  ];

  Category _prepareUpdatedCategory() {
    final updated = _categories.first.copyWith(
      id: _serverCategory!.id,
      name: _serverCategory!.name,
      updatedBy: _employee!.fullName,
      history: history(AuditAction.updated),
    );
    return updated;
  }

  List<Category> _prepareNewCategories() {
    final newCats = _categories
        .map(
          (e) => e.copyWith(
            createdBy: _employee!.fullName,
            history: history(AuditAction.updated),
          ),
        )
        .toList();
    return newCats;
  }

  // load existing Categories
  void _loadExistingCategories() {
    if (_serverCategory != null) {
      _categories
        ..clear()
        ..add(_serverCategory!);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExistingCategories();
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
              showButton: true,
              title: 'Item Categories',
              fieldsConfig: ItemPref.categoryField,
              initialData: [?_serverCategory?.toMap()],
              onChanged: (List<Map<String, dynamic>> data) {
                if (_isValid) setState(() {});

                // Create a new line item
                _categories
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map((e) => Category.fromMap(e)));
              },
            ),
          ],
        ),
        context.confirmableActionButton(
          label: _serverCategory == null ? 'Create Category' : null,
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}
