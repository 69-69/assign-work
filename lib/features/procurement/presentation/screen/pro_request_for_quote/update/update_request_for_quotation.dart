import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/address_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
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
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_link_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_rfq/pro_request_for_quote_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/widget/rfq_form_inputs.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/widget/rfq_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateRequestForQuotationForm on BuildContext {
  Future openUpdateRFQ({required RequestForQuote rfq}) async {
    if (rfq.id.isEmpty) return;

    return await openBottomSheet(
      isExpand: false,
      child: BottomSheetScaffold(
        title: 'Edit Request For Quote',
        subtitle:
            '${rfq.rfqNumber.toUpperAll} (${rfq.lineItems.first.getType})',
        body: _UpdateRequestForQuote(rfq: rfq),
      ),
    );
  }
}

class _UpdateRequestForQuote extends StatefulWidget {
  final RequestForQuote rfq;

  const _UpdateRequestForQuote({required this.rfq});

  @override
  State<_UpdateRequestForQuote> createState() => _UpdateRequestForQuoteState();
}

class _UpdateRequestForQuoteState extends State<_UpdateRequestForQuote> {
  final _formKey = GlobalKey<FormState>();

  // Basic fields
  bool _isSubmitting = false;
  String? _rfqTitle;
  String? _rfqStatus;
  String? _requestedBy;
  String? _currencyCode;
  String? _costCenterCode;
  String? _departmentCode;
  bool? _autoConvertRfq; // auto-convert PO when RFQ is Accepted
  // Dates

  /// Line Items & Additional Info
  final List<LineItem> _lineItems = [];
  final Map<String, dynamic> _buyerTerms = {};
  final List<SupplierLink> _supplierLinks = [];
  final List<AddressInfo> _shippingAddress = [];

  RequestForQuote get _serverRFQ => widget.rfq;

  String get _lineItemType => _serverRFQ.lineItems.first.getType;

  bool get isFormValid => _formKey.currentState?.validate() ?? false;

  /// Current employee info
  String get _employeeId => context.employee!.employeeId;

  String get _employeeName => context.employee!.fullName;

  ProRequestForQuoteBloc get _bloc => context.read<ProRequestForQuoteBloc>();

  AuditAction get _action => AuditActionUtil.isApproved(_rfqStatus)
      ? AuditAction.approved
      : AuditAction.updated;

  @override
  void initState() {
    super.initState();
    /*_buyerTerms.addAll({
      'notes': _serverRFQ.notes,
      'buyerContactPerson': _serverRFQ.buyerContactPersonId,
      'deadline': _serverRFQ.getDeadlineDate,
      'expectedDate': _serverRFQ.getExpectedDate,
    });
    _lineItems.addAll(_serverRFQ.lineItems);
    _supplierLinks.addAll(_serverRFQ.supplierLinks);
    */
  }

  /// Construct Request For Quote object
  RequestForQuote get _updatedRFQ {
    final status = _rfqStatus ?? _serverRFQ.getRFQStatus;

    return _serverRFQ.copyWith(
      title: _rfqTitle ?? _serverRFQ.title,
      autoConvertRfq: _autoConvertRfq ?? _serverRFQ.autoConvertRfq,
      requestedBy: _requestedBy ?? _serverRFQ.requestedBy,
      status: WorkflowStatusUtil.fromString(status),
      costCenterCode: _costCenterCode ?? _serverRFQ.costCenterCode,
      currencyCode: _currencyCode ?? _serverRFQ.currencyCode,
      departmentCode: _departmentCode ?? _serverRFQ.departmentCode,
      supplierLinks: List.from(_supplierLinks),
      lineItems: List.from(_lineItems),
      notes: _buyerTerms['notes'],
      shippingAddress: _shippingAddress.first,
      deadline: toDateTimeFn(_buyerTerms['deadline']),
      expectedDate: toDateTimeFn(_buyerTerms['expectedDate']),
      buyerContactPersonId: _buyerTerms['buyerContactPerson'],
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

  void _onSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      if (!isFormValid || _lineItems.isNullOrEmpty) return;

      _bloc.add(
        UpdateProcurement<RequestForQuote>(
          documentId: _updatedRFQ.id,
          data: _updatedRFQ,
        ),
      );

      context.showAlertOverlay(
        'Changes successfully saved',
        onCallback: () => Navigator.pop(context),
      );
      await _confirmPrintoutDialog();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        FormGroupCard(
          title: '1. Quotation Overview',
          subTitle: '\nGeneral RFQ info, requester details, & document status.',
          children: [
            _buildAutoCreateAndStatus(),
            const HorizontalDivider(space: 0.4),
            _buildTitleField(),
            _buildRequesterAndDepartment(),
          ],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '2. Accounting & Cost Assignment',
          subTitle: '\nCost center, currency, & financial allocation details.',
          children: [_buildCurrencyAndCostCenter()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '3. ${_lineItemType.toSentence} Line Items',
          subTitle:
              '\nYou can add more ${_lineItemType}s to the Quotation (RFQ).',
          children: [_buildLineItems()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '4. Suppliers Invitation',
          subTitle: '\nSelect & invite vendors to submit quotations.',
          children: [_buildSuppliers()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '5. Shipping Address',
          subTitle:
              '\nSpecify the delivery location for quoted ${_lineItemType}s.',
          children: [_buildShippingAddress()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '6. Contacts & Submission Deadlines',
          subTitle: '\nBuyer contact information & quotation submission dates.',
          children: [_buildBuyerTerms()],
        ),

        const SizedBox(height: 20.0),
        context.confirmableActionButton(onPressed: _onSubmit),
        const SizedBox(height: 20.0),
      ],
    );
  }

  AutoCreateAndRFQStatus _buildAutoCreateAndStatus() {
    return AutoCreateAndRFQStatus(
      initialStatus: _serverRFQ.getRFQStatus,
      onStatusChanged: (s) => setState(() => _rfqStatus = s),
      isSelected: _autoConvertRfq ?? _serverRFQ.autoConvertRfq,
      onAutoConvertChanged: (bool? v) {
        setState(() => _autoConvertRfq = v ?? false);
      },
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

  CurrencyAndCostCenterDepartment _buildCurrencyAndCostCenter() {
    return CurrencyAndCostCenterDepartment(
      initialCurrency: _serverRFQ.currencyCode,
      initialCostCenter: _serverRFQ.costCenterCode,
      onCurrencyChanged: (v) => setState(() => _currencyCode = v),
      onCostCenterChange: (id, code, name) =>
          setState(() => _costCenterCode = code),
    );
  }

  Widget _buildLineItems() {
    return DynamicTextFields(
      showButton: true,
      fullWidthKey: 'description',
      fieldsConfig: RFQFormInputs.fields(_lineItemType),
      initialData: _serverRFQ.lineItems.map((e) => e.toMap(true)).toList(),
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        // Update the ProLineItem list
        RFQFormInputs.updateListFromData<LineItem>(
          _lineItems,
          map: data,
          fromMap: (map, id) => LineItem.fromMap(map),
        );
      },
    );
  }

  DynamicTextFields _buildSuppliers() {
    return DynamicTextFields(
      showButton: true,
      fullWidthKey: 'supplierLinks',
      fieldsConfig: RFQFormInputs.suppliersFields,
      initialData: _serverRFQ.supplierLinks
          .map((e) => {'supplierLinks': e.toMap(), 'status': e.getStatus})
          .toList(),
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        final supplierLinks = data.map((e) {
          final copy = Map<String, dynamic>.from(e['supplierLinks'] ?? {});
          // Merge the supplier status(like: invited, declined) from the top-level map
          copy['status'] = e['status'];
          return copy;
        }).toList();

        // Update the RFQSupplier list
        RFQFormInputs.updateListFromData<SupplierLink>(
          _supplierLinks,
          map: supplierLinks,
          fromMap: (map, id) => SupplierLink.fromMap(map),
        );
      },
    );
  }

  DynamicTextFields _buildBuyerTerms() {
    return DynamicTextFields(
      initialData: [
        {
          'notes': _serverRFQ.notes,
          'deadline': _serverRFQ.getDeadlineDate,
          'expectedDate': _serverRFQ.getExpectedDate,
          'buyerContactPerson': _serverRFQ.buyerContactPersonId,
        },
      ],
      fullWidthKey: 'buyerContactPerson',
      fieldsConfig: RFQFormInputs.buyerTermsFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _buyerTerms
          ..clear()
          ..addAll(data.first);
      },
    );
  }

  // Addresses (e.g., Buyer Shipping Address)
  DynamicTextFields _buildShippingAddress() {
    return DynamicTextFields(
      initialData: [_serverRFQ.shippingAddress?.toMap() ?? {}], // empty form
      fieldsConfig: RFQFormInputs.shippingAddressFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        // Update the address list
        RFQFormInputs.updateListFromData<AddressInfo>(
          _shippingAddress,
          map: data,
          fromMap: (map, id) => AddressInfo.fromMap(map),
        );
      },
    );
  }

  Future<void> _confirmPrintoutDialog() async {
    final isConfirmed = await context.confirmAction<bool>(
      const Text('Would you like to print this Request for Quote (RFQ)?'),
      title: "Print RFQ",
      onAcceptLabel: "Print",
      onRejectLabel: "Cancel",
    );

    if (mounted && isConfirmed == true) {
      // Show progress dialog while loading data
      await context.progressBarDialog(
        request: _printout(),
        onSuccess: (_) {
          context.showAlertOverlay('RFQ Printout successful');
        },
        onError: (e) => context.showAlertOverlay(
          'RFQ printout failed',
          bgColor: kDangerColor,
        ),
      );
    }
  }

  Future<dynamic> _printout() => Future.delayed(kRProgressDelay, () async {
    final rfqWithTaxes = await RFQFormInputs.applyTaxesToRFQ(_updatedRFQ);
    final supplier = await RFQFormInputs.getSupplier(
      _updatedRFQ.supplierLinks.first.supplierId,
    );
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

    await RFQPrinter(rfq: rfqWithTaxes, supplier: supplier).printRFQ();
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
