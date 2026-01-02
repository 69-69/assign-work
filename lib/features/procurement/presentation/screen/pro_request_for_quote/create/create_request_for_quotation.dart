import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/workflow_status.dart';
import 'package:assign_erp/core/network/data_sources/models/address_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/doc_type_enum.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/material_or_service_choice.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/procurement/data/model/request_for_quote_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_link_model.dart';
import 'package:assign_erp/features/procurement/data/model/workflow_converter_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_rfq/pro_request_for_quote_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/widget/rfq_form_inputs.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_request_for_quote/widget/rfq_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension RFQFormExtensions on BuildContext {
  /// [openRFQForm] Opens the Request For Quote Form
  Future<void> openRFQForm() => openBottomSheet(
    isExpand: false,
    child: FindApprovedPR(
      onValueChanged: (WorkflowConverter approvedPR) async {
        if (mounted && approvedPR.isNotEmpty) {
          await openCreateRFQForm(data: approvedPR);
        }
      },
      onCreateNewRFQ: () async {
        final lineItemType = await openMaterialOrServiceToggle('RFQ');
        if (mounted && lineItemType != null) {
          await openCreateRFQForm(type: lineItemType);
        }
      },
    ),
  );

  Future<void> openCreateRFQForm({WorkflowConverter? data, String? type}) =>
      openBottomSheet(
        isExpand: false,
        child: BottomSheetScaffold(
          initialSize: 0.94,
          title: 'Create Request For Quote',
          body: _CreateRFQForm(initialPRData: data, lineItemType: type),
        ),
      );
}

/// Create Request For Quote Form [_CreateRFQForm]
class _CreateRFQForm extends StatefulWidget {
  final String? lineItemType;
  final WorkflowConverter? initialPRData;

  const _CreateRFQForm({this.initialPRData, this.lineItemType});

  @override
  State<_CreateRFQForm> createState() => _CreateRFQFormState();
}

class _CreateRFQFormState extends State<_CreateRFQForm> {
  String? get _lineItemType =>
      widget.lineItemType ?? _initialPR?.lineItems.first.getTypeLabel;
  final _formKey = GlobalKey<FormState>();
  Key _formResetKey = UniqueKey();

  // Basic fields
  String? _rfqStatus;
  String _rfqTitle = '';
  String _currencyCode = '';
  String _rfqNumber = '';
  String _requestedBy = '';
  bool _autoCreateRfq = true; // auto-convert PO when RFQ is Accepted
  bool _isSubmitting = false;
  String _costCenterCode = '';
  String _departmentCode = '';
  bool _useDefaultAddress = false;

  /// Line Items & Additional Info
  final List<LineItem> _lineItems = [];
  final Map<String, dynamic> _buyerTerms = {};
  final List<SupplierLink> _supplierLinks = [];
  final List<AddressInfo> _shippingAddress = [];

  /// Initial PR data if converting PR → RFQ
  WorkflowConverter? get _initialPR => widget.initialPRData;

  /// Disable form fields if converting PR to RFQ & PR has line items
  bool get _isDisabled => _initialPR?.lineItems != null;

  bool get isFormValid => _formKey.currentState!.validate();

  /// Current employee info
  String get _employeeId => context.employee!.employeeId;
  String get _employeeName => context.employee!.fullName;
  String get _employeeStore => context.employee!.storeNumber;

  ProRequestForQuoteBloc get _bloc => context.read<ProRequestForQuoteBloc>();

  void _generateRFQNumber() async {
    await DocType.rfq.getShortUID(
      onChanged: (s) {
        if (mounted) setState(() => _rfqNumber = s);
      },
    );
  }

  Future<void> _getDefaultShippingAddress() async {
    if (!_useDefaultAddress) {
      setState(() => _shippingAddress.clear());
      return;
    }

    final shippingAddress = await RFQFormInputs.getCompanyAddress();

    if (!mounted || shippingAddress == null) return;

    setState(() {
      _shippingAddress
        ..clear()
        ..add(shippingAddress);
    });
  }

  /// Construct RequestForQuote object
  RequestForQuote get _newRFQ => RequestForQuote(
    /// [prNumber] FOREIGN KEY (purchase requisition) else its new RFQ (Not generated from PR)
    prNumber: _initialPR?.workflowNumber ?? 'N/A',
    rfqNumber: _rfqNumber,
    storeNumber: _employeeStore,
    autoConvertRfq: _autoCreateRfq,
    title: _rfqTitle,
    status: WorkflowStatusHelper.fromString(_rfqStatus ?? ''),
    supplierLinks: List.from(_supplierLinks),
    currencyCode: _currencyCode,
    notes: _buyerTerms['notes'],
    lineItems: List.from(_lineItems),
    shippingAddress: _shippingAddress.first,
    deadline: toDateTimeFn(_buyerTerms['deadline']),
    expectedDate: toDateTimeFn(_buyerTerms['expectedDate']),
    buyerContactPersonId: _buyerTerms['buyerContactPerson'],
    requestedBy: _initialPR?.requestedBy ?? _requestedBy,
    costCenterCode: _initialPR?.costCenterCode ?? _costCenterCode,
    departmentCode: _initialPR?.departmentCode ?? _departmentCode,
    createdBy: _employeeName,
    history: [
      AuditLog(
        action: AuditAction.created,
        actionBy: _employeeId,
        statusAfterAction: _rfqStatus,
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

      _bloc.add(AddProcurement<RequestForQuote>(data: _newRFQ));

      context.showAlertOverlay(
        'RFQ successfully created',
        onCallback: () => _resetForm(),
      );

      await _confirmPrintoutDialog();
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _formResetKey = UniqueKey(); // 💥 full rebuild

      _isSubmitting = false;
      _rfqTitle = '';
      _autoCreateRfq = false;
      _supplierLinks.clear();
      _requestedBy = '';
      _currencyCode = '';
      _costCenterCode = '';
      _departmentCode = '';
      _lineItems.clear();
      _shippingAddress.clear();
      _rfqStatus = null;
      _buyerTerms.clear();
      _useDefaultAddress = false;
      _lineItems.clear();
      _supplierLinks.clear();
      _shippingAddress.clear();
      _buyerTerms.clear();
      _useDefaultAddress = false;
    });

    _generateRFQNumber();
  }

  @override
  void initState() {
    _generateRFQNumber();

    _getDefaultShippingAddress();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: KeyedSubtree(key: _formResetKey, child: _buildBody()),
    );
  }

  Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        RFQFormInputs.buildRFQNumber(context, _rfqNumber, _generateRFQNumber),
        FormGroupCard(
          title: '1. Quotation Overview',
          children: [
            _buildAutoCreateAndStatus(),
            const HorizontalDivider(space: 0.4),
            _buildTitleField(),
            _buildRequesterAndDepartment(),
          ],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '2. Cost Center',
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
          title: '4. Invite Suppliers',
          subTitle:
              '\nYou can invite additional suppliers/vendors to the Quotation (RFQ).',
          children: [_buildSuppliers()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '5. Buyer\'s Terms',
          children: [_buildBuyerTerms()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '6. Shipping Address',
          children: [
            SizedBox(
              width: context.dynamicWidth(0.48),
              child: UseDefaultAddress(
                isChecked: _useDefaultAddress,
                onChanged: (v) async {
                  if (!mounted) return;

                  setState(() => _useDefaultAddress = v);
                  await _getDefaultShippingAddress();
                },
              ),
            ),
            const HorizontalDivider(isORSeparator: true, space: 0.4),

            _buildShippingAddress(),
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

  // -------------------------
  // Section Builders
  // -------------------------

  DynamicTextFields _buildLineItems() {
    return DynamicTextFields(
      showButton: !_isDisabled,
      fullWidthKey: 'description',
      fieldsConfig: RFQFormInputs.fields(
        _lineItemType ?? '',
        isDisabled: _isDisabled,
        keysToExclude: [
          'discount',
          'unitPrice',
          'serviceRate',
          'limitAmount',
          'limitQuantity',
          'taxCodes',
          'leadTimDays',
        ],
      ),
      initialData:
          _initialPR?.lineItems.map((e) => e.toMap(true)).toList() ?? [{}],
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        // Update the ProLineItem list
        RFQFormInputs.updateListFromData<LineItem>(
          _lineItems,
          map: data,
          fromMap: (map, id) =>
              LineItem.fromMap(map, id: id, lineType: _lineItemType),
        );
      },
    );
  }

  // Addresses (e.g., Buyer Shipping Address)
  DynamicTextFields _buildShippingAddress() {
    return DynamicTextFields(
      key: Key('default_${_useDefaultAddress.hashCode}'),
      initialData: _shippingAddress.isNotEmpty
          ? [_shippingAddress.first.toMap()]
          : [{}], // empty form
      fieldsConfig: RFQFormInputs.shippingAddressFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        // Update the address list
        RFQFormInputs.updateListFromData<AddressInfo>(
          _shippingAddress,
          map: data,
          fromMap: (map, id) => AddressInfo.fromMap(map, id: id),
        );
      },
    );
  }

  DynamicTextFields _buildBuyerTerms() {
    return DynamicTextFields(
      initialData: [{}],
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

  DynamicTextFields _buildSuppliers() {
    return DynamicTextFields(
      initialData: [{}],
      showButton: true,
      fullWidthKey: 'supplierLinks',
      fieldsConfig: RFQFormInputs.suppliersFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        final supplierLinks = data.map((e) {
          final copy = Map<String, dynamic>.from(e['supplierLinks'] ?? {});
          // Merge the status from the top-level map
          copy['status'] = e['status'];
          return copy;
        }).toList();

        // Update the RFQSupplier list
        RFQFormInputs.updateListFromData<SupplierLink>(
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

  AutoCreateAndRFQStatus _buildAutoCreateAndStatus() {
    return AutoCreateAndRFQStatus(
      onStatusChanged: (s) => setState(() => _rfqStatus = s),
      isSelected: _autoCreateRfq,
      onAutoConvertChanged: (bool? v) {
        setState(() => _autoCreateRfq = v ?? false);
      },
    );
  }

  RequestedByAndDepartments _buildRequesterAndDepartment() {
    return RequestedByAndDepartments(
      initialRequestedBy: _initialPR?.requestedBy,
      initialDepartment: _initialPR?.departmentCode,
      onRequestedChanged: (id, code, name) =>
          setState(() => _requestedBy = name),
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

    final quoteWithTaxes = await RFQFormInputs.applyTaxesToQuote(_newRFQ);
    final supplier = await RFQFormInputs.getSupplier(
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
    final up = RFQFormInputs.updateHistory(
      action: action,
      rfq: _newRFQ,
      empId: _employeeId,
    );
    _bloc.add(up);
  }
}
