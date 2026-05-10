import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
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
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/price_list_entry_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/price_list_master/widget/price_master_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreatePriceListEntry<T> on BuildContext {
  Future<void> openAddPriceEntry({
    PriceListEntry? serverPriceEntry,
    String? variantSku,
  }) => openBottomSheet(
    isExpand: false,
    showZoomIcon: false,
    barrierColor: kTransparentColor,
    child: BottomSheetScaffold(
      isShadow: true,
      title: 'Price Entry',
      body: _AddPriceEntryForm(
        serverPriceEntry: serverPriceEntry,
        variantSku: variantSku,
      ),
    ),
  );
}

class _AddPriceEntryForm extends StatefulWidget {
  final String? variantSku;
  final PriceListEntry? serverPriceEntry;

  const _AddPriceEntryForm({this.serverPriceEntry, this.variantSku});

  @override
  State<_AddPriceEntryForm> createState() => _AddPriceEntryFormState();
}

class _AddPriceEntryFormState extends State<_AddPriceEntryForm> {
  bool _isSubmitting = false;
  final List<PriceListEntry> _entries = [];
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();
  bool _isFormValid = false; // _formKey.currentState?.validate() ??

  PriceListEntry? get _serverPriceEntry => widget.serverPriceEntry;

  bool get _isServerNull => _serverPriceEntry == null;

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  String? get _variantSku => widget.variantSku ?? _serverPriceEntry?.variantSku;

  PriceListEntryBloc get _bloc => context.read<PriceListEntryBloc>();

  void _updateValidity() => _formKey.updateValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

  void _onSubmit() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Case 1: Update existing Attribute
    if (_isFormValid && (_serverPriceEntry?.isNotEmpty ?? false)) {
      _updatedPriceEntry();
      return;
    }

    // Case 2: Form validation or empty entries
    if (!_isFormValid && _entries.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Create new entries
    _newPriceEntries();
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    if (!_isServerNull) ..._serverPriceEntry!.history,
    AuditLog(action: action, actionBy: _employeeName),
  ];

  void _newPriceEntries() {
    final newPrices = _entries
        .map((e) => e.copyWith(variantSku: _variantSku, history: history()))
        .toList();
    prettyPrint('label-newPrices', newPrices);

    // _bloc.add(AddSetup<List<PriceListEntry>>(data: newPrices));
  }

  void _updatedPriceEntry() {
    final updated = _entries.first.copyWith(
      id: _serverPriceEntry?.id,
      variantSku: _serverPriceEntry?.variantSku,
      sellingPrice: _serverPriceEntry?.sellingPrice,
      minQuantity: _serverPriceEntry?.minQuantity,
      discountPercent: _serverPriceEntry?.discountPercent,
      history: history(AuditAction.updated),
    );
    _bloc.add(
      UpdateSetup<PriceListEntry>(documentId: updated.id, data: updated),
    );
  }

  // load existing Price entries
  void _loadExistingPrices() {
    if (_serverPriceEntry != null) {
      _entries
        ..clear()
        ..add(_serverPriceEntry!);
    }
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _isFormValid = false;
        _entries.clear();
      });

      if (_isServerNull) Navigator.pop(context);
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => _resetForm());
    setState(() => _isSubmitting = false);
  }

  void _handleBlocState(BuildContext cxt, SetupState<PriceListEntry> state) {
    final note = _isServerNull ? 'Price List created' : 'Changes saved';
    switch (state) {
      case SetupAdded<PriceListEntry>(message: var msg):
      case SetupUpdated<PriceListEntry>(message: var msg):
        _showAlert(msg ?? note);
      case SetupError<PriceListEntry>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExistingPrices();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PriceListEntryBloc, SetupState<PriceListEntry>>(
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
          title: 'Selling Price',
          subTitle:
              '\nSet prices, quantity tiers, and discounts for variant (SKU: $_variantSku)',
          showCollapseButton: false,
          children: [
            DynamicTextFields(
              fieldsConfig: PriceMasterFormInputs.priceEntryFields,
              initialData: [?_serverPriceEntry?.toMap()],
              onChanged: (List<Map<String, dynamic>> data) {
                _entries
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map((e) => PriceListEntry.fromMap(e)));

                prettyPrint('label-data', _entries);

                _updateValidity();
              },
            ),
          ],
        ),

        if (!_variantSku!.startsWith('demo'))
          context.confirmableActionButton(
            isDisabled: _isSubmitting || !_isFormValid,
            label: _isServerNull
                ? (_isSubmitting ? 'Setting...' : 'Set Price')
                : (_isSubmitting ? 'Updating...' : null),
            onPressed: _onSubmit,
          ),
      ],
    );
  }
}
