import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/workflow_status.dart';
import 'package:assign_erp/core/network/data_sources/models/address_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/doc_type_enum.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/material_or_service_choice.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/procurement/data/model/pro_purchase_order_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_link_model.dart';
import 'package:assign_erp/features/procurement/data/model/workflow_converter_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_po/pro_purchase_order_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_order/widget/po_form_inputs.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_order/widget/po_printer.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension POFormExtensions on BuildContext {
  /// [openPOForm] Opens the Purchase Order Form
  Future<void> openPOForm() => openBottomSheet(
    isExpand: false,
    child: FindApprovedRFQ(
      onValueChanged: (WorkflowConverter approvedPR) async {
        if (mounted && approvedPR.isNotEmpty) {
          await openCreatePOForm(data: approvedPR);
        }
      },
      onCreateNewPO: () async {
        final lineItemType = await openMaterialOrServiceToggle('PO');
        if (mounted && lineItemType != null) {
          await openCreatePOForm(type: lineItemType);
        }
      },
    ),
  );

  Future<void> openCreatePOForm({WorkflowConverter? data, String? type}) =>
      openBottomSheet(
        isExpand: false,
        child: BottomSheetScaffold(
          initialSize: 0.94,
          title: 'Create Purchase Order',
          body: _CreatePOForm(initialRFQData: data, lineItemType: type),
        ),
      );
}

/// Create Purchase Order Form [_CreatePOForm]
class _CreatePOForm extends StatefulWidget {
  final String? lineItemType;
  final WorkflowConverter? initialRFQData;

  const _CreatePOForm({this.initialRFQData, this.lineItemType});

  @override
  State<_CreatePOForm> createState() => _CreatePOFormState();
}

class _CreatePOFormState extends State<_CreatePOForm> {
  String? get _lineItemType =>
      widget.lineItemType ?? _initialRFQ?.lineItems.first.getTypeLabel;
  final _formKey = GlobalKey<FormState>();
  Key _formResetKey = UniqueKey();

  // Basic fields
  bool _isSubmitting = false;
  String _costCenterCode = '';
  String _poNumber = '';
  String _currencyCode = '';
  String _requestedBy = '';
  String _paymentTerm = '';
  String _paymentMethod = '';
  String? _poStatus;
  final List<SupplierLink> _supplierLinks = [];
  // Dates
  DateTime? _deliveryDate;

  /// Line Items & Additional Info
  final List<LineItem> _lineItems = [];
  final List<AddressInfo> _addresses = [];
  final Map<String, dynamic> _payments = {};
  final Map<String, dynamic> _additionalInfo = {};

  /// Initial RFQ data if converting RFQ → PO
  WorkflowConverter? get _initialRFQ => widget.initialRFQData;

  /// Disable form fields if converting RFQ to PO & RFQ has line items
  bool get _isDisabled => _initialRFQ?.lineItems != null;

  bool get isFormValid => _formKey.currentState!.validate();

  /// Current employee info
  Employee? get _employee => context.employee;
  String get _employeeId => _employee!.employeeId;
  String get _employeeName => _employee!.fullName;
  String get _employeeStore => _employee!.storeNumber;

  ProPurchaseOrderBloc get _bloc => context.read<ProPurchaseOrderBloc>();

  @override
  void initState() {
    super.initState();
    _generatePONumber();
  }

  void _generatePONumber() async {
    await DocType.pOrder.getShortUID(
      onChanged: (s) {
        if (mounted) setState(() => _poNumber = s);
      },
    );
  }

  /// Construct ProPurchaseOrder object
  ProPurchaseOrder get _newPO => ProPurchaseOrder(
    /// [rfqNumber] FOREIGN KEY (Request For Quote) else its 'new PO' (Not generated from RFQ)
    rfqNumber: _initialRFQ?.workflowNumber ?? 'N/A',
    poNumber: _poNumber,
    storeNumber: _employeeStore,

    status: WorkflowStatusHelper.fromString(_poStatus ?? ''),
    supplierLink: _supplierLinks.first,
    requestedBy: _initialRFQ?.requestedBy ?? _requestedBy,

    costCenterCode: _initialRFQ?.costCenterCode ?? _costCenterCode,
    currencyCode: _currencyCode,

    paymentTerm: _initialRFQ?.paymentTerm ?? _paymentTerm,
    paymentMethod: _paymentMethod,

    addresses: List.from(_addresses),

    notes: _additionalInfo['notes'],
    termsAndConditions: _additionalInfo['termsAndConditions'],

    lineItems: List.from(_lineItems),

    deliveryDate: _deliveryDate,
    createdBy: _employeeName,
    history: [
      AuditLog(
        action: AuditAction.created,
        actionBy: _employeeId,
        statusAfterAction: _poStatus,
      ),
    ],
  );

  void _onSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      if (!isFormValid || _newPO.isNullOrEmpty) {
        context.showAlertOverlay(
          'Please enter all required fields',
          bgColor: kDangerColor,
        );
        return;
      }

      _bloc.add(AddProcurement<ProPurchaseOrder>(data: _newPO));

      context.showAlertOverlay(
        'PO successfully created',
        onCallback: () => _resetForm(),
      );

      await _confirmPrintoutDialog();
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _formKey.currentState?.reset();
        _formResetKey = UniqueKey();
        _isSubmitting = false;
        _currencyCode = '';
        _poNumber = '';
        _requestedBy = '';
        _payments.clear();
        _addresses.clear();
        _supplierLinks.clear();
        _additionalInfo.clear();
        _poStatus = null;
        _deliveryDate = null;
      });
      _generatePONumber(); // fresh RFQ number
    }
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
        POFormInputs.buildPONumber(context, _poNumber, _generatePONumber),
        FormGroupCard(
          title: 'Purchase Order Overview',
          children: [_buildPOStatusAndRequestedBy(), _buildSupplier()],
        ),

        FormGroupCard(
          title: 'Cost Center',
          children: [_buildCurrencyAndCostCenter()],
        ),

        FormGroupCard(
          title: '${_lineItemType.toSentence} Line Items',
          subTitle:
              '\nYou can add more ${_lineItemType}s to the purchase order (PO).',
          children: [_buildLineItems()],
        ),

        FormGroupCard(
          title: 'Payment & Terms',
          children: [_buildPayMethodAndTerms()],
        ),

        FormGroupCard(
          title: 'Addresses',
          subTitle: '\nYou can add multiple addresses: Billing, Shipping, etc.',
          children: [_buildAddresses()],
        ),

        FormGroupCard(
          title: 'Notes / T&C',
          children: [_buildTermsAndConditions(), _buildDeliveryDate()],
        ),

        const SizedBox(height: 20.0),
        context.confirmableActionButton(
          label: 'Create PO',
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  // -------------------------
  // Section Builders
  // -------------------------
  DynamicTextFields _buildTermsAndConditions() {
    return DynamicTextFields(
      initialData: [{}],
      fieldsConfig: POFormInputs.deliveryFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        _additionalInfo
          ..clear() // Clear previous entries to prevent duplication
          ..addAll(data.first);
      },
    );
  }

  // Addresses (e.g., Billing, Shipping Address)
  DynamicTextFields _buildAddresses() {
    return DynamicTextFields(
      initialData: [{}],
      showButton: true,
      fieldsConfig: POFormInputs.addressFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        // Update the address list
        POFormInputs.updateListFromData<AddressInfo>(
          _addresses,
          map: data,
          fromMap: (map, id) => AddressInfo.fromMap(map, id: id),
        );
      },
    );
  }

  DeliveryDate _buildDeliveryDate() {
    return DeliveryDate(
      labelDelivery: "Delivery date",
      onDeliveryChanged: (date) => setState(() => _deliveryDate = date),
    );
  }

  DynamicTextFields _buildLineItems() {
    return DynamicTextFields(
      showButton: !_isDisabled,
      fullWidthKey: 'description',
      fieldsConfig: POFormInputs.fields(
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
          _initialRFQ?.lineItems.map((e) => e.toMap(true)).toList() ?? [{}],
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        // Update the ProLineItem list
        POFormInputs.updateListFromData<LineItem>(
          _lineItems,
          map: data,
          fromMap: (map, id) =>
              LineItem.fromMap(map, id: id, lineType: _lineItemType),
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

  POStatusAndRequestedBy _buildPOStatusAndRequestedBy() {
    return POStatusAndRequestedBy(
      onStatusChanged: (s) => setState(() => _poStatus = s),
      onRequestedChanged: (id, code, name) => setState(() => _requestedBy = id),
    );
  }

  // Only a single supplier is allowed for a PO
  DynamicTextFields _buildSupplier() {
    return DynamicTextFields(
      initialData: [{}],
      showButton: false,
      fullWidthKey: 'supplierLinks',
      fieldsConfig: POFormInputs.suppliersFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (isFormValid) setState(() {});

        final supplierLinks = data.map((e) {
          final copy = Map<String, dynamic>.from(e['supplierLinks'] ?? {});
          // Merge the status from the top-level map
          copy['status'] = e['status'];
          return copy;
        }).toList();

        // Update the RFQSupplier list
        POFormInputs.updateListFromData<SupplierLink>(
          _supplierLinks,
          map: supplierLinks,
          fromMap: (map, id) => SupplierLink.fromMap(map, id: id),
        );
      },
    );
  }

  PayMethodAndTermsDropdown _buildPayMethodAndTerms() {
    return PayMethodAndTermsDropdown(
      onPayTermsChanged: (t) => setState(() => _paymentTerm = t),
      onPayMethodChanged: (m) => setState(() => _paymentMethod = m),
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
    if (_newPO.isEmpty) return;

    final quoteWithTaxes = await POFormInputs.applyTaxesToQuote(_newPO);
    final supplier = await POFormInputs.getSupplier(
      _newPO.supplierLink.supplierId,
    );
    if (supplier.isEmpty) return;

    // Log that details were printed
    if (mounted &&
        AuditTracker.shouldLog(
          id: '${_newPO.id}::$_employeeId',
          type: DocType.pOrder,
          action: AuditAction.printed,
        )) {
      _updateHistory();
    }
    await POPrinter(order: quoteWithTaxes, supplier: supplier).printPO();
  });

  /// Audit Log Entry (Tracking actions)
  void _updateHistory([AuditAction action = AuditAction.printed]) {
    final up = POFormInputs.updateHistory(
      action: action,
      order: _newPO,
      empId: _employeeId,
    );
    _bloc.add(up);
  }
}
