import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/address_info_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/form_group_card_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/extensions/form_validity.dart';
import 'package:assign_erp/core/util/extensions/sales_channel.dart';
import 'package:assign_erp/core/util/extensions/tax_mode.dart';
import 'package:assign_erp/core/util/extensions/workflow_status.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/auto_id_field.dart';
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

extension SalesQuoteFormExtensions on BuildContext {
  /// [openCreateSQForm] Opens the Sales Quote Form
  Future<void> openCreateSQForm({
    required String type,
    void Function()? onBackPress,
  }) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      onBackPress: onBackPress,
      title: 'New Sales Quotation',
      body: _CreateSQForm(lineItemType: type),
    ),
  );
}

/// Create Sales Quotation Form [_CreateSQForm]
class _CreateSQForm extends StatefulWidget {
  final String lineItemType;

  const _CreateSQForm({required this.lineItemType});

  @override
  State<_CreateSQForm> createState() => _CreateSQFormState();
}

class _CreateSQFormState extends State<_CreateSQForm> {
  String? get _lineItemType => widget.lineItemType;
  final _formKey = GlobalKey<FormState>();
  Key _formResetKey = UniqueKey();

  // Basic fields
  String? _sqStatus;
  String _quoteNumber = '';
  String _salesRepId = '';
  bool _autoConvertSO = true; // If approved, auto-convert SQ to SO
  bool _isSubmitting = false;
  String? _customerId;
  String _customerName = '';
  String _salesChannelId = '';

  final List<String> _taxCodes = [];
  final List<LineItem> _lineItems = [];
  final List<AddressInfo> _addresses = [];
  final Map<String, dynamic> _validityDate = {};
  final Map<String, dynamic> _currencyPricing = {};
  final Map<String, dynamic> _termsConditions = {};

  /// [_taxModeToApply] Tax method to apply either per line[PerLineTax] or per order[HeaderTax].
  TaxMode? _taxModeToApply;
  late SalesQuotation _finalizedQuote;

  bool _isFormValid = false; // _formKey.currentState!.validate();

  /// Current employee info
  Employee? get _employee => context.employee;

  String get _employeeId => _employee!.employeeId;

  SalesQuotationBloc get _bloc => context.read<SalesQuotationBloc>();

  /// Construct Sales Quote object
  SalesQuotation get _newQuote => SalesQuotation(
    quoteNumber: _quoteNumber,
    autoConvertSq: _autoConvertSO,
    storeNumber: _employee!.storeNumber,
    status: WorkflowStatusUtil.fromString(_sqStatus),

    salesRepId: _salesRepId,
    customerId: _customerId ?? 'new',
    customerName: _customerName,
    addresses: _addresses,
    salesChannel: SalesChannelUtil.fromString(_salesChannelId),

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
    createdBy: _employee!.fullName,
    history: [
      AuditLog(
        action: AuditAction.created,
        actionBy: _employeeId,
        statusAfterAction: _sqStatus,
      ),
    ],
  );

  void _onSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    if (!_isFormValid || _newQuote.isEmpty) {
      _showAlert('Please enter all required fields');
      return;
    }

    _finalizedQuote = _sanitizeTaxCodes(_newQuote);

    _bloc.add(AddSalesDistribution<SalesQuotation>(data: _finalizedQuote));
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

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _formResetKey = UniqueKey(); // 💥 full rebuild

      _isFormValid = false;
      _isSubmitting = false;
      _autoConvertSO = false;
      _salesRepId = '';
      _customerId = '';
      _lineItems.clear();
      _addresses.clear();
      _sqStatus = null;
      _customerName = '';
      _salesChannelId = '';
      _taxCodes.clear();
      _taxModeToApply = null;
      _validityDate.clear();
      _currencyPricing.clear();
      _termsConditions.clear();
      _finalizedQuote = SalesQuotation.empty;

      _lineItems.clear();
      _addresses.clear();
      _validityDate.clear();
    });
  }

  void _syncValidity() => _formKey.syncValidity(
    currentValidity: _isFormValid,
    onChanged: (v) => setState(() => _isFormValid = v),
  );

  void _showAlert(String msg) {
    context.showAlertOverlay(msg, onCallback: () => _resetForm());
    setState(() => _isSubmitting = false);
  }

  Future<void> _handleBlocState(
    BuildContext cxt,
    SalesDistributionState<SalesQuotation> state,
  ) async {
    switch (state) {
      case SalesDistributionAdded<SalesQuotation>(message: var msg):
        _showAlert(msg ?? 'Quote created successfully');
        await _confirmPrintoutDialog();
      case SalesDistributionError<SalesQuotation>():
        _showAlert('Something went wrong! Please, try again');
      case _: // no action
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      SalesQuotationBloc,
      SalesDistributionState<SalesQuotation>
    >(
      listener: _handleBlocState,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: KeyedSubtree(key: _formResetKey, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    return FormGroupTabView(
      contents: formGroupCards,
      header: AutoIDField(
        label: 'Quote Number',
        onGenerate: () async => await DocType.sQuote.getShortUID,
        onChanged: (id) {
          setState(() => _quoteNumber = id);
          _syncValidity();
        },
      ),
      footers:[
        context.confirmableActionButton(
          submitLabel: _isSubmitting ? 'Creating...' : 'Create Quote',
          isDisabled: !_isFormValid || _isSubmitting,
          onSubmit: _onSubmit,
        ),
      ],
      visibleWhen: _isFormValid,
      showNavigationButtons: true,
    );
  }

  List<FormGroupCardModel> get formGroupCards => [
    FormGroupCardModel(
      title: 'Quotation Overview',
      subTitle: '\nGeneral quotation info & document status.',
      builder: () => [
        _buildAutoCreateAndStatus(),
      ],
    ),

    FormGroupCardModel(
      title: 'Customer & Sales',
      subTitle:
      '\nCustomer details, sales channel, & sales representative.',
      builder: () => [
        _buildSalesChannel(),
        _buildSalesRepAndCustomer(),
      ],
    ),

    FormGroupCardModel(
      title: 'Pricing & Tax Determination',
      subTitle:
      '\nCurrency, pricing conditions, & tax preferences.',
      builder: () => [
        _buildCurrencyPricing(),
        const HorizontalDivider(space: 0.4),
        _buildTaxModeSelector(),
      ],
    ),

    FormGroupCardModel(
      title: '${_lineItemType.toSentence} Line Items',
      subTitle:
      '\nYou can add more ${_lineItemType}s to the Quotation.',
      builder: () => [
        _buildLineItems(),
      ],
    ),

    FormGroupCardModel(
      title: 'Dates & Validity',
      subTitle:
      '\nQuotation date, validity period, & delivery timeline.',
      builder: () => [
        _buildDateValidity(),
      ],
    ),

    FormGroupCardModel(
      title: 'Addresses',
      subTitle:
      '\nCustomer Bill-to, Ship-to, & other address details.',
      builder: () => [
        _buildAddresses(),
      ],
    ),

    FormGroupCardModel(
      title: 'Terms & Conditions',
      subTitle:
      '\nPayment terms, warranty, & commercial conditions.',
      builder: () => [
        _buildTermsConditions(),
      ],
    ),
  ];

  // -------------------------
  // Section Builders
  // -------------------------
  AutoCreateAndSQStatus _buildAutoCreateAndStatus() {
    return AutoCreateAndSQStatus(
      onStatusChanged: (s) {
        setState(() => _sqStatus = s);
        _syncValidity();
      },
      isSelected: _autoConvertSO,
      onAutoConvertChanged: (bool? v) {
        setState(() => _autoConvertSO = v ?? false);
        _syncValidity();
      },
    );
  }

  SalesChannelChoice _buildSalesChannel() {
    return SalesChannelChoice(
      onChannelChange: (s) {
        setState(() => _salesChannelId = s);
        _syncValidity();
      },
    );
  }

  SalesRepAndCustomer _buildSalesRepAndCustomer() {
    return SalesRepAndCustomer(
      onSalesRepChanged: (id, code, name) {
        setState(() => _salesRepId = name);
        _syncValidity();
      },
      onCustomerChange: (id, name) {
        setState(() {
        _customerId = id;
        _customerName = name;
      });
        _syncValidity();
      },
    );
  }

  Widget _buildTaxModeSelector() {
    return SQFormInputs.buildTaxModeSelector(
      selectedTaxCodes: _taxCodes,
      defaultTaxMode: _taxModeToApply,
      selectedTaxMode: (TaxMode? mode) {
        setState(() => _taxModeToApply = mode);
        _syncValidity();
      },
    );
  }

  DynamicTextFields _buildLineItems() {
    return DynamicTextFields(
      isRepeatable: true,
      fieldsConfig: SQFormInputs.fields(
        _lineItemType ?? '',
        isHidden: _taxModeToApply != TaxMode.perLineTax,
      ),
      initialData: [{}],
      onChanged: (List<Map<String, dynamic>> data) {
        // Update the ProLineItem list
        SQFormInputs.updateListFromData<LineItem>(
          _lineItems,
          map: data,
          fromMap: (map, id) =>
              LineItem.fromMap(map, id: id, lineType: _lineItemType),
        );
        _syncValidity();
      },
    );
  }

  DynamicTextFields _buildCurrencyPricing() {
    return DynamicTextFields(
      initialData: [{}],
      fullWidthKey: 'currencyPricing',
      fieldsConfig: SQFormInputs.currencyPricingFields,
      onChanged: (List<Map<String, dynamic>> data) {
        _currencyPricing
          ..clear()
          ..addAll(data.first);

        _syncValidity();
      },
    );
  }

  DynamicTextFields _buildDateValidity() {
    return DynamicTextFields(
      initialData: [{}],
      fieldsConfig: SQFormInputs.validityDateFields,
      onChanged: (List<Map<String, dynamic>> data) {
        _validityDate
          ..clear()
          ..addAll(data.first);

        _syncValidity();
      },
    );
  }

  // Addresses (e.g., Buyer Shipping & Billing Address)
  DynamicTextFields _buildAddresses() {
    return DynamicTextFields(
      initialData: [{}],
      isRepeatable: true,
      fieldGroupsLimit: 2,
      fieldsConfig: SQFormInputs.addressesFields,
      onChanged: (List<Map<String, dynamic>> data) {
        // if (_isFormValid) setState(() {});

        // Update the address list
        SQFormInputs.updateListFromData<AddressInfo>(
          _addresses,
          map: data,
          fromMap: (map, id) => AddressInfo.fromMap(map, id: id),
        );

        _syncValidity();
      },
    );
  }

  DynamicTextFields _buildTermsConditions() {
    return DynamicTextFields(
      initialData: [{}],
      fullWidthKey: 'supplierTerms',
      fieldsConfig: SQFormInputs.supplierTermsFields,
      onChanged: (List<Map<String, dynamic>> data) {
        _termsConditions
          ..clear()
          ..addAll(data.first);
        _syncValidity();
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
        onSuccess: (_) => _showAlert('Sales Quote printout created'),
        onError: (e) => _showAlert('Sales Quote printout failed'),
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
}
