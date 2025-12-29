import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/tax_mode.dart';
import 'package:assign_erp/core/constants/workflow_status.dart';
import 'package:assign_erp/core/network/data_sources/models/address_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/doc_type_enum.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
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
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_link_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_rfq/pro_request_for_quote_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/widget/rfq_printer.dart';
import 'package:assign_erp/features/sales_distribution/presentation/screen/sales_quotation/widget/sq_form_inputs.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_taxes/widget/search_taxes.dart';
import 'package:collection/collection.dart';
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
      title: 'Create Sales Quotation',
      onBackPress: onBackPress,
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
  bool _isRebuilding = false;

  // Basic fields
  String? _sqStatus;
  String _rfqTitle = '';
  String _quoteNumber = '';
  String _currencyCode = '';
  String _salesRepId = '';
  String _costCenterCode = '';
  bool _autoConvertSO = true; // If approved, auto-convert SQ to SO
  bool _isSubmitting = false;
  String _customerId = '';

  final List<String> _taxCodes = [];
  final List<LineItem> _lineItems = [];
  final Map<String, dynamic> _validityDate = {};
  final Map<String, dynamic> _currencyPricing = {};
  final Map<String, dynamic> _supplierTerms = {};
  final List<SupplierLink> _supplierLinks = [];
  final List<AddressInfo> _addresses = [];

  /// [_taxModeToApply] Tax method to apply either per line[PerLineTax] or per order[HeaderTax].
  TaxMode? _taxModeToApply;
  late RequestForQuote _cachedUpdatedSQ;

  bool get isFormValid => _formKey.currentState!.validate();

  Employee? get _employee => context.employee;

  /// Current employee info
  String get _employeeId => _employee!.employeeId;

  ProRequestForQuoteBloc get _bloc => context.read<ProRequestForQuoteBloc>();

  void _generateSQNumber() async {
    await DocType.sQuote.getShortUID(
      onChanged: (s) {
        if (mounted) setState(() => _quoteNumber = s);
      },
    );
  }

  /// Construct RequestForQuote object
  RequestForQuote get _newRFQ => RequestForQuote(
    /// [prNumber] FOREIGN KEY (purchase requisition) else its new RFQ (Not generated from PR)
    prNumber: 'N/A',
    rfqNumber: _quoteNumber,
    storeNumber: _employee!.storeNumber,
    autoConvertRfq: _autoConvertSO,
    title: _rfqTitle,
    status: WorkflowStatusHelper.fromString(_sqStatus ?? ''),
    supplierLinks: List.from(_supplierLinks),
    currencyCode: _currencyCode,
    notes: _validityDate['notes'],
    lineItems: List.from(_lineItems),
    taxMode: _taxModeToApply ?? TaxMode.headerTax,
    shippingAddress: _addresses.first,
    deadline: toDateTimeFn(_validityDate['deadline']),
    expectedDate: toDateTimeFn(_validityDate['expectedDate']),
    buyerContactPersonId: _validityDate['buyerContactPerson'],
    requestedBy: _salesRepId,
    costCenterCode: _costCenterCode,
    departmentCode: _customerId,
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

    try {
      if (!isFormValid || _newRFQ.isEmpty) {
        context.showAlertOverlay(
          'Please enter all required fields',
          bgColor: kDangerColor,
        );
        return;
      }

      _cachedUpdatedSQ = _sanitizeTaxCodes(_newRFQ);

      _bloc.add(AddProcurement<RequestForQuote>(data: _cachedUpdatedSQ));

      context.showAlertOverlay('RFQ successfully created');

      _confirmPrintoutDialog();
    } finally {
      if (mounted && isFormValid) {
        await _rebuildForm(); // rebuild fresh form
      }
    }
  }

  /// Ensures tax codes are correctly applied to RFQ line items
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
  RequestForQuote _sanitizeTaxCodes(RequestForQuote quote) {
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

  Future<void> _rebuildForm() async {
    _resetForm();
    if (_isRebuilding) return;
    _isRebuilding = true;
    // 1️⃣ Close current bottom sheet and WAIT
    await Navigator.of(context).maybePop();

    // 2️⃣ Wait one frame (critical)
    await Future.delayed(Duration.zero);

    // 3️⃣ Open fresh form
    if (mounted) {
      await context.openCreateSQForm(type: widget.lineItemType);
    }
    _isRebuilding = false;
  }

  void _resetForm() {
    _formKey.currentState?.reset();

    setState(() {
      _isSubmitting = false;
      _rfqTitle = '';
      _autoConvertSO = false;
      _supplierLinks.clear();
      _salesRepId = '';
      _currencyCode = '';
      _costCenterCode = '';
      _customerId = '';
      _lineItems.clear();
      _addresses.clear();
      _sqStatus = null;
    });

    // Reset dynamic fields
    _lineItems.clear();
    _supplierLinks.clear();
    _addresses.clear();
    _validityDate.clear();

    _generateSQNumber();
  }

  @override
  void initState() {
    _generateSQNumber();
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
        SQFormInputs.buildSQNumber(context, _quoteNumber, _generateSQNumber),

        FormGroupCard(
          title: 'Quotation Overview',
          children: [_buildAutoCreateAndStatus()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: 'Customer & Sales',
          children: [_buildSalesChannel(), _buildRequesterAndDepartment()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: 'Currency & Pricing',
          children: [
            _buildCurrencyPricing(),
            HorizontalDivider(space: 0.4),
            _buildTaxModeSelector(),
          ],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '${_lineItemType.toSentence} Line Items',
          subTitle: '\nYou can add more ${_lineItemType}s to the Quotation.',
          children: [_buildLineItems()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: 'Dates & Validity',
          children: [_buildDateValidity()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: 'Addresses',
          subTitle: '\nCustomer shipping & billing address.',
          children: [_buildShippingAddress()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: 'Terms & Conditions',
          subTitle: '\nPayment & warranty terms for the Quotation.',
          children: [_buildSupplierTerms()],
        ),

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

  DynamicTextFields _buildLineItems() {
    return DynamicTextFields(
      showButton: true,
      fieldsConfig: SQFormInputs.fields(
        _lineItemType ?? '',
        isHidden: _taxModeToApply != TaxMode.perLineTax,
        keysToExclude: ['limitAmount', 'limitQuantity'],
      ),
      initialData: [{}],
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        // Update the ProLineItem list
        SQFormInputs.updateListFromData<LineItem>(
          _lineItems,
          map: data,
          fromMap: (map, id) => LineItem.fromMap(map, id: id),
        );
      },
    );
  }

  // Addresses (e.g., Buyer Shipping Address)
  DynamicTextFields _buildShippingAddress() {
    return DynamicTextFields(
      initialData: [{}],
      showButton: true,
      fieldGroupsLimit: 2,
      fieldsConfig: SQFormInputs.shippingAddressFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        // Update the address list
        SQFormInputs.updateListFromData<AddressInfo>(
          _addresses,
          map: data,
          fromMap: (map, id) => AddressInfo.fromMap(map, id: id),
        );
      },
    );
  }

  DynamicTextFields _buildCurrencyPricing() {
    return DynamicTextFields(
      initialData: [{}],
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
      initialData: [{}],
      fieldsConfig: SQFormInputs.validityDateFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _validityDate
          ..clear()
          ..addAll(data.first);
      },
    );
  }

  DynamicTextFields _buildSupplierTerms() {
    return DynamicTextFields(
      initialData: [{}],
      fullWidthKey: 'supplierTerms',
      fieldsConfig: SQFormInputs.supplierTermsFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _supplierTerms
          ..clear()
          ..addAll(data.first);
      },
    );
  }

  AutoCreateAndSQStatus _buildAutoCreateAndStatus() {
    return AutoCreateAndSQStatus(
      onStatusChanged: (s) => setState(() => _sqStatus = s),
      isSelected: _autoConvertSO,
      onAutoConvertChanged: (bool? v) {
        setState(() => _autoConvertSO = v ?? false);
      },
    );
  }

  RequestedByAndDepartments _buildRequesterAndDepartment() {
    return RequestedByAndDepartments(
      onSalesRepChanged: (id, code, name) => setState(() => _salesRepId = name),
      onCustomerChange: (id, name) => setState(() => _customerId = id),
    );
  }

  SalesChannelChoice _buildSalesChannel() {
    return SalesChannelChoice(
      onChannelChange: (s) => setState(() => _customerId = s),
    );
  }

  Widget _buildTaxModeSelector() {
    return TaxModeSelector(
      initialValues: [],
      onRadioChanged: _onSelectTaxMode,
      defaultTaxMode: _taxModeToApply,
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

  // -------------------------
  // Print & History Logic
  // -------------------------
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
    if (_newRFQ.isEmpty) return;

    final quoteWithTaxes = await SQFormInputs.applyTaxesToQuote(_newRFQ);
    final supplier = await SQFormInputs.getSupplier(
      _newRFQ.supplierLinks.first.supplierId,
    );
    if (supplier.isEmpty) return;

    // Log that details were printed
    if (mounted &&
        AuditTracker.shouldLog(
          id: '${_newRFQ.id}::$_employeeId',
          type: DocType.rfq,
          action: AuditAction.printed,
        )) {
      _updateHistory();
    }
    await RFQPrinter(rfq: quoteWithTaxes, supplier: supplier).printRFQ();
  });

  /// Audit Log Entry (Tracking actions)
  void _updateHistory([AuditAction action = AuditAction.printed]) {
    final up = SQFormInputs.updateHistory(
      action: action,
      rfq: _newRFQ,
      empId: _employeeId,
    );
    _bloc.add(up);
  }

  DynamicTextFields _buildSuppliers() {
    return DynamicTextFields(
      initialData: [{}],
      showButton: true,
      fullWidthKey: 'supplierLinks',
      fieldsConfig: SQFormInputs.suppliersFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        final supplierLinks = data.map((e) {
          final copy = Map<String, dynamic>.from(e['supplierLinks'] ?? {});
          // Merge the status from the top-level map
          copy['status'] = e['status'];
          return copy;
        }).toList();

        // Update the RFQSupplier list
        SQFormInputs.updateListFromData<SupplierLink>(
          _supplierLinks,
          map: supplierLinks,
          fromMap: (map, id) => SupplierLink.fromMap(map, id: id),
        );
      },
    );
  }

  CurrencyAndCostCenterDepartment _buildCurrencyAndCostCenter() {
    return CurrencyAndCostCenterDepartment(
      onCurrencyChanged: (v) => setState(() => _currencyCode = v),
      onCostCenterChange: (id, code, name) =>
          setState(() => _costCenterCode = code),
    );
  }
}
