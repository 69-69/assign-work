import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/tax_mode.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/doc_type_enum.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/form_group_card.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/procurement/data/data_sources/remote/get_suppliers.dart';
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_quote/pro_request_for_quote_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_quote/widget/form_inputs.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_quote/widget/rfq_printer.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_taxes.dart';
import 'package:assign_erp/features/system_admin/data/models/tax_model.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/manage_taxes/widget/search_taxes.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateRequestForQuotationForm on BuildContext {
  Future openUpdateRequestForQuote({required RequestForQuote quote}) async {
    if (quote.id.isEmpty) return;

    return await openBottomSheet(
      isExpand: false,
      child: FormBottomSheet(
        title: 'Edit Request For Quote',
        subtitle: quote.rfqNumber.toUpperAll,
        body: _UpdateRequestForQuote(quote: quote),
      ),
    );
  }
}

class _UpdateRequestForQuote extends StatefulWidget {
  final RequestForQuote quote;

  const _UpdateRequestForQuote({required this.quote});

  @override
  State<_UpdateRequestForQuote> createState() => _UpdateRequestForQuoteState();
}

class _UpdateRequestForQuoteState extends State<_UpdateRequestForQuote> {
  final _formKey = GlobalKey<FormState>();

  /// [_taxModeToApply] Tax method to apply either per line[PerLineTax] or per order[HeaderTax].
  TaxMode? _taxModeToApply;

  // Basic fields
  String? _currency;
  String? _rfqTitle;
  String? _requestedBy;
  String? _departmentCode;
  String? _supplierId;
  String? _supplierRepId; // supplier's contact person
  String? _rfqStatus;
  String? _paymentTerm;
  // Dates
  DateTime? _deadlineDate;
  DateTime? _deliveryDate;
  DateTime? _validityDate;
  final _titleController = TextEditingController();

  final List<String> _taxCodes = [];

  /// Line Items & Additional Info
  final List<RFQLineItem> _lineItems = [];
  final Map<String, dynamic> _additionalInfo = {};

  RequestForQuote get _serverRFQ => widget.quote;

  List<String> get _initialHeaderTaxes =>
      _serverRFQ.taxMode == TaxMode.headerTax
      ? List.from(_serverRFQ.lineItems.first.taxCodes)
      : [];

  bool get isFormValid => _formKey.currentState?.validate() ?? false;

  /// Current employee info
  String get _employeeId => context.employee!.employeeId;
  String get _employeeName => context.employee!.fullName;

  ProRequestForQuoteBloc get _bloc => context.read<ProRequestForQuoteBloc>();

  AuditAction get _action => _rfqStatus!.contains('approved')
      ? AuditAction.approved
      : AuditAction.updated;

  @override
  void initState() {
    super.initState();
    _taxModeToApply = _serverRFQ.taxMode;
    _titleController.text = _serverRFQ.title;
    _additionalInfo.addAll({
      'notes': _serverRFQ.notes,
      'deliveryAddress': _serverRFQ.deliveryAddress,
    });
    _lineItems.addAll(_serverRFQ.lineItems);
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Construct Request For Quote object
  RequestForQuote get _updatedRFQ => _serverRFQ.copyWith(
    taxMode: _taxModeToApply,
    title: _rfqTitle,
    notes: _additionalInfo['notes'],
    deliveryAddress: _additionalInfo['deliveryAddress'],
    requestedBy: _requestedBy ?? _serverRFQ.requestedBy,
    status: _rfqStatus ?? _serverRFQ.status,
    currency: _currency ?? _serverRFQ.currency,
    departmentCode: _departmentCode ?? _serverRFQ.departmentCode,
    supplierId: _supplierId ?? _serverRFQ.supplierId,
    supplierRepId: _supplierRepId ?? _serverRFQ.supplierRepId,
    lineItems: List.from(_lineItems),
    deadline: _deadlineDate ?? _serverRFQ.deadline,
    paymentTerm: _paymentTerm ?? _serverRFQ.paymentTerm,
    deliveryDate: _deliveryDate ?? _serverRFQ.deliveryDate,
    validityDate: _validityDate != null
        ? '${_validityDate!.toDays} days'
        : _serverRFQ.validityDate,
    updatedBy: _employeeName,
    history: [
      ..._serverRFQ.history, // keep all old logs
      AuditLog(action: _action, performedBy: _employeeId),
    ],
  );

  void _onSubmit() {
    if (!isFormValid || _lineItems.isNullOrEmpty) {
      context.showAlertOverlay(
        'Please enter all required fields',
        bgColor: kDangerColor,
      );
      return;
    }

    final sanitizedQuote = _sanitizeTaxCodes(_updatedRFQ);

    _bloc.add(
      UpdateProcurement<RequestForQuote>(
        documentId: sanitizedQuote.id,
        data: sanitizedQuote,
      ),
    );

    context.showAlertOverlay('Changes successfully saved');

    _confirmPrintoutDialog();
  }

  RequestForQuote _sanitizeTaxCodes(RequestForQuote quote) {
    if (quote.taxMode == TaxMode.headerTax) {
      final updatedItems = quote.lineItems
          .map((e) => e.copyWith(taxCodes: _taxCodes))
          .toList();

      return quote.copyWith(lineItems: updatedItems);
    }
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

        FormGroupCard(children: [_buildLineItems()]),

        FormGroupCard(
          title: 'Buyer Terms',
          children: [_buildDates(), _buildCurrency()],
        ),

        FormGroupCard(
          title: 'Supplier Terms',
          children: [_buildValidityAndPayTerms(), _buildTaxModeSelector()],
        ),

        FormGroupCard(children: [_buildDeliveryAndNotes()]),

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
      onRequestedBy: (id, code, name) => setState(() => _requestedBy = name),
      onDepartmentChange: (id, code, name) =>
          setState(() => _departmentCode = code),
    );
  }

  Widget _buildValidityAndPayTerms() {
    return ValidityAndPayTermsDropdown(
      initialPayTerms: _serverRFQ.paymentTerm,
      onPayTermsChanged: (s) => setState(() => _paymentTerm = s),
      initialValidity: _serverRFQ.getValidityDate,
      onValidityChanged: (date) => setState(() => _validityDate = date),
    );
  }

  Widget _buildTaxModeSelector() {
    return TaxModeSelector(
      initialValues: _initialHeaderTaxes,
      onRadioChanged: _onSelectTaxMode,
      defaultTaxMode: _taxModeToApply,
      onCheckChanged: (List<Map<String, dynamic>> data) {
        // if (_isValid) setState(() {});

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

  Widget _buildDeliveryAndNotes() {
    return DynamicTextFields(
      title: 'Delivery Address and Notes',
      initialData: [
        {
          'notes': _serverRFQ.notes,
          'deliveryAddress': _serverRFQ.deliveryAddress,
        },
      ],
      fieldsConfig: _RFQFormConfig.deliveryFields(),
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
      initialCurrency: _serverRFQ.currency,
      onCurrencyChanged: (s) => setState(() => _currency = s),
    );
  }

  Widget _buildDates() {
    return DeadlineAndDeliveryDateInput(
      labelDelivery: "Delivery date",
      labelDeadline: "Deadline date",
      initialDeadlineDate: _serverRFQ.getDeadlineDate,
      initialDeliveryDate: _serverRFQ.getDeliveryDate,
      onDeliveryChanged: (date) => setState(() => _deliveryDate = date),
      onDeadlineChanged: (date) => setState(() => _deadlineDate = date),
    );
  }

  Widget _buildLineItems() {
    return DynamicTextFields(
      showButton: true,
      title: 'Products / Services',
      fieldsConfig: _RFQFormConfig.itemsFields(
        _taxModeToApply != TaxMode.perLineTax,
      ),
      initialData: _serverRFQ.lineItems.map((e) => e.toMap()).toList(),
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});
        _lineItems
          ..clear() // Clear previous entries to prevent duplication
          ..addAll(data.map((e) => RFQLineItem.fromMap(e)));
      },
    );
  }

  Widget _buildSupplierAndStatus() {
    return SuppliersAndRFQStatusDropdown(
      initialStatus: _serverRFQ.status,
      initialSupplier: _serverRFQ.supplierId,
      initialSupplierRep: _serverRFQ.supplierRepId,
      onStatusChanged: (s) => setState(() => _rfqStatus = s),
      onSupplierChanged: (id, name) => setState(() => _supplierId = id),
      onContactPersonChanged: (id) => setState(() => _supplierRepId = id),
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
    final quoteWithTaxes = await _RFQFormConfig.applyTaxesToQuote(_updatedRFQ);
    final supplier = await _RFQFormConfig.getSupplier(_updatedRFQ.supplierId);
    if (supplier.isEmpty) return;

    // Log that details were printed
    if (mounted &&
        AuditTracker.shouldLog(
          id: _updatedRFQ.id,
          type: DocType.prs,
          action: AuditAction.printed,
        )) {
      _updateHistory();
    }

    await RFQPrinter(quote: quoteWithTaxes, supplier: supplier).printRFQ();
  });

  /// Audit Log Entry (Tracking actions)
  void _updateHistory([AuditAction action = AuditAction.printed]) {
    final up = _RFQFormConfig.updateHistory(
      empId: _employeeId,
      action: action,
      quote: _updatedRFQ,
    );
    _bloc.add(up);
  }
}

class _RFQFormConfig {
  static Future<RequestForQuote> applyTaxesToQuote(
    RequestForQuote quote,
  ) async {
    final taxMap = await GetTaxes.loadAllTaxRates();
    return quote.computeTaxAmounts(taxMap);
  }

  static Future getSupplier(String supplierId) async {
    final supplier = await GetSuppliers.bySupplierId(supplierId);
    return supplier.isEmpty ? null : supplier;
  }

  /// Audit Log Entry (Tracking actions)
  static AuditProcurement<RequestForQuote> updateHistory({
    required String empId,
    required AuditAction action,
    required RequestForQuote quote,
  }) {
    final up = AuditProcurement<RequestForQuote>(
      documentId: quote.id,
      log: {
        'history': [
          ...quote.history.map((e) => e.toMap()), // keep old logs
          AuditLog(action: action, performedBy: empId).toMap(), // new log
        ],
      },
    );
    return up;
  }

  /// Products / Services
  static List<FieldGroupConfig> itemsFields(bool isHidden) {
    return [
      ..._textFields.map(
        (e) => FieldGroupConfig(
          key: e.$1,
          label: e.$2,
          type: e.$3,
          validator: e.$1 == 'discount' ? (_) => null : null,
        ),
      ),
      FieldGroupConfig(
        key: 'unitOfMeasure',
        label: 'Unit of Measure (e.g. box, kg)',
        type: TextInputType.text,
        widgetType: FieldWidgetType.custom,
        customBuilder: ({required initialData, required onChanged}) {
          return UnitOfMeasureDropdown(
            initialValue: initialData,
            onChanged: (String? selected) => onChanged(selected),
          );
        },
      ),
      FieldGroupConfig(
        key: 'category',
        label: 'Item Group (e.g. Office Supplies, IT)',
        type: TextInputType.text,
        widgetType: FieldWidgetType.custom,
        customBuilder: ({required initialData, required onChanged}) {
          return ItemCategoryDropdown(
            initialValue: initialData,
            onChanged: (String? selected) => onChanged(selected),
          );
        },
      ),
      // Tax Rate % (Per item)
      FieldGroupConfig(
        key: 'taxCodes',
        label: 'Tax Rate % (Per item)',
        type: TextInputType.text,
        widgetType: FieldWidgetType.custom,
        hideField: isHidden,
        customBuilder: ({required initialData, required onChanged}) {
          return TaxMultiSelectDropdown(
            initialValues: initialData,
            onMultiChanged: (List<Tax> selected) {
              final taxCodes = selected.map((e) => e.code).toList();
              onChanged(taxCodes);
            },
          );
        },
      ),
      /*FieldGroupConfig(
      key: 'notes',
      label: 'Additional Notes (if any)...',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
    ),*/
    ];
  }

  /// Delivery Address and Notes
  static List<FieldGroupConfig> deliveryFields() {
    return [
      FieldGroupConfig(
        key: 'deliveryAddress',
        label: 'Delivery address (if any)...',
        type: TextInputType.multiline,
        isTextArea: true,
        isAutoGrow: true,
        minLines: null,
        validator: (_) => null,
      ),
      FieldGroupConfig(
        key: 'notes',
        label: 'Additional Notes (if any)...',
        type: TextInputType.multiline,
        isTextArea: true,
        isAutoGrow: true,
        minLines: null,
        validator: (_) => null,
      ),
    ];
  }

  static List<(String, String, TextInputType)> get _textFields =>
      <(String, String, TextInputType)>[
        ('itemName', 'Item name', TextInputType.text),
        ('quantity', 'Quantity', TextInputType.number),
        ('unitPrice', 'Unit price', TextInputType.number),
        (
          'discount',
          'Discount %',
          TextInputType.numberWithOptions(decimal: true),
        ),
      ];
}
