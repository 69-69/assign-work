import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/constants/sales_channel.dart';
import 'package:assign_erp/core/constants/tax_mode.dart';
import 'package:assign_erp/core/constants/workflow_status.dart';
import 'package:assign_erp/core/network/data_sources/models/address_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/doc_type_enum.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/sales_distribution/data/model/sales_quotation_model.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_distribution_bloc.dart';
import 'package:assign_erp/features/sales_distribution/presentation/bloc/sales_quotation/sales_quotation_bloc.dart';
import 'package:assign_erp/features/sales_distribution/presentation/screen/sales_quotation/widget/sq_form_inputs.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_taxes/widget/search_taxes.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateSalesQuotationForm on BuildContext {
  Future openUpdateSalesQuote({required SalesQuotation serverQuote}) async {
    if (serverQuote.id.isEmpty) return;
    prettyPrint('serverQuote', serverQuote.taxMode);

    return await openBottomSheet(
      isExpand: false,
      child: BottomSheetScaffold(
        title: 'Edit Sales Quote',
        subtitle: 'Quote No: ${serverQuote.quoteNumber}',
        body: _UpdateSalesQuote(serverQuote: serverQuote),
      ),
    );
  }
}

class _UpdateSalesQuote extends StatefulWidget {
  final SalesQuotation serverQuote;

  const _UpdateSalesQuote({required this.serverQuote});

  @override
  State<_UpdateSalesQuote> createState() => _UpdateSalesQuoteState();
}

class _UpdateSalesQuoteState extends State<_UpdateSalesQuote> {
  final _formKey = GlobalKey<FormState>();

  SalesQuotation get _serverQuote => widget.serverQuote;

  String get _lineItemType => _serverQuote.lineItems.first.getTypeLabel;

  // Basic fields
  String? _sqStatus;
  String? _salesRepId;
  String? _customerId;
  String? _customerName;
  String? _salesChannelId;
  bool _isSubmitting = false;
  bool? _autoConvertSO; // If approved, auto-convert SQ to SO

  final List<String> _taxCodes = [];
  final List<LineItem> _lineItems = [];
  final List<AddressInfo> _addresses = [];
  final Map<String, dynamic> _validityDate = {};
  final Map<String, dynamic> _currencyPricing = {};
  final Map<String, dynamic> _termsConditions = {};

  /// [_taxModeToApply] Tax method to apply either per line[PerLineTax] or per order[HeaderTax].
  TaxMode? _taxModeToApply;
  late SalesQuotation _finalizedQuote;

  bool get isFormValid => _formKey.currentState!.validate();

  /// Current employee info
  Employee? get _employee => context.employee;

  String get _employeeId => _employee!.employeeId;

  SalesQuotationBloc get _bloc => context.read<SalesQuotationBloc>();

  AuditAction get _action =>
      _serverQuote.isApproved ? AuditAction.approved : AuditAction.updated;

  /// Construct Sales Quote object
  SalesQuotation get _updateQuote {
    final status = _sqStatus ?? _serverQuote.getSQStatus;

    return _serverQuote.copyWith(
      autoConvertSq: _autoConvertSO,
      status: WorkflowStatusHelper.fromString(status),

      salesRepId: _salesRepId ?? _serverQuote.salesRepId,
      customerId: _customerId ?? _serverQuote.customerId,
      customerName: _customerName ?? _serverQuote.customerName,
      addresses: List.from(_addresses),
      salesChannel: SalesChannelHelper.fromString(
        _salesChannelId ?? _serverQuote.getSalesChannel,
      ),

      currencyCode: _currencyPricing['currencyCode'],
      exchangeRate: double.tryParse(_currencyPricing['exchangeRate']) ?? 0.0,
      shippingAmount:
          double.tryParse(_currencyPricing['shippingAmount']) ?? 0.0,

      lineItems: List.from(_lineItems),
      taxMode: _taxModeToApply ?? TaxMode.headerTax,

      notes: _termsConditions['notes'],
      paymentTerms: _termsConditions['paymentTerms'],
      warrantyTerms: _termsConditions['warrantyTerms'],
      returnPolicy: _termsConditions['returnPolicy'],

      validFrom: toDateTimeFn(_validityDate['validFrom']),
      validUntil: toDateTimeFn(_validityDate['validUntil']),
      expectedDate: toDateTimeFn(_validityDate['expectedDate']),
      createdBy: _employee!.fullName,
      history: [
        ..._serverQuote.history, // Keep existing history
        AuditLog(
          action: _action,
          actionBy: _employeeId,
          statusAfterAction: status,
        ),
      ],
    );
  }

  void _onSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      if (!isFormValid || _updateQuote.isEmpty) {
        context.showAlertOverlay(
          'Please enter all required fields',
          bgColor: kDangerColor,
        );
        return;
      }

      _finalizedQuote = _sanitizeTaxCodes(_updateQuote);

      _bloc.add(
        UpdateSalesDistribution<SalesQuotation>(
          documentId: _finalizedQuote.id,
          data: _finalizedQuote,
        ),
      );

      context.showAlertOverlay('Changes successfully saved');

      await _confirmPrintoutDialog();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Ensures tax codes are correctly applied to Sale Quote line items
  /// based on the selected tax mode [_sanitizeTaxCodes].
  ///
  /// - For Header Tax:
  ///   Tax codes are selected once at the header level but must be
  ///   propagated to every line item before sending data to the server.
  ///   This guarantees backend consistency and correct tax calculation.
  ///
  /// - For Per-Line Tax:
  ///   Line items already carry their own tax codes, so no modification
  ///   is required.
  SalesQuotation _sanitizeTaxCodes(SalesQuotation quote) {
    // If Header Tax is selected, apply the same tax codes
    // to all line items to ensure backend compatibility.
    if (quote.taxMode.isHeaderTax) {
      // Apply tax codes to each line item in the quote object
      final updatedItems = quote.lineItems
          .map((e) => e.copyWith(taxCodes: _taxCodes))
          .toList();
      // Return a new RFQ object with updated line items
      return quote.copyWith(lineItems: updatedItems);
    }
    // For Per-Line Tax mode, return the RFQ unchanged since
    // tax codes are managed individually per line item.
    return quote;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _buildBody(),
    );
  }

  Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FormGroupCard(
          title: '1. Quotation Overview',
          children: [_buildAutoCreateAndStatus()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '2. Customer & Sales',
          children: [_buildSalesChannel(), _buildSalesRepAndCustomer()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '3. Currency & Pricing',
          children: [
            _buildCurrencyPricing(),
            HorizontalDivider(space: 0.4),
            _buildTaxModeSelector(),
          ],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '4. ${_lineItemType.toSentence} Line Items',
          subTitle: '\nYou can add more ${_lineItemType}s to the Quotation.',
          children: [_buildLineItems()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '5. Dates & Validity',
          children: [_buildDateValidity()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '6. Addresses',
          subTitle: '\nCustomer shipping & billing address.',
          children: [_buildAddresses()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '7. Terms & Conditions',
          subTitle: '\nPayment & warranty terms for the Quotation.',
          children: [_buildTermsConditions()],
        ),

        FormGroupCard(
          showCollapseButton: false,
          title: 'Financial Summary',
          subTitle: '\nOverview of the Quotation’s Financial Details',
          contentPadding: const EdgeInsets.fromLTRB(10, 20, 22, 20),
          children: [
            HorizontalDivider(space: 0.4),
            _buildText('SubTotal:', _serverQuote.subTotalAmount),
            _buildText('Discount:', _serverQuote.discountAmount),
            _buildText('Tax:', _serverQuote.taxAmount),
            _buildText('Net Total:', _serverQuote.netTotalAmount),
            _buildText('Grand Total:', _serverQuote.totalAmount),
          ],
        ),

        const SizedBox(height: 20.0),
        context.confirmableActionButton(
          label: 'Create Quote',
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  // -------------------------
  // Section Builders
  // -------------------------
  Widget _buildText(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: kTextColor,
          ),
        ),
        Text(
          '${getCurrencySign(_serverQuote.currencyCode)}${amount.toCurrency}',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.normal,
            color: context.onSurfaceColor,
          ),
          textAlign: TextAlign.end, // Right-align the value
        ),
      ],
    );
  }

  AutoCreateAndSQStatus _buildAutoCreateAndStatus() {
    return AutoCreateAndSQStatus(
      initialStatus: _serverQuote.getSQStatus,
      onStatusChanged: (s) => setState(() => _sqStatus = s),
      isSelected: _autoConvertSO ?? _serverQuote.autoConvertSq,
      onAutoConvertChanged: (bool? v) {
        setState(() => _autoConvertSO = v ?? false);
      },
    );
  }

  SalesChannelChoice _buildSalesChannel() {
    return SalesChannelChoice(
      initialChannel: _serverQuote.getSalesChannel,
      onChannelChange: (s) => setState(() => _salesChannelId = s),
    );
  }

  SalesRepAndCustomer _buildSalesRepAndCustomer() {
    return SalesRepAndCustomer(
      initialSalesRep: _serverQuote.salesRepId,
      initialCustomer: _serverQuote.customerName,
      onSalesRepChanged: (id, code, name) => setState(() => _salesRepId = name),
      onCustomerChange: (id, name) => setState(() {
        _customerId = id;
        _customerName = name;
      }),
    );
  }

  Widget _buildTaxModeSelector() {
    // Header-level taxes are preselected here,
    // but per-line taxes are handled in 'lineItems'
    List<String> initialVals = _serverQuote.taxMode.isHeaderTax
        ? List.from(_serverQuote.lineItems.first.taxCodes)
        : [];

    return TaxModeSelector(
      initialValues: initialVals,
      onRadioChanged: _onSelectTaxMode,
      defaultTaxMode: _taxModeToApply ?? _serverQuote.taxMode,
      onCheckChanged: (List<Map<String, dynamic>> data) {
        // if (isFormValid) setState(() {});

        List<String> taxCodes = data
            .where((e) => e['selected'] == true)
            .map((m) => Tax.fromMap(m['data']).code)
            .toList();

        _taxCodes
          ..clear() // Clear previous entries to prevent duplication
          ..addAll(taxCodes);
      },
    );
  }

  DynamicTextFields _buildLineItems() {
    return DynamicTextFields(
      showButton: true,
      fieldsConfig: SQFormInputs.fields(
        _lineItemType,
        isHidden: _taxModeToApply != TaxMode.perLineTax,
        keysToExclude: ['limitAmount', 'limitQuantity'],
      ),
      initialData: _serverQuote.lineItems.map((e) => e.toMap(true)).toList(),
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        // Update the LineItem list
        SQFormInputs.updateListFromData<LineItem>(
          _lineItems,
          map: data,
          fromMap: (map, id) => LineItem.fromMap(map),
        );
      },
    );
  }

  DynamicTextFields _buildCurrencyPricing() {
    return DynamicTextFields(
      initialData: [
        {
          'currencyCode': _serverQuote.currencyCode,
          'exchangeRate': _serverQuote.exchangeRate,
          'shippingAmount': _serverQuote.shippingAmount,
        },
      ],
      fullWidthKey: 'currencyPricing',
      fieldsConfig: SQFormInputs.currencyPricingFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _currencyPricing
          ..clear()
          ..addAll(data.first);
      },
    );
  }

  DynamicTextFields _buildDateValidity() {
    return DynamicTextFields(
      initialData: [
        {
          'validFrom': _serverQuote.getValidFromDate,
          'validUntil': _serverQuote.getValidToDate,
          'expectedDate': _serverQuote.getExpectedDate,
        },
      ],
      fieldsConfig: SQFormInputs.validityDateFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _validityDate
          ..clear()
          ..addAll(data.first);
      },
    );
  }

  // Addresses (e.g., Buyer Shipping & Billing Address)
  DynamicTextFields _buildAddresses() {
    return DynamicTextFields(
      showButton: true,
      fieldGroupsLimit: 2,
      initialData: _serverQuote.addresses.map((e) => e.toMap()).toList(),
      fieldsConfig: SQFormInputs.addressesFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        // Update the address list
        SQFormInputs.updateListFromData<AddressInfo>(
          _addresses,
          map: data,
          fromMap: (map, id) => AddressInfo.fromMap(map),
        );
      },
    );
  }

  DynamicTextFields _buildTermsConditions() {
    return DynamicTextFields(
      initialData: [
        {
          'notes': _serverQuote.notes,
          'paymentTerms': _serverQuote.paymentTerms,
          'warrantyTerms': _serverQuote.warrantyTerms,
          'returnPolicy': _serverQuote.returnPolicy,
        },
      ],
      fullWidthKey: 'supplierTerms',
      fieldsConfig: SQFormInputs.supplierTermsFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _termsConditions
          ..clear()
          ..addAll(data.first);
      },
    );
  }

  // -------------------------
  // Tax, Print & History Logic
  // -------------------------
  void _onSelectTaxMode(List<Map<String, dynamic>> data) {
    final selected = data.firstWhereOrNull((item) => item['selected'] == true);
    final selectedKey = selected?['key'];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _taxModeToApply = TaxModeHelper.fromString(selectedKey));
    });
  }

  Future<void> _confirmPrintoutDialog() async {
    final isConfirmed = await context.confirmAction<bool>(
      const Text('Would you like to print the request for quotation: RFQ?'),
      title: "Print RFQ",
      onAcceptLabel: "Print",
      onRejectLabel: "Cancel",
    );

    if (mounted && isConfirmed) {
      // Show progress dialog while loading data
      await context.progressBarDialog(
        request: _printout(),
        onSuccess: (_) => context.showAlertOverlay('RFQ successfully created'),
        onError: (e) => context.showAlertOverlay(
          'RFQ printout failed',
          bgColor: kDangerColor,
        ),
      );
    }
  }

  Future<dynamic> _printout() => Future.delayed(kRProgressDelay, () async {
    if (_finalizedQuote.isEmpty) return;

    final quoteWithTaxes = await SQFormInputs.applyTaxesToQuote(
      _finalizedQuote,
    );
    final supplier = await SQFormInputs.getCustomer(_finalizedQuote.customerId);
    if (supplier.isEmpty) return;

    // Log that details were printed
    if (mounted &&
        AuditTracker.shouldLog(
          id: '${_finalizedQuote.id}::$_employeeId',
          type: DocType.rfq,
          action: AuditAction.printed,
        )) {
      _updateHistory();
    }
    // await SQPrinter(quote: quoteWithTaxes, customer: customer).printRFQ();
  });

  /// Audit Log Entry (Tracking actions)
  void _updateHistory([AuditAction action = AuditAction.printed]) {
    final up = SQFormInputs.updateHistory(
      action: action,
      quote: _finalizedQuote,
      empId: _employeeId,
    );
    _bloc.add(up);
  }
}
