import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/form_validity.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/taxes/tax_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/tax_master/widget/tax_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateTaxes<T> on BuildContext {
  Future<void> openAddTax({Tax? serverTax}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: serverTax?.name.toTitle ?? 'New Tax',
      body: _AddTaxForm(serverTax: serverTax),
    ),
  );
}

class _AddTaxForm extends StatefulWidget {
  final Tax? serverTax;

  const _AddTaxForm({this.serverTax});

  @override
  State<_AddTaxForm> createState() => _AddTaxFormState();
}

class _AddTaxFormState extends State<_AddTaxForm> {
  bool _isSubmitting = false;
  final List<Tax> _taxList = [];
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => _serverTax.hasValue;

  TaxBloc get _bloc => context.read<TaxBloc>();

  Tax? get _serverTax => widget.serverTax;

  bool get _isServerNull => _serverTax == null;

  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  String get _employeeId => _employee!.employeeId;
  bool _isFormValid = false;

  void _updateValidity() => _formKey.updateValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

  void _onSubmit() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Tax
    if (_isFormValid && (_serverTax?.isNotEmpty ?? false)) {
      _updatedTax();
      return;
    }

    // Case 2: Form validation or empty Tax
    if (!_isFormValid && _taxList.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Add new Taxes
    _createNewTaxes();
  }

  // load existing Taxes
  void _loadExistingTaxes() {
    if (_isEditing) {
      _taxList
        ..clear()
        ..add(_serverTax!);
    }
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    if (!_isServerNull) ..._serverTax!.history,
    AuditLog(action: action, actionBy: _employeeId),
  ];

  void _createNewTaxes() {
    // Append tax-code & createdBy to each tax
    final newTaxes = _taxList
        .map(
          (e) => e.copyWith(
            code: e.name.generateTaxCode(e.rate),
            createdBy: _employeeName,
            history: history(),
          ),
        )
        .toList();

    _bloc.add(AddSetup<List<Tax>>(data: newTaxes));
  }

  void _updatedTax() {
    final tax = _taxList.first;

    final updatedTax = _serverTax!.copyWith(
      id: _serverTax!.id,
      name: tax.name,
      rate: tax.rate,
      notes: tax.notes,
      autoApplyOn: tax.autoApplyOn,
      isAutoApply: tax.isAutoApply,
      isShippingTaxed: tax.isShippingTaxed,
      isWithholding: tax.isWithholding,
      updatedBy: _employeeName,
      history: history(AuditAction.updated),
    );

    _bloc.add(UpdateSetup<Tax>(documentId: updatedTax.id, data: updatedTax));
  }

  void _resetForm() {
    _taxList.clear();
    _formKey.currentState!.reset();
    _formResetKey = UniqueKey();
    setState(() => _isSubmitting = false);
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(
      msg,
      onCallback: () => _isServerNull ? _resetForm() : Navigator.pop(context),
    );
  }

  void _handleBlocState(BuildContext cxt, SetupState<Tax> state) {
    final note = _isServerNull ? 'Taxes created' : 'Changes saved';
    switch (state) {
      case SetupAdded<Tax>(message: var msg):
      case SetupUpdated<Tax>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<Tax>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExistingTaxes();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaxBloc, SetupState<Tax>>(
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
          title: 'Tax Rates',
          subTitle: '\n Add Tax Rates & Notes',
          children: [
            DynamicTextFields(
              showButton: !_isEditing,
              initialData: [?_serverTax?.toMap()],
              fieldsConfig: TaxFormInputs.taxRatesFields(_serverTax?.toMap()),
              onChanged: (List<Map<String, dynamic>> data) {
                if (data.isEmpty) return;

                TaxFormInputs.updateListFromData<Tax>(
                  _taxList,
                  map: data,
                  fromMap: (map, id) => Tax.fromMap(map),
                );

                _updateValidity();
              },
            ),
          ],
        ),

        const SizedBox(height: 10.0),
        context.confirmableActionButton(
          onPressed: _onSubmit,
          isDisabled: _isSubmitting || !_isFormValid,
          label: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Create Taxes')
              : (_isSubmitting ? 'Updating...' : null),
        ),
      ],
    );
  }
}
