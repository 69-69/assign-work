import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/util/doc_type_enum.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/form_group_card.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/procurement/data/data_sources/remote/get_suppliers.dart';
import 'package:assign_erp/features/procurement/data/model/pr_to_rfq_converter_model.dart';
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_quote/pro_request_for_quote_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_quote/widget/form_inputs.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_quote/widget/rfq_printer.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_taxes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension RFQFormExtensions on BuildContext {
  /// [openRequestForQuoteForm] Opens the Request For Quote Form
  Future<void> openRFQForm() => _openRFQSheet(
    title: '[Purchase Requisition] → RFQ',
    body: const _PRToRFQStartForm(),
  );

  Future<void> openCreateRFQForm({PRToRFQConverter? initialPRData}) =>
      _openRFQSheet(
        size: 0.94,
        title: 'Create Request For Quote',
        body: _CreateRFQForm(initialPRData: initialPRData),
      );

  Future<void> _openRFQSheet({
    required String title,
    required Widget body,
    double? size,
  }) async {
    return openBottomSheet(
      isExpand: false,
      child: FormBottomSheet(initialSize: size, title: title, body: body),
    );
  }
}

class _PRToRFQStartForm extends StatelessWidget {
  const _PRToRFQStartForm();

  @override
  Widget build(BuildContext context) {
    return FormGroupCard(
      title: '[Purchase Requisition] → RFQ',
      children: [
        FindApprovedPurchaseRequisition(
          onValueChanged: (PRToRFQConverter approvedPR) {
            if (approvedPR.isNotEmpty) {
              _openRFQ(context, approvedPR);
            }
          },
          onPressed: () => _openRFQ(context),
        ),
      ],
    );
  }

  void _openRFQ(BuildContext context, [PRToRFQConverter? data]) {
    if (!context.mounted) return;
    // never close the bottom sheet before showing it - it will trigger error
    context.openCreateRFQForm(initialPRData: data);
  }
}

/// Create Request For Quote Form [_CreateRFQForm]
class _CreateRFQForm extends StatefulWidget {
  final PRToRFQConverter? initialPRData;

  const _CreateRFQForm({this.initialPRData});

  @override
  State<_CreateRFQForm> createState() => _CreateRFQFormState();
}

class _CreateRFQFormState extends State<_CreateRFQForm> {
  final _formKey = GlobalKey<FormState>();

  String _newRFQNumber = '';
  String _rfqTitle = '';
  String _currency = '';
  String _requestedBy = '';
  String _departmentCode = '';
  String _selectedSupplierId = '';
  String _selectedSupplierRepId = '';
  String? _selectedRFQStatus;
  DateTime? _selectedDeadlineDate;
  DateTime? _selectedDeliveryDate;

  // Add a list to manage line items
  final List<RFQLineItem> _lineItems = [];
  final Map<String, dynamic> _addressAndNotes = {};

  PRToRFQConverter? get _initialPRData => widget.initialPRData;
  // Disable FormFields if PR is not empty
  bool get _isDisabled => _initialPRData?.lineItems != null;

  bool get isFormValid => _formKey.currentState!.validate();

  String get _currentEmployeeId => context.employee!.employeeId;

  ProRequestForQuoteBloc get _readBloc =>
      context.read<ProRequestForQuoteBloc>();

  @override
  void initState() {
    super.initState();
    _generateRFQNumber();
  }

  void _generateRFQNumber() async {
    await DocType.rfq.getShortUID(
      onChanged: (s) {
        if (mounted) setState(() => _newRFQNumber = s);
      },
    );
  }

  RequestForQuote get _newQuote => RequestForQuote(
    /// [prNumber] FOREIGN KEY (purchase requisition) else its new RFQ
    prNumber: _initialPRData?.prNumber ?? 'N/A',
    title: _rfqTitle,
    requestedBy: _initialPRData?.requestedBy ?? _requestedBy,
    rfqNumber: _newRFQNumber,
    status: _selectedRFQStatus ?? '',
    departmentCode: _initialPRData?.departmentCode ?? _departmentCode,
    supplierId: _selectedSupplierId,
    supplierRepId: _selectedSupplierRepId,
    currency: _currency,
    deadline: _selectedDeadlineDate,
    deliveryDate: _selectedDeliveryDate,
    storeNumber: context.employee!.storeNumber,
    notes: _addressAndNotes['notes'],
    deliveryAddress: _addressAndNotes['deliveryAddress'],
    lineItems: List.from(_lineItems),
    createdBy: context.employee!.fullName,
    history: [
      AuditLog(action: AuditAction.created, performedBy: _currentEmployeeId),
    ],
  );

  void _onSubmit() {
    if (!isFormValid || _newQuote.isEmpty) {
      context.showAlertOverlay(
        'Please fill in all required fields',
        bgColor: kDangerColor,
      );
      return;
    }

    _readBloc.add(AddProcurement<RequestForQuote>(data: _newQuote));

    _confirmPrintoutDialog().then((_) => _resetForm());
  }

  void _resetForm() {
    if (mounted) {
      _formKey.currentState?.reset();
      _lineItems.clear();
      _addressAndNotes.clear();

      setState(() {
        _rfqTitle = '';
        _currency = '';
        _requestedBy = '';
        _departmentCode = '';
        _selectedSupplierId = '';
        _selectedRFQStatus = null;
        _selectedDeadlineDate = null;
        _selectedDeliveryDate = null;
      });
      _generateRFQNumber(); // get a new RFQ number
    }
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
        _buildRFQNumber(),
        FormGroupCard(
          title: 'Request for Quotes',
          children: [
            DynamicTextFields(
              initialData: [{}],
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
              initialRequestedBy: _initialPRData?.requestedBy,
              initialDepartment: _initialPRData?.departmentCode,
              onRequestedBy: (id, code, name) =>
                  setState(() => _requestedBy = name),
              onDepartmentChange: (id, code, name) =>
                  setState(() => _departmentCode = code),
              isDisabled: _initialPRData != null,
            ),
            SuppliersAndRFQStatusDropdown(
              initialSupplier: _selectedSupplierId,
              onStatusChanged: (s) => setState(() => _selectedRFQStatus = s),
              onSupplierChanged: (id, name) {
                if (isFormValid) setState(() => _selectedSupplierId = id);
              },
              onContactPersonChanged: (id) {
                if (isFormValid) {
                  setState(() => _selectedSupplierRepId = id);
                }
              },
            ),
          ],
        ),

        FormGroupCard(
          children: [
            DynamicTextFields(
              title: 'Products / Services',
              showButton: !_isDisabled,
              fieldsConfig: _itemsFieldsConfig,
              initialData:
                  _initialPRData?.lineItems.map((e) => e.toMap()).toList() ??
                  [{}],
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
              onDeliveryChanged: (date) =>
                  setState(() => _selectedDeliveryDate = date),
              onDeadlineChanged: (date) =>
                  setState(() => _selectedDeadlineDate = date),
            ),
            CurrencyDropdown(
              onCurrencyChanged: (s) => setState(() => _currency = s),
            ),
          ],
        ),

        FormGroupCard(
          children: [
            DynamicTextFields(
              title: 'Delivery Address and Notes',
              initialData: [{}],
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

        context.confirmableActionButton(
          label: 'Create Quote',
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  _buildRFQNumber() => Align(
    alignment: Alignment.topLeft,
    child: FittedBox(
      child: context.actionInfoButton(
        'Refresh RFQ Number',
        count: _newRFQNumber,
        bgColor: kPrimaryColor,
        isTotal: false,
        onPressed: _generateRFQNumber,
      ),
    ),
  );

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
    if (_newQuote.isEmpty) return;

    final quoteWithTaxes = await _applyTaxesToQuote(_newQuote);
    final supplier = await _getSupplier(_newQuote.supplierId);
    if (supplier.isEmpty) return;

    // Log that details were printed
    if (mounted &&
        AuditTracker.shouldLog(
          id: '${_newQuote.id}::$_currentEmployeeId',
          type: DocType.rfq,
          action: AuditAction.printed,
        )) {
      _updateHistory();
    }
    await RFQPrinter(quote: quoteWithTaxes, supplier: supplier).printRFQ();
  });

  /// Audit Log Entry (Tracking actions)
  void _updateHistory([AuditAction action = AuditAction.printed]) {
    final up = AuditProcurement<RequestForQuote>(
      documentId: _newQuote.id,
      log: {
        'history': [
          ..._newQuote.history.map((e) => e.toMap()), // keep old logs
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
  ];

  get _itemsFieldsConfig => [
    ..._textFields.map(
      (e) => FieldGroupConfig(
        key: e.$1,
        label: e.$2,
        type: e.$3,
        isDisabled: _isDisabled,
      ),
    ),
    FieldGroupConfig(
      key: 'category',
      label: 'Item Group (e.g. Office Supplies, IT)',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return ItemCategoryDropdown(
          isDisabled: _isDisabled,
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
    FieldGroupConfig(
      key: 'unitOfMeasure',
      label: 'Unit of Measure (e.g. box, kg)',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return UnitOfMeasureDropdown(
          isDisabled: _isDisabled,
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
    FieldGroupConfig(
      key: 'notes',
      label: 'Additional Notes (if any)...',
      isDisabled: _isDisabled,
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
    ),
  ];
}
