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

  String? _currency;
  String? _rfqTitle;
  String? _requestedBy;
  String? _departmentCode;
  String? _selectedSupplierId;
  String? _selectedSupplierRepId;
  String? _selectedRFQStatus;
  String? _selectedPaymentTerm;
  DateTime? _selectedDeadlineDate;
  DateTime? _selectedDeliveryDate;
  DateTime? _selectedValidityDate;
  final _titleController = TextEditingController();

  final List<String> _taxCodes = [];
  // Add a list to manage line items
  final List<RFQLineItem> _lineItems = [];
  final Map<String, dynamic> _addressAndNotes = {};

  RequestForQuote get _serverQuote => widget.quote;

  List<String> get _initialHeaderTaxes =>
      _serverQuote.taxMode == TaxMode.headerTax
      ? List.from(_serverQuote.lineItems.first.taxCodes)
      : [];

  bool get isFormValid => _formKey.currentState?.validate() ?? false;

  String get _currentEmployeeId => context.employee!.employeeId;

  ProRequestForQuoteBloc get _readBloc =>
      context.read<ProRequestForQuoteBloc>();

  AuditAction get _action => _selectedRFQStatus!.contains('approved')
      ? AuditAction.approved
      : AuditAction.updated;

  @override
  void initState() {
    super.initState();
    _taxModeToApply = _serverQuote.taxMode;
    _titleController.text = _serverQuote.title;
    _addressAndNotes.addAll({
      'notes': _serverQuote.notes,
      'deliveryAddress': _serverQuote.deliveryAddress,
    });
    _lineItems.addAll(_serverQuote.lineItems);
  }

  @override
  void dispose() {
    super.dispose();
  }

  RequestForQuote get _updatedQuote {
    return _serverQuote.copyWith(
      taxMode: _taxModeToApply,
      title: _rfqTitle,
      notes: _addressAndNotes['notes'],
      deliveryAddress: _addressAndNotes['deliveryAddress'],
      requestedBy: _requestedBy ?? _serverQuote.requestedBy,
      status: _selectedRFQStatus ?? _serverQuote.status,
      currency: _currency ?? _serverQuote.currency,
      departmentCode: _departmentCode ?? _serverQuote.departmentCode,
      supplierId: _selectedSupplierId ?? _serverQuote.supplierId,
      supplierRepId: _selectedSupplierRepId ?? _serverQuote.supplierRepId,
      lineItems: List.from(_lineItems),
      deadline: _selectedDeadlineDate ?? _serverQuote.deadline,
      paymentTerm: _selectedPaymentTerm ?? _serverQuote.paymentTerm,
      deliveryDate: _selectedDeliveryDate ?? _serverQuote.deliveryDate,
      validityDate: _selectedValidityDate != null
          ? '${_selectedValidityDate!.toDays} days'
          : _serverQuote.validityDate,
      updatedBy: context.employee!.fullName,
      history: [
        ..._serverQuote.history, // keep all old logs
        AuditLog(action: _action, performedBy: _currentEmployeeId),
      ],
    );
  }

  void _onSubmit() {
    if (!isFormValid || _lineItems.isNullOrEmpty) {
      context.showAlertOverlay(
        'Please enter all required fields',
        bgColor: kDangerColor,
      );
      return;
    }

    final sanitizedQuote = _sanitizeTaxCodes(_updatedQuote);

    _readBloc.add(
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
            DynamicTextFields(
              initialData: [
                {'title': _serverQuote.title},
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
            ),
            RequestedByAndDepartments(
              initialRequestedBy: _serverQuote.requestedBy,
              initialDepartment: _serverQuote.departmentCode,
              onRequestedBy: (id, code, name) =>
                  setState(() => _requestedBy = name),
              onDepartmentChange: (id, code, name) =>
                  setState(() => _departmentCode = code),
            ),
            SuppliersAndRFQStatusDropdown(
              initialStatus: _serverQuote.status,
              initialSupplier: _serverQuote.supplierId,
              initialSupplierRep: _serverQuote.supplierRepId,
              onStatusChanged: (s) => setState(() => _selectedRFQStatus = s),
              onSupplierChanged: (id, name) =>
                  setState(() => _selectedSupplierId = id),
              onContactPersonChanged: (id) =>
                  setState(() => _selectedSupplierRepId = id),
            ),
          ],
        ),

        FormGroupCard(
          children: [
            DynamicTextFields(
              showButton: true,
              title: 'Products / Services',
              fieldsConfig: _itemsFieldsConfig,
              initialData: _serverQuote.lineItems
                  .map((e) => e.toMap())
                  .toList(),
              onChanged: (List<Map<String, dynamic>> data) {
                if (isFormValid) setState(() {});
                _lineItems
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.map((e) => RFQLineItem.fromMap(e)));
              },
            ),
          ],
        ),

        FormGroupCard(
          title: 'Buyer Terms',
          children: [
            DeadlineAndDeliveryDateInput(
              labelDelivery: "Delivery date",
              labelDeadline: "Deadline date",
              initialDeadlineDate: _serverQuote.getDeadlineDate,
              initialDeliveryDate: _serverQuote.getDeliveryDate,
              onDeliveryChanged: (date) =>
                  setState(() => _selectedDeliveryDate = date),
              onDeadlineChanged: (date) =>
                  setState(() => _selectedDeadlineDate = date),
            ),
            CurrencyDropdown(
              initialCurrency: _serverQuote.currency,
              onCurrencyChanged: (s) => setState(() => _currency = s),
            ),
          ],
        ),

        FormGroupCard(
          title: 'Supplier Terms',
          children: [
            ValidityAndPayTermsDropdown(
              initialPayTerms: _serverQuote.paymentTerm,
              onPayTermsChanged: (s) =>
                  setState(() => _selectedPaymentTerm = s),
              initialValidity: _serverQuote.getValidityDate,
              onValidityChanged: (date) =>
                  setState(() => _selectedValidityDate = date),
            ),
            TaxModeSelector(
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
            ),
          ],
        ),

        FormGroupCard(
          children: [
            DynamicTextFields(
              title: 'Delivery Address and Notes',
              initialData: [
                {
                  'notes': _serverQuote.notes,
                  'deliveryAddress': _serverQuote.deliveryAddress,
                },
              ],
              fieldsConfig: [
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
              ],
              onChanged: (List<Map<String, dynamic>> data) {
                if (isFormValid) setState(() {});

                _addressAndNotes
                  ..clear() // Clear previous entries to prevent duplication
                  ..addAll(data.first);
              },
            ),
          ],
        ),

        context.confirmableActionButton(onPressed: _onSubmit),
        const SizedBox(height: 20.0),
      ],
    );
  }

  void _onSelectTaxMode(List<Map<String, dynamic>> data) {
    final selected = data.firstWhereOrNull((item) => item['selected'] == true);
    final selectedKey = selected?['key'];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _taxModeToApply = TaxModeHelper.fromString(selectedKey));
    });
  }

  Future<RequestForQuote> _applyTaxesToQuote(RequestForQuote quote) async {
    final taxMap = await GetTaxes.loadAllTaxRates();
    return quote.computeTaxAmounts(taxMap);
  }

  Future _getSupplier(String supplierId) async {
    final supplier = await GetSuppliers.bySupplierId(supplierId);
    return supplier.isEmpty ? null : supplier;
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
    final quoteWithTaxes = await _applyTaxesToQuote(_updatedQuote);
    final supplier = await _getSupplier(_updatedQuote.supplierId);
    if (supplier.isEmpty) return;

    // Log that details were printed
    if (mounted &&
        AuditTracker.shouldLog(
          id: _updatedQuote.id,
          type: DocType.prs,
          action: AuditAction.printed,
        )) {
      _updateHistory();
    }

    await RFQPrinter(quote: quoteWithTaxes, supplier: supplier).printRFQ();
  });

  /// Audit Log Entry (Tracking actions)
  void _updateHistory([AuditAction action = AuditAction.printed]) {
    final up = AuditProcurement<RequestForQuote>(
      documentId: _updatedQuote.id,
      log: {
        'history': [
          ..._updatedQuote.history.map((e) => e.toMap()), // keep old logs
          AuditLog(
            action: action,
            performedBy: _currentEmployeeId,
          ).toMap(), // new log
        ],
      },
    );
    _readBloc.add(up);
  }

  final _textFields = <(String, String, TextInputType)>[
    ('itemName', 'Item name', TextInputType.text),
    ('quantity', 'Quantity', TextInputType.number),
    ('unitPrice', 'Unit price', TextInputType.number),
    ('discount', 'Discount %', TextInputType.numberWithOptions(decimal: true)),
  ];

  get _itemsFieldsConfig => [
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
      hideField: _taxModeToApply != TaxMode.perLineTax,
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
