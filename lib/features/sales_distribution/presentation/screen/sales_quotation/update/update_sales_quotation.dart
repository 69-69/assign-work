import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/network/data_sources/models/address_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/extensions/sales_channel.dart';
import 'package:assign_erp/core/util/extensions/tax_mode.dart';
import 'package:assign_erp/core/util/extensions/workflow_status.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateSalesQuotationForm on BuildContext {
  Future openUpdateSalesQuote({required SalesQuotation serverQuote}) async {
    if (serverQuote.id.isEmpty) return;

    return await openBottomSheet(
      isExpand: false,
      child: BottomSheetScaffold(
        title: 'Edit Sales Quote',
        subtitle:
            '${serverQuote.quoteNumber.toUpperAll} (${serverQuote.lineItems.first.getType})',
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
  bool get _isFormValid => _formKey.currentState!.validate();

  SalesQuotation get _serverQuote => widget.serverQuote;
  String get _lineItemType => _serverQuote.lineItems.first.getType;

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

  /// Current employee info
  Employee? get _employee => context.employee;
  String get _employeeId => _employee!.employeeId;

  SalesQuotationBloc get _bloc => context.read<SalesQuotationBloc>();

  AuditAction get _action =>
      _serverQuote.isApproved ? AuditAction.approved : AuditAction.updated;

  /// Construct Sales Quote object
  SalesQuotation get _updateQuote {
    final status = _sqStatus ?? _serverQuote.getSQStatus;
    prettyPrint('_taxMode-ToApply', _taxModeToApply);

    return _serverQuote.copyWith(
      autoConvertSq: _autoConvertSO,
      status: WorkflowStatusUtil.fromString(status),

      salesRepId: _salesRepId ?? _serverQuote.salesRepId,
      customerId: _customerId ?? _serverQuote.customerId,
      customerName: _customerName ?? _serverQuote.customerName,
      addresses: List.from(_addresses),
      salesChannel: SalesChannelUtil.fromString(
        _salesChannelId ?? _serverQuote.getSalesChannel,
      ),

      currencyCode: _currencyPricing['currencyCode'],
      exchangeRate: '${_currencyPricing['exchangeRate']}'.asDouble,
      shippingAmount: '${_currencyPricing['shippingAmount']}'.asDouble,

      lineItems: List.from(_lineItems),
      taxMode: _taxModeToApply ?? TaxMode.perLineTax,

      notes: _termsConditions['notes'],
      paymentTerms: _termsConditions['paymentTerms'],
      warrantyTerms: _termsConditions['warrantyTerms'],
      returnPolicy: _termsConditions['returnPolicy'],

      validFrom: toDateTimeFn(_validityDate['validFrom']),
      validUntil: toDateTimeFn(_validityDate['validUntil']),
      expectedDate: toDateTimeFn(_validityDate['expectedDate']),
      updatedBy: _employee!.fullName,
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
      if (!_isFormValid || _updateQuote.isEmpty) {
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

      // context.showAlertOverlay('Changes successfully saved');
      // await _confirmPrintoutDialog();
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
    _taxModeToApply = _serverQuote.taxMode;
    _autoConvertSO = _serverQuote.autoConvertSq;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalesQuotationBloc, SalesDistributionState>(
      listener: (context, state) async {
        if (state is SalesDistributionUpdated<SalesQuotation>) {
          context.showAlertOverlay(
            state.message ?? 'Changes successfully saved',
          );
          await _confirmPrintoutDialog();
        }

        if (state is SalesDistributionError<SalesQuotation>) {
          if (context.mounted) {
            context.showAlertOverlay('Error saving changes');
          }
        }
      },
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: _buildBody(),
      ),
    );

    /*return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _buildBody(),
    );*/
  }

  Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FormGroupCard(
          title: '1. Quotation Overview',
          subTitle: '\nGeneral quotation info & document status.',
          children: [_buildAutoCreateAndStatus()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '2. Customer & Sales',
          subTitle:
              '\nCustomer details, sales channel, & sales representative.',
          children: [_buildSalesChannel(), _buildSalesRepAndCustomer()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '3. Pricing & Tax Determination',
          subTitle: '\nCurrency, pricing conditions, & tax preferences.',
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
          subTitle: '\nQuotation date, validity period, & delivery timeline.',
          children: [_buildDateValidity()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '6. Addresses',
          subTitle: '\nCustomer Bill-to, Ship-to, & other address details.',
          children: [_buildAddresses()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '7. Terms & Conditions',
          subTitle: '\nPayment terms, warranty, & commercial conditions.',
          children: [_buildTermsConditions()],
        ),

        FormGroupCard(
          showCollapseButton: false,
          title: 'Financial Summary',
          subTitle: '\nOverview of the Quotation’s Financial Details',
          contentPadding: const EdgeInsets.fromLTRB(10, 20, 22, 20),
          children: [
            HorizontalDivider(space: 0.4),
            ...[
              ('SubTotal:', _serverQuote.subTotal),
              ('Discount:', _serverQuote.totalDiscountAmount),
              ('Tax Amount:', _serverQuote.totalTaxAmount),
              ('Net Total:', _serverQuote.netTotal),
              if (_serverQuote.shippingTaxAmount > 0) ...[
                ('Shipping:', _serverQuote.shippingAmount),
                ('Shipping Tax:', _serverQuote.shippingTaxAmount),
              ],
              ('Grand Total:', _serverQuote.grandTotal),
            ].map((e) => _buildTextSummary(e.$1, e.$2)),
          ],
        ),

        const SizedBox(height: 20.0),
        context.confirmableActionButton(onPressed: _onSubmit),
        const SizedBox(height: 20.0),
      ],
    );
  }

  // -------------------------
  // Section Builders
  // -------------------------

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
    return SQFormInputs.buildTaxModeSelector(
      initialValues: List.from(_serverQuote.lineItems.first.taxCodes),
      selectedTaxCodes: _taxCodes,
      defaultTaxMode: _taxModeToApply,
      selectedTaxMode: (TaxMode? mode) =>
          setState(() => _taxModeToApply = mode),
    );
  }

  DynamicTextFields _buildLineItems() {
    return DynamicTextFields(
      showButton: true,
      fieldsConfig: SQFormInputs.fields(
        _lineItemType,
        isHidden: _taxModeToApply != TaxMode.perLineTax,
      ),
      initialData: _serverQuote.lineItems.map((e) => e.toMap(true)).toList(),
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

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
        if (_isFormValid) setState(() {});

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
          'validUntil': _serverQuote.getValidUntilDate,
          'expectedDate': _serverQuote.getExpectedDate,
        },
      ],
      fieldsConfig: SQFormInputs.validityDateFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

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
        if (_isFormValid) setState(() {});

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
        if (_isFormValid) setState(() {});

        _termsConditions
          ..clear()
          ..addAll(data.first);
      },
    );
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
    prettyPrint('quote-With-Taxes', quoteWithTaxes);

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

  Widget _buildTextSummary(String label, double amount) {
    if (amount.isNaN || amount == 0.0) {
      amount = 0.0; // Set a default value if the amount is invalid
    }
    final sign = getCurrencySign(_serverQuote.currencyCode);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: label.filterAny('grand') ? kDangerColor : kTextColor,
          ),
        ),
        Text(
          '$sign${amount.toCurrency}',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.normal,
            color: context.onSurfaceColor,
          ),
          textAlign: TextAlign.end, // Right-align the value
        ),
      ],
    );
  }
}
