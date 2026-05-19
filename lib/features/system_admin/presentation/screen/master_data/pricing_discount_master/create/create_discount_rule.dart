import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/discount_type.dart';
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
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/discount_rule_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/pricing_discount_master/widget/discount_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateDiscountRule<T> on BuildContext {
  Future<void> openAddDiscountRule({DiscountRule? serverRule}) =>
      openBottomSheet(
        isExpand: false,
        child: BottomSheetScaffold(
          title: serverRule != null
              ? 'Edit ${serverRule.getDiscountType}'.toTitle
              : 'New Discount Rule',
          body: _AddDiscountRuleForm(serverRule: serverRule),
        ),
      );
}

class _AddDiscountRuleForm extends StatefulWidget {
  final DiscountRule? serverRule;

  const _AddDiscountRuleForm({this.serverRule});

  @override
  State<_AddDiscountRuleForm> createState() => _AddDiscountRuleFormState();
}

class _AddDiscountRuleFormState extends State<_AddDiscountRuleForm> {
  bool _isSubmitting = false;
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();
  final List<DiscountRule> _discountRules = [];
  bool _isFormValid = false; // _formKey.currentState?.validate() ??
  DiscountType? _selectedDiscountType;

  DiscountRule? get _serverRule => widget.serverRule;

  bool get _isServerNull => _serverRule == null;

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  DiscountRuleBloc get _bloc => context.read<DiscountRuleBloc>();

  void _updateValidity() => _formKey.updateValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

  void _onSubmit() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Attribute
    if (_isFormValid && (_serverRule?.isNotEmpty ?? false)) {
      _updatedDiscountRule();
      return;
    }

    // Case 2: Form validation or empty Discount rule
    if (!_isFormValid && _discountRules.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Create new Discount Rule
    _newDiscountRule();
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    if (!_isServerNull) ..._serverRule!.history,
    AuditLog(action: action, actionBy: _employeeName),
  ];

  void _newDiscountRule() {
    final newRules = _discountRules
        .map((e) => e.copyWith(history: history()))
        .toList();

    _bloc.add(AddSetup<List<DiscountRule>>(data: newRules));
  }

  void _updatedDiscountRule() {
    final updated = _discountRules.first.copyWith(
      id: _serverRule!.id,
      history: history(AuditAction.updated),
    );
    _bloc.add(UpdateSetup<DiscountRule>(documentId: updated.id, data: updated));
  }

  void _populateDiscountRuleForm() {
    if (!_isServerNull) {
      _discountRules
        ..clear()
        ..add(_serverRule!);
    }
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _isFormValid = false;
        _discountRules.clear();
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

  void _handleBlocState(BuildContext cxt, SetupState<DiscountRule> state) {
    final note = _isServerNull ? 'Discount rule created' : 'Changes saved';
    switch (state) {
      case SetupAdded<DiscountRule>(message: var msg):
      case SetupUpdated<DiscountRule>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<DiscountRule>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _populateDiscountRuleForm();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiscountRuleBloc, SetupState<DiscountRule>>(
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
          title: 'Discount Rule',
          helperText: '\nTap the + button to add multiple Rules',
          children: [
            DynamicTextFields(
              showButton: true,
              fieldsConfig: DiscountFormInputs(
                discountType: _selectedDiscountType,
              ).discountRuleFields,
              initialData: [?_serverRule?.toMap(true)],
              onChanged: (List<Map<String, dynamic>> data) {
                _discountRules
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map(DiscountRule.fromMap));
                setState(
                  () => _selectedDiscountType =
                      _discountRules.firstOrNull?.discountType,
                );

                _updateValidity();
              },
            ),
          ],
        ),

        context.confirmableActionButton(
          isDisabled: _isSubmitting || !_isFormValid,
          label: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Create Discount Rule')
              : (_isSubmitting ? 'Updating...' : null),
          onPressed: _onSubmit,
        ),
      ],
    );
  }
}
