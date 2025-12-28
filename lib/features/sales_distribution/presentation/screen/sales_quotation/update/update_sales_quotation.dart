import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/tax_mode.dart';
import 'package:assign_erp/core/constants/workflow_status.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/doc_type_enum.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_rfq/pro_request_for_quote_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/widget/rfq_form_inputs.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/widget/rfq_printer.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_taxes/widget/search_taxes.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateSalesQuotationForm on BuildContext {
  Future openUpdateSalesQuote({required RequestForQuote quote}) async {
    if (quote.id.isEmpty) return;

    return await openBottomSheet(
      isExpand: false,
      child: BottomSheetScaffold(
        title: 'Edit Sales Quote',
        subtitle: quote.rfqNumber.toUpperAll,
        body: _UpdateSalesQuote(quote: quote),
      ),
    );
  }
}

class _UpdateSalesQuote extends StatefulWidget {
  final RequestForQuote quote;

  const _UpdateSalesQuote({required this.quote});

  @override
  State<_UpdateSalesQuote> createState() => _UpdateSalesQuoteState();
}

class _UpdateSalesQuoteState extends State<_UpdateSalesQuote> {
  final _formKey = GlobalKey<FormState>();
  late RequestForQuote _cachedUpdatedSQ;

  /// [_taxModeToApply] Tax method to apply either per line[PerLineTax] or per order[HeaderTax].
  TaxMode? _taxModeToApply;

  // Basic fields
  bool _isSubmitting = false;
  String? _currencyCode;
  String? _rfqTitle;
  String? _requestedBy;
  String? _departmentCode;
  String? _rfqStatus;
  String? _paymentTerm;
  // Dates
  DateTime? _deadlineDate;
  DateTime? _expectedDate;

  final List<String> _taxCodes = [];

  /// Line Items & Additional Info
  final List<LineItem> _lineItems = [];
  final Map<String, dynamic> _additionalInfo = {};

  RequestForQuote get _serverRFQ => widget.quote;
  String? get _lineItemType => _serverRFQ.lineItems.first.getTypeLabel;

  List<String> get _initialHeaderTaxes => _serverRFQ.taxMode.isHeaderTax
      ? List.from(_serverRFQ.lineItems.first.taxCodes)
      : [];

  bool get isFormValid => _formKey.currentState?.validate() ?? false;

  /// Current employee info
  String get _employeeId => context.employee!.employeeId;
  String get _employeeName => context.employee!.fullName;

  ProRequestForQuoteBloc get _bloc => context.read<ProRequestForQuoteBloc>();

  AuditAction get _action => AuditActionHelper.isApproved(_rfqStatus)
      ? AuditAction.approved
      : AuditAction.updated;

  @override
  void initState() {
    super.initState();
    _taxModeToApply = _serverRFQ.taxMode;
    _additionalInfo.addAll({
      'notes': _serverRFQ.notes,
      'deliveryAddress': _serverRFQ.shippingAddress,
    });
    _lineItems.addAll(_serverRFQ.lineItems);
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Construct Request For Quote object
  RequestForQuote get _updatedRFQ {
    final status = _rfqStatus ?? _serverRFQ.status.getName;

    return _serverRFQ.copyWith(
      taxMode: _taxModeToApply,
      title: _rfqTitle ?? _serverRFQ.title,
      requestedBy: _requestedBy ?? _serverRFQ.requestedBy,
      status: WorkflowStatusHelper.fromString(status),
      currencyCode: _currencyCode ?? _serverRFQ.currencyCode,
      departmentCode: _departmentCode ?? _serverRFQ.departmentCode,
      supplierLinks: _serverRFQ.supplierLinks,
      lineItems: List.from(_lineItems),
      notes: _additionalInfo['notes'],
      shippingAddress: _additionalInfo['deliveryAddress'],
      termsAndConditions: _additionalInfo['termsAndConditions'],
      deadline: _deadlineDate ?? _serverRFQ.deadline,
      buyerContactPersonId: _paymentTerm ?? _serverRFQ.buyerContactPersonId,
      expectedDate: _expectedDate ?? _serverRFQ.expectedDate,
      updatedBy: _employeeName,
      history: [
        ..._serverRFQ.history, // keep all old logs
        AuditLog(
          action: _action,
          actionBy: _employeeId,
          statusAfterAction: status,
        ),
      ],
    );
  }

  void _onSubmit() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      if (!isFormValid || _lineItems.isNullOrEmpty) return;

      _cachedUpdatedSQ = _sanitizeTaxCodes(_updatedRFQ);

      _bloc.add(
        UpdateProcurement<RequestForQuote>(
          documentId: _cachedUpdatedSQ.id,
          data: _cachedUpdatedSQ,
        ),
      );

      context.showAlertOverlay('Changes successfully saved');
      _confirmPrintoutDialog();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          title: 'Request for Quotes',
          children: [
            _buildTitleField(),
            _buildRequesterAndDepartment(),
            _buildSupplierAndStatus(),
          ],
        ),

        FormGroupCard(
          title: '${_lineItemType.toSentence} Line Items',
          subTitle:
              '\nYou can add more ${_lineItemType}s to the Quotation (RFQ).',
          children: [_buildLineItems()],
        ),

        FormGroupCard(
          title: 'Buyer Terms',
          children: [_buildDates(), _buildCurrency()],
        ),

        FormGroupCard(
          title: 'Supplier Terms',
          children: [/*_buildValidityAndPayTerms()*/ _buildTaxModeSelector()],
        ),

        FormGroupCard(
          title: 'Delivery Address and Terms',
          children: [_buildDeliveryAndTerms()],
        ),

        context.confirmableActionButton(onPressed: _onSubmit),
        const SizedBox(height: 20.0),
      ],
    );
  }

  // -------------------------
  // Section Builders
  // -------------------------
  Widget _buildTitleField() {
    return DynamicTextFields(
      initialData: [
        {'title': _serverRFQ.title},
      ],
      fieldsConfig: [
        FieldGroupConfig(
          key: 'title',
          label: 'Title or subject',
          type: TextInputType.text,
          minLines: 1,
        ),
      ],
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _rfqTitle = data.first['title'];
      },
    );
  }

  Widget _buildRequesterAndDepartment() {
    return RequestedByAndDepartments(
      initialRequestedBy: _serverRFQ.requestedBy,
      initialDepartment: _serverRFQ.departmentCode,
      onRequestedChanged: (id, code, name) =>
          setState(() => _requestedBy = name),
      onDepartmentChange: (id, code, name) =>
          setState(() => _departmentCode = code),
    );
  }

  /*Widget _buildValidityAndPayTerms() {
    return ValidityAndPayTermsDropdown(
      initialPayTerms: _serverRFQ.buyerContactPersonId,
      onPayTermsChanged: (s) => setState(() => _paymentTerm = s),
      initialValidity: _serverRFQ.getValidityDate,
      onValidityChanged: (date) => setState(() => _validityDate = date),
    );
  }*/

  Widget _buildTaxModeSelector() {
    return TaxModeSelector(
      initialValues: _initialHeaderTaxes,
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

  Widget _buildDeliveryAndTerms() {
    return DynamicTextFields(
      initialData: [
        {
          'notes': _serverRFQ.notes,
          'shippingAddress': _serverRFQ.shippingAddress,
        },
      ],
      fieldsConfig: RFQFormInputs.deliveryFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _additionalInfo
          ..clear() // Clear previous entries to prevent duplication
          ..addAll(data.first);
      },
    );
  }

  Widget _buildCurrency() {
    return CurrencyDropdown(
      initialCurrency: _serverRFQ.currencyCode,
      onCurrencyChanged: (s) => setState(() => _currencyCode = s),
    );
  }

  Widget _buildDates() {
    return DeadlineAndExpectedDateInput(
      lineItemType: _lineItemType,
      labelExpected: "Expected date",
      labelDeadline: "Deadline date",
      initialDeadlineDate: _serverRFQ.getDeadlineDate,
      initialExpectedDate: _serverRFQ.getExpectedDate,
      onExpectedChanged: (date) => setState(() => _expectedDate = date),
      onDeadlineChanged: (date) => setState(() => _deadlineDate = date),
    );
  }

  Widget _buildLineItems() {
    return DynamicTextFields(
      showButton: true,
      fullWidthKey: 'description',
      fieldsConfig: RFQFormInputs.fields(
        _lineItemType ?? '',
        isHidden: _taxModeToApply != TaxMode.perLineTax,
        keysToExclude: [],
      ),
      initialData: _serverRFQ.lineItems.map((e) => e.toMap(true)).toList(),
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        // Update the ProLineItem list
        RFQFormInputs.updateListFromData<LineItem>(
          _lineItems,
          map: data,
          fromMap: (map, id) => LineItem.fromMap(map, id: id),
        );
      },
    );
  }

  Widget _buildSupplierAndStatus() {
    return SizedBox.shrink();
    /*AutoCreateAndRFQStatus(
      initialStatus: _serverRFQ.status.getName,
      initialSupplier: _serverRFQ.supplierId,
      initialSupplierRep: _serverRFQ.supplierRepId,
      onStatusChanged: (s) => setState(() => _rfqStatus = s),
      onSupplierChanged: (id, name) => setState(() => _supplierId = id),
      onContactPersonChanged: (id) => setState(() => _supplierRepId = id),
    );*/
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
      const Text('Would you like to print this Request for Quote (RFQ)?'),
      title: "Print RFQ",
      onAcceptLabel: "Print",
      onRejectLabel: "Cancel",
    );

    if (mounted) {
      if (!isConfirmed) return;

      // Show progress dialog while loading data
      await context.progressBarDialog(
        request: _printout(),
        onSuccess: (_) {
          context.showAlertOverlay('RFQ Printout successful');
          Navigator.pop(context);
        },
        onError: (e) => context.showAlertOverlay(
          'RFQ printout failed',
          bgColor: kDangerColor,
        ),
      );
    }
  }

  Future<dynamic> _printout() => Future.delayed(kRProgressDelay, () async {
    final quoteWithTaxes = await RFQFormInputs.applyTaxesToQuote(
      _cachedUpdatedSQ,
    );
    final supplier = await RFQFormInputs.getSupplier(
      _cachedUpdatedSQ.supplierLinks.first.supplierId,
    );
    if (supplier.isEmpty) return;

    // Log that details were printed
    if (mounted &&
        AuditTracker.shouldLog(
          id: _cachedUpdatedSQ.id,
          type: DocType.prs,
          action: AuditAction.printed,
        )) {
      _updateHistory();
    }

    await RFQPrinter(rfq: quoteWithTaxes, supplier: supplier).printRFQ();
  });

  /// Audit Log Entry (Tracking actions)
  void _updateHistory([AuditAction action = AuditAction.printed]) {
    final up = RFQFormInputs.updateHistory(
      empId: _employeeId,
      action: action,
      rfq: _updatedRFQ,
    );
    _bloc.add(up);
  }
}
