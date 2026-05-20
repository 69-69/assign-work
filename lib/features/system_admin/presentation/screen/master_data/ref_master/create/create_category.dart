import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/form_validity.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/category_model.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/category_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/ref_master/widget/ref_master_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateCategory<T> on BuildContext {
  Future<void> openAddCategory({Category? serverAttribute}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: serverAttribute != null
          ? 'Edit ${serverAttribute.name}'
          : 'New Category',
      body: _AddCategoryForm(serverCategory: serverAttribute),
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
  bool _isSubmitting = false;
  final List<Category> _categories = [];
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();
  bool _isFormValid = false; // _formKey.currentState?.validate() ??

  Category? get _serverCategory => widget.serverCategory;
  bool get _isServerNull => _serverCategory == null;

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;
  String get _employeeStore => _employee!.storeNumber;
  CategoryBloc get _bloc => context.read<CategoryBloc>();

  void _updateValidity() => _formKey.updateValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

  void _onSubmit() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Category
    if (_isFormValid && (_serverCategory?.isNotEmpty ?? false)) {
      _updatedCategory();
      return;
    }

    // Case 2: Form validation or empty Category
    if (!_isFormValid && _categories.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Create new Categories
    _newCategories();
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    if (!_isServerNull) ..._serverCategory!.history,
    AuditLog(action: action, actionBy: _employeeName),
  ];

  void _newCategories() {
    final newCats = _categories
        .map(
          (e) => e.copyWith(
            storeNumber: _employeeStore,
            createdBy: _employeeName,
            history: history(),
          ),
        )
        .toList();
    _bloc.add(AddSetup<List<Category>>(data: newCats));
  }

  void _updatedCategory() {
    final updated = _categories.first.copyWith(
      id: _serverCategory!.id,
      name: _serverCategory!.name,
      updatedBy: _employeeName,
      history: history(AuditAction.updated),
    );
    _bloc.add(UpdateSetup<Category>(documentId: updated.id, data: updated));
  }

  void _populateCategoryForm() {
    if (_serverCategory != null) {
      _categories
        ..clear()
        ..add(_serverCategory!);
    }
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
      });
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(
      msg,
      onCallback: () => _isServerNull ? _resetForm() : Navigator.pop(context),
    );
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, SetupState<Category> state) {
    final note = _isServerNull ? 'Category created' : 'Changes saved';
    switch (state) {
      case SetupAdded<Category>(message: var msg):
      case SetupUpdated<Category>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<Category>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _populateCategoryForm();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryBloc, SetupState<Category>>(
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
          children: [
            DynamicTextFields(
              isRepeatable: true,
              title: 'Item Categories',
              fieldsConfig: RefMasterFormInputs.categoryField,
              initialData: [?_serverCategory?.toMap()],
              onChanged: (List<Map<String, dynamic>> data) {
                // if (_isFormValid) setState(() {});

                // Create a new line item
                _categories
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map((e) => Category.fromMap(e)));

                _updateValidity();
              },
            ),
          ],
        ),
        context.confirmableActionButton(
          isDisabled: _isSubmitting || !_isFormValid,
          label: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Create Category')
              : (_isSubmitting ? 'Updating...' : null),
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}
