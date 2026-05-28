import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/extensions/form_validity.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/price_list_master_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/price_list_entry_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/pricing_discount_master/widget/pricing_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';

extension CreatePriceListEntry<T> on BuildContext {
  Future<void> openAddPriceEntry({
    PriceListEntry? serverPriceEntry,
    List<String>? variantSKUs,
    bool isChangePrice = false,
    void Function({required Map<String, double> prices})? onPriceCreated,
  }) {
    final isDemo =
        variantSKUs?.firstOrNull?.toLowerAll.startsWith('demo-') ?? false;
    return openBottomSheet(
      isExpand: false,
      showZoomIcon: false,
      barrierColor: kTransparentColor,
      child: BottomSheetScaffold(
        isShadow: true,
        title: 'Selling Price Entry',
        subtitle: isDemo ? '(Demo Mode)' : null,
        body: _AddPriceEntryForm(
          serverPriceEntry: serverPriceEntry,
          onPriceCreated: onPriceCreated,
          isChangePrice: isChangePrice,
          variantSKUs: variantSKUs,
          isDemo: isDemo,
        ),
      ),
    );
  }
}

class _AddPriceEntryForm extends StatefulWidget {
  final bool isDemo;
  final bool isChangePrice;
  final List<String>? variantSKUs;
  final PriceListEntry? serverPriceEntry;
  final void Function({required Map<String, double> prices})? onPriceCreated;

  const _AddPriceEntryForm({
    this.serverPriceEntry,
    this.variantSKUs,
    this.onPriceCreated,
    this.isDemo = false,
    this.isChangePrice = false,
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

  bool _isLoadingEntry = false;

  bool get _isDemo => widget.isDemo;
  PriceListEntry? _serverPriceEntry;

  bool get _isServerNull => _serverPriceEntry == null;

  // Current employee info
  Employee? get _employee => context.employee;

  String get _employeeName => _employee!.fullName;

  String _missing = '';

  List<String>? get _variantSKUs => widget.variantSKUs;

  int get _totalSKUs => _variantSKUs?.length ?? 0;

  bool get _isDisabled => _missing.isNotEmpty || _isSubmitting || !_isFormValid;

  PriceListEntryBloc get _bloc => context.read<PriceListEntryBloc>();

  void _syncValidity() => _formKey.syncValidity(
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

  void _buildPriceMap({String? msg}) {
    final note = _isServerNull ? 'Price entry created' : 'Changes saved';

    final pricesMap = {
      for (var e in _priceEntries) e.variantSku: e.sellingPrice,
    };
    widget.onPriceCreated?.call(prices: pricesMap);
    _showAlert(msg ?? note);
    return;
  }

  void _createNewPrices() {
    _priceEntries = _priceEntries.mapIndexed((i, price) {
      return price.copyWith(
        variantSku: _variantSKUs?.elementAtOrNull(i),
        history: history(),
      );
    }).toList();

    // For demo: Exploring Variants Playground
    if (_isDemo) {
      _buildPriceMap();
    }

    _bloc.add(AddSetup<List<PriceListEntry>>(data: _priceEntries));
  }

  void _updatedPriceEntry() {
    final updated = _priceEntries.first.copyWith(
      id: _serverPriceEntry?.id,
      variantSku: _variantSKUs?.first,
      history: history(AuditAction.updated),
    );
    _priceEntries = [updated];

    _bloc.add(
      UpdateSetup<PriceListEntry>(documentId: updated.id, data: updated),
    );
  }

  void _populatePriceForm() {
    if (!_isServerNull || widget.isChangePrice) {
      _priceEntries
        ..clear()
        ..add(_serverPriceEntry!);
    }
  }

  void _fetchServerPriceEntry() {
    _isLoadingEntry = true;

    _bloc.add(
      GetSetupById<PriceListEntry>(
        documentId: _variantSKUs!.first,
        field: 'variantSku',
      ),
    );
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
    switch (state) {
      case SetupLoaded<PriceListEntry>(data: final entry):
        setState(() {
          _serverPriceEntry = entry;
          _isLoadingEntry = false;
        });
        _populatePriceForm();
      case SetupAdded<PriceListEntry>(message: var msg):
      case SetupUpdated<PriceListEntry>(message: var msg):
        _buildPriceMap(msg: msg);
      case SetupError<PriceListEntry>():
        final msg = _isDemo
            ? 'Changes cannot be saved in demo mode'
            : 'Unable to save changes. Please try again.';
        _showAlert(msg);
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();

    _serverPriceEntry = widget.serverPriceEntry;

    if (widget.isChangePrice && _variantSKUs.hasValue) {
      _fetchServerPriceEntry();
    } else {
      _populatePriceForm();
    }
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
    if (_isLoadingEntry) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [SizedBox(height: 40), context.loader, SizedBox(height: 20)],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 20,
      children: [
        FormGroupCard(
          showCollapseButton: false,
          title: 'Selling Price',
          subTitle:
              '\nSet prices, quantity tiers, and discounts for selected items',
          children: [
            DynamicTextFields(
              title: 'Price',
              isRepeatable: _totalSKUs > 1,
              fieldGroupsLimit: _totalSKUs,
              initialData: [?_serverPriceEntry?.toMap(true)],
              fieldsConfig: PricingFormInputs.priceEntryFields,
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
                /*_priceEntries
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(
                    data.mapIndexed((i, map) {
                      return PriceListEntry.fromMap(map).copyWith(
                        variantSku: _variantSKUs?.elementAtOrNull(i),
                        history: history(),
                      );
                    }),
                  );*/

                _syncValidity();
              },
            ),
          ],
        ),

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
