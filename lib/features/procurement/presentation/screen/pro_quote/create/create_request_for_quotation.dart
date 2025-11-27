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

  // Basic fields
  String _rfqNumber = '';
  String _rfqTitle = '';
  String _currency = '';
  String _requestedBy = '';
  String _departmentCode = '';
  String _supplierId = '';
  String _supplierRepId = '';
  String? _rfqStatus;
  // Dates
  DateTime? _deadlineDate;
  DateTime? _deliveryDate;

  /// Line Items & Additional Info
  final List<RFQLineItem> _lineItems = [];
  final Map<String, dynamic> _additionalInfo = {};

  /// Initial PR data if converting PR → RFQ
  PRToRFQConverter? get _initialPR => widget.initialPRData;

  /// Disable form fields if this RFQ originated from a PR
  bool get _isDisabled => _initialPR?.lineItems != null;

  bool get isFormValid => _formKey.currentState!.validate();

  /// Current employee info
  String get _employeeId => context.employee!.employeeId;
  String get _employeeName => context.employee!.fullName;
  String get _employeeStore => context.employee!.storeNumber;

  ProRequestForQuoteBloc get _bloc => context.read<ProRequestForQuoteBloc>();

  @override
  void initState() {
    super.initState();
    _generateRFQNumber();
  }

  void _generateRFQNumber() async {
    await DocType.rfq.getShortUID(
      onChanged: (s) {
        if (mounted) setState(() => _rfqNumber = s);
      },
    );
  }

  /// Construct RequestForQuote object
  RequestForQuote get _newRFQ => RequestForQuote(
    /// [prNumber] FOREIGN KEY (purchase requisition) else its new RFQ
    prNumber: _initialPR?.prNumber ?? 'N/A',
    storeNumber: _employeeStore,
    title: _rfqTitle,
    requestedBy: _initialPR?.requestedBy ?? _requestedBy,
    rfqNumber: _rfqNumber,
    status: _rfqStatus ?? '',
    departmentCode: _initialPR?.departmentCode ?? _departmentCode,
    supplierId: _supplierId,
    supplierRepId: _supplierRepId,
    currency: _currency,
    deadline: _deadlineDate,
    deliveryDate: _deliveryDate,
    notes: _additionalInfo['notes'],
    deliveryAddress: _additionalInfo['deliveryAddress'],
    lineItems: List.from(_lineItems),
    createdBy: _employeeName,
    history: [AuditLog(action: AuditAction.created, performedBy: _employeeId)],
  );

  void _onSubmit() {
    if (!isFormValid || _newRFQ.isEmpty) {
      context.showAlertOverlay(
        'Please fill in all required fields',
        bgColor: kDangerColor,
      );
      return;
    }

    _bloc.add(AddProcurement<RequestForQuote>(data: _newRFQ));

    _confirmPrintoutDialog().then((_) => _resetForm());
  }

  void _resetForm() {
    if (mounted) {
      _formKey.currentState?.reset();
      _lineItems.clear();
      _additionalInfo.clear();

      setState(() {
        _rfqTitle = '';
        _currency = '';
        _requestedBy = '';
        _departmentCode = '';
        _supplierId = '';
        _rfqStatus = null;
        _deadlineDate = null;
        _deliveryDate = null;
      });
      _generateRFQNumber(); // fresh RFQ number
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
        _RFQFormConfig.buildRFQNumber(context, _rfqNumber, _generateRFQNumber),
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

        FormGroupCard(children: [_buildDeliveryAndNotes()]),

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
  DynamicTextFields _buildDeliveryAndNotes() {
    return DynamicTextFields(
      title: 'Delivery Address and Notes',
      initialData: [{}],
      fieldsConfig: _RFQFormConfig.deliveryFields(),
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _additionalInfo
          ..clear() // Clear previous entries to prevent duplication
          ..addAll(data.first);
      },
    );
  }

  CurrencyDropdown _buildCurrency() {
    return CurrencyDropdown(
      onCurrencyChanged: (s) => setState(() => _currency = s),
    );
  }

  DeadlineAndDeliveryDateInput _buildDates() {
    return DeadlineAndDeliveryDateInput(
      labelDelivery: "Delivery date",
      labelDeadline: "Deadline date",
      onDeliveryChanged: (date) => setState(() => _deliveryDate = date),
      onDeadlineChanged: (date) => setState(() => _deadlineDate = date),
    );
  }

  DynamicTextFields _buildLineItems() {
    return DynamicTextFields(
      title: 'Products / Services',
      showButton: !_isDisabled,
      fieldsConfig: _RFQFormConfig.itemsFields(_isDisabled),
      fullWidthKey: 'itemName',
      initialData: _initialPR?.lineItems.map((e) => e.toMap()).toList() ?? [{}],
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _lineItems
          ..clear() // Clear previous entries to prevent duplication
          ..addAll(data.map((e) => RFQLineItem.fromMap(e)));
      },
    );
  }

  SuppliersAndRFQStatusDropdown _buildSupplierAndStatus() {
    return SuppliersAndRFQStatusDropdown(
      initialSupplier: _supplierId,
      onStatusChanged: (s) => setState(() => _rfqStatus = s),
      onSupplierChanged: (id, name) {
        if (isFormValid) setState(() => _supplierId = id);
      },
      onContactPersonChanged: (id) {
        if (isFormValid) {
          setState(() => _supplierRepId = id);
        }
      },
    );
  }

  RequestedByAndDepartments _buildRequesterAndDepartment() {
    return RequestedByAndDepartments(
      initialRequestedBy: _initialPR?.requestedBy,
      initialDepartment: _initialPR?.departmentCode,
      onRequestedBy: (id, code, name) => setState(() => _requestedBy = name),
      onDepartmentChange: (id, code, name) =>
          setState(() => _departmentCode = code),
      isDisabled: _initialPR != null,
    );
  }

  DynamicTextFields _buildTitleField() {
    return DynamicTextFields(
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
    );
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

    final quoteWithTaxes = await _RFQFormConfig.applyTaxesToQuote(_newRFQ);
    final supplier = await _RFQFormConfig.getSupplier(_newRFQ.supplierId);
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
    await RFQPrinter(quote: quoteWithTaxes, supplier: supplier).printRFQ();
  });

  /// Audit Log Entry (Tracking actions)
  void _updateHistory([AuditAction action = AuditAction.printed]) {
    final up = _RFQFormConfig.updateHistory(
      action: action,
      quote: _newRFQ,
      empId: _employeeId,
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

  /// RFQ Number
  static Widget buildRFQNumber(
    BuildContext context,
    String count,
    void Function()? onPressed,
  ) => Align(
    alignment: Alignment.topLeft,
    child: FittedBox(
      child: context.actionInfoButton(
        'Refresh RFQ Number',
        count: count,
        bgColor: kPrimaryColor,
        isTotal: false,
        onPressed: onPressed,
      ),
    ),
  );

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
  static List<FieldGroupConfig> itemsFields(bool isDisabled) {
    return [
      ..._textFields.map(
        (e) => FieldGroupConfig(
          key: e.$1,
          label: e.$2,
          type: e.$3,
          isDisabled: isDisabled,
        ),
      ),
      FieldGroupConfig(
        key: 'category',
        label: 'Item Group (e.g. Office Supplies, IT)',
        type: TextInputType.text,
        widgetType: FieldWidgetType.custom,
        customBuilder: ({required initialData, required onChanged}) {
          return ItemCategoryDropdown(
            isDisabled: isDisabled,
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
            isDisabled: isDisabled,
            initialValue: initialData,
            onChanged: (String? selected) => onChanged(selected),
          );
        },
      ),
      /*FieldGroupConfig(
      key: 'notes',
      label: 'Additional Notes (if any)...',
      isDisabled: _isDisabled,
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
      ];
}
