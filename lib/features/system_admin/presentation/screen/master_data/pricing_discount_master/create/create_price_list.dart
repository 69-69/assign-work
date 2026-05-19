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
import 'package:assign_erp/features/system_admin/data/models/master_data/price_list_master_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/price_list_master_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/pricing_discount_master/widget/pricing_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreatePriceMaster<T> on BuildContext {
  Future<void> openAddPriceList({PriceListMaster? serverPriceList}) =>
      openBottomSheet(
        isExpand: false,
        child: BottomSheetScaffold(
          title: serverPriceList != null
              ? 'Edit ${serverPriceList.type}'.toTitle
              : 'New Price List',
          body: _AddPriceListForm(serverPriceList: serverPriceList),
        ),
      );
}

class _AddPriceListForm extends StatefulWidget {
  final PriceListMaster? serverPriceList;

  const _AddPriceListForm({this.serverPriceList});

  @override
  State<_AddPriceListForm> createState() => _AddPriceListFormState();
}

class _AddPriceListFormState extends State<_AddPriceListForm> {
  bool _isSubmitting = false;
  final List<PriceListMaster> _priceLists = [];
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();
  bool _isFormValid = false; // _formKey.currentState?.validate() ??

  PriceListMaster? get _serverPriceList => widget.serverPriceList;

  bool get _isServerNull => _serverPriceList == null;

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  String get _employeeStore => _employee!.storeNumber;

  PriceListMasterBloc get _bloc => context.read<PriceListMasterBloc>();

  void _updateValidity() => _formKey.updateValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

  void _onSubmit() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Attribute
    if (_isFormValid && (_serverPriceList?.isNotEmpty ?? false)) {
      _updatedPriceList();
      return;
    }

    // Case 2: Form validation or empty priceList
    if (!_isFormValid && _priceLists.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Create new Attributes
    _newPriceLists();
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    if (!_isServerNull) ..._serverPriceList!.history,
    AuditLog(action: action, actionBy: _employeeName),
  ];

  void _newPriceLists() {
    final newPrices = _priceLists
        .map((e) => e.copyWith(storeNumber: _employeeStore, history: history()))
        .toList();

    _bloc.add(AddSetup<List<PriceListMaster>>(data: newPrices));
  }

  void _updatedPriceList() {
    final updated = _priceLists.first.copyWith(
      id: _serverPriceList!.id,
      history: history(AuditAction.updated),
    );
    _bloc.add(UpdateSetup<PriceListMaster>(documentId: updated.id, data: updated));
  }

  // load existing PriceMaster
  void _populatePriceForm() {
    if (!_isServerNull) {
      _priceLists
        ..clear()
        ..add(_serverPriceList!);
    }
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _isFormValid = false;
        _priceLists.clear();
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

  void _handleBlocState(BuildContext cxt, SetupState<PriceListMaster> state) {
    final note = _isServerNull ? 'Price List created' : 'Changes saved';
    switch (state) {
      case SetupAdded<PriceListMaster>(message: var msg):
      case SetupUpdated<PriceListMaster>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<PriceListMaster>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _populatePriceForm();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PriceListMasterBloc, SetupState<PriceListMaster>>(
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
          title: 'Price Master',
          helperText: '\nTap the + button to add multiple entries',
          children: [
            DynamicTextFields(
              showButton: true,
              fieldsConfig: PricingFormInputs.priceListFields,
              initialData: [?_serverPriceList?.toMap(true)],
              onChanged: (List<Map<String, dynamic>> data) {
                _priceLists
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map(PriceListMaster.fromMap));

                _updateValidity();
              },
            ),
          ],
        ),

        context.confirmableActionButton(
          isDisabled: _isSubmitting || !_isFormValid,
          label: _isServerNull
              ? (_isSubmitting ? 'Creating...' : 'Create Price List')
              : (_isSubmitting ? 'Updating...' : null),
          onPressed: _onSubmit,
        ),
      ],
    );
  }
}
