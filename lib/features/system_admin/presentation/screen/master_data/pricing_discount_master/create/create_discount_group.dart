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
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/discount_group_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/discount_group_master_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/pricing_discount_master/widget/discount_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateDiscountGroupMaster<T> on BuildContext {
  Future<void> openAddDiscountGroup({DiscountGroup? serverDiscountGroup}) =>
      openBottomSheet(
        isExpand: false,
        child: BottomSheetScaffold(
          title: serverDiscountGroup != null
              ? 'Edit ${serverDiscountGroup.name}'.toTitle
              : 'New Discount Group',
          body: _AddDiscountGroupForm(serverDiscountGroup: serverDiscountGroup),
        ),
      );
}

class _AddDiscountGroupForm extends StatefulWidget {
  final DiscountGroup? serverDiscountGroup;

  const _AddDiscountGroupForm({this.serverDiscountGroup});

  @override
  State<_AddDiscountGroupForm> createState() => _AddDiscountGroupFormState();
}

class _AddDiscountGroupFormState extends State<_AddDiscountGroupForm> {
  bool _isSubmitting = false;
  final List<DiscountGroup> _discountGroups = [];
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();
  bool _isFormValid = false; // _formKey.currentState?.validate() ??

  DiscountGroup? get _serverDiscountGroup => widget.serverDiscountGroup;

  bool get _isServerNull => _serverDiscountGroup == null;

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  String get _employeeStore => _employee!.storeNumber;

  DiscountGroupMasterBloc get _bloc => context.read<DiscountGroupMasterBloc>();

  void _updateValidity() => _formKey.updateValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

  void _onSubmit() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Discount Rule
    if (_isFormValid && (_serverDiscountGroup?.isNotEmpty ?? false)) {
      _updatedDiscountGroup();
      return;
    }

    // Case 2: Form validation or empty Discount Rule
    if (!_isFormValid && _discountGroups.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Create new Discount Rule
    _newDiscountGroup();
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    if (!_isServerNull) ..._serverDiscountGroup!.history,
    AuditLog(action: action, actionBy: _employeeName),
  ];

  void _newDiscountGroup() {
    final newDiscounts = _discountGroups
        .map((e) => e.copyWith(storeNumber: _employeeStore, history: history()))
        .toList();

    _bloc.add(AddSetup<List<DiscountGroup>>(data: newDiscounts));
  }

  void _updatedDiscountGroup() {
    final updated = _discountGroups.first.copyWith(
      id: _serverDiscountGroup!.id,
      history: history(AuditAction.updated),
    );
    _bloc.add(
      UpdateSetup<DiscountGroup>(documentId: updated.id, data: updated),
    );
  }

  void _populateDiscountGroupForm() {
    if (!_isServerNull) {
      _discountGroups
        ..clear()
        ..add(_serverDiscountGroup!);
    }
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _isFormValid = false;
        _discountGroups.clear();
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

  void _handleBlocState(BuildContext cxt, SetupState<DiscountGroup> state) {
    final note = _isServerNull ? 'Discount group created' : 'Changes saved';
    switch (state) {
      case SetupAdded<DiscountGroup>(message: var msg):
      case SetupUpdated<DiscountGroup>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<DiscountGroup>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _populateDiscountGroupForm();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiscountGroupMasterBloc, SetupState<DiscountGroup>>(
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
      spacing: 20,
      children: [
        FormGroupCard(
          title: 'Discount Group',
          helperText: '\nTap the + button to add multiple groups',
          children: [
            DynamicTextFields(
              isRepeatable: _isServerNull,
              fieldsConfig: DiscountFormInputs.discountGroupFields,
              initialData: [?_serverDiscountGroup?.toMap(true)],
              onChanged: (List<Map<String, dynamic>> data) {
                _discountGroups
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map(DiscountGroup.fromMap));

                _updateValidity();
              },
            ),
          ],
        ),

        context.confirmableActionButton(
          isDisabled: _isSubmitting || !_isFormValid,
          label: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Create Discount Group')
              : (_isSubmitting ? 'Updating...' : null),
          onPressed: _onSubmit,
        ),
      ],
    );
  }
}
