import 'package:assign_erp/core/constants/app_colors.dart';
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
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/price_list_entry_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/price_list_master/widget/price_master_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreatePriceListEntry<T> on BuildContext {
  Future<void> openAddPriceEntry({
    PriceListEntry? serverPriceEntry,
    List<String>? variantSKUs,
    void Function({required Map<String, double> prices})? onPriceCreated,
  }) => openBottomSheet(
    isExpand: false,
    showZoomIcon: false,
    barrierColor: kTransparentColor,
    child: BottomSheetScaffold(
      isShadow: true,
      title: 'Selling Price Entry',
      body: _AddPriceEntryForm(
        serverPriceEntry: serverPriceEntry,
        onPriceCreated: onPriceCreated,
        variantSKUs: variantSKUs,
      ),
    ),
  );
}

class _AddPriceEntryForm extends StatefulWidget {
  final List<String>? variantSKUs;
  final PriceListEntry? serverPriceEntry;
  final void Function({required Map<String, double> prices})? onPriceCreated;

  const _AddPriceEntryForm({
    this.serverPriceEntry,
    this.variantSKUs,
    this.onPriceCreated,
  });

  @override
  State<_AddPriceEntryForm> createState() => _AddPriceEntryFormState();
}

class _AddPriceEntryFormState extends State<_AddPriceEntryForm> {
  bool _isFormValid = false; // _formKey.currentState?.validate() ??
  bool _isSubmitting = false;
  Key _formResetKey = UniqueKey();
  final _formKey = GlobalKey<FormState>();
  List<PriceListEntry> _priceEntries = [];

  PriceListEntry? get _serverPriceEntry => widget.serverPriceEntry;

  bool get _isServerNull => _serverPriceEntry == null;

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  String _missing = '';

  List<String>? get _variantSKUs => widget.variantSKUs;

  int get _totalSKUs => _variantSKUs?.length ?? 0;

  bool get _isDisabled => _missing.isNotEmpty || _isSubmitting || !_isFormValid;

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
    if (!_isFormValid && _priceEntries.isNullOrEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    // Case 3: Create new entries
    _createNewPrices();
  }

  List<AuditLog> history([action = AuditAction.created]) => [
    ...?_serverPriceEntry?.history,
    AuditLog(action: action, actionBy: _employeeName),
  ];

  void _createNewPrices() {
    _priceEntries = _priceEntries.indexed.map((entry) {
      final (index, price) = entry;

      return price.copyWith(
        variantSku: _variantSKUs?.elementAtOrNull(index),
        history: history(),
      );
    }).toList();

    _bloc.add(AddSetup<List<PriceListEntry>>(data: _priceEntries));
  }

  void _updatedPriceEntry() {
    /*sellingPrice: _serverPriceEntry?.sellingPrice,
      minQuantity: _serverPriceEntry?.minQuantity,
      discountPercent: _serverPriceEntry?.discountPercent,*/
    final updated = _priceEntries.first.copyWith(
      id: _serverPriceEntry?.id,
      variantSku: _serverPriceEntry?.variantSku,
      history: history(AuditAction.updated),
    );

    _bloc.add(
      UpdateSetup<PriceListEntry>(documentId: updated.id, data: updated),
    );
  }

  // load existing Price entry
  void _loadExistingPriceEntry() {
    if (_serverPriceEntry != null) {
      _priceEntries
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
        _priceEntries.clear();
      });

      if (_isServerNull) Navigator.pop(context);
    }
  }

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => _resetForm());
  }

  void _handleBlocState(BuildContext cxt, SetupState<PriceListEntry> state) {
    final note = _isServerNull ? 'Price entry created' : 'Changes saved';

    switch (state) {
      case SetupAdded<PriceListEntry>(message: var msg):
      case SetupUpdated<PriceListEntry>(message: var msg):
        if (state is SetupAdded) {
          /// Upon creating selling price entry, trigger Saving Variants
          final pricesMap = {
            for (var entry in _priceEntries)
              entry.variantSku: entry.sellingPrice,
          };
          widget.onPriceCreated?.call(prices: pricesMap);
        }
        _showAlert(msg ?? note);
      case SetupError<PriceListEntry>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
        setState(() => _isSubmitting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExistingPriceEntry();
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
    final isDemo =
        _variantSKUs?.firstOrNull?.toLowerAll.startsWith('demo-') ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 20,
      children: [
        FormGroupCard(
          title: 'Selling Price',
          subTitle:
              '\nSet prices, quantity tiers, and discounts for selected items',
          showCollapseButton: false,
          children: [
            DynamicTextFields(
              title: 'Price',
              showButton: true,
              fieldGroupsLimit: _totalSKUs,
              initialData: [?_serverPriceEntry?.toMap()],
              fieldsConfig: PriceMasterFormInputs.priceEntryFields,
              orText: _variantSKUs?.map((sku) => 'SKU: $sku').toList(),
              onCount: (int v) {
                final count = _totalSKUs - v;
                final msg = count > 0 ? ' ($count missing prices)' : '';

                setState(() => _missing = msg);
              },
              onChanged: (List<Map<String, dynamic>> data) {
                if (data.isEmpty) return;

                _priceEntries
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map(PriceListEntry.fromMap));

                _updateValidity();
              },
            ),
          ],
        ),

        if (!isDemo)
          context.confirmableActionButton(
            isDisabled: _isDisabled,
            label: _isServerNull
                ? (_isSubmitting ? 'Setting...' : 'Set All Prices$_missing')
                : (_isSubmitting ? 'Updating...' : null),
            onPressed: _onSubmit,
          ),
      ],
    );
  }
}
