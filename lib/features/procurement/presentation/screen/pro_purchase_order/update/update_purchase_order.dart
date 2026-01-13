import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/app_drop_options.dart';
import 'package:assign_erp/core/network/data_sources/models/address_model.dart';
import 'package:assign_erp/core/network/data_sources/models/audit_log_model.dart';
import 'package:assign_erp/core/network/data_sources/models/line_item_model.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/extensions/tax_mode.dart';
import 'package:assign_erp/core/util/extensions/workflow_status.dart';
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
import 'package:assign_erp/features/procurement/data/model/pro_purchase_order_model.dart';
import 'package:assign_erp/features/procurement/data/model/supplier_link_model.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/pro_po/pro_purchase_order_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/bloc/procurement_bloc.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_order/widget/po_form_inputs.dart';
import 'package:assign_erp/features/procurement/presentation/screen/pro_purchase_order/widget/po_printer.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension POFormExtensions on BuildContext {
  /// [openUpdatePOForm] Opens the Update Purchase Order Form
  Future<void> openUpdatePOForm({
    required ProPurchaseOrder serverPO,
  }) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      initialSize: 0.94,
      title: 'Edit Purchase Order',
      subtitle:
          '${serverPO.poNumber.toLowerAll} (${serverPO.lineItems.first.getType})',
      body: _CreatePOForm(serverPO: serverPO),
    ),
  );
}

/// Create Purchase Order Form [_CreatePOForm]
class _CreatePOForm extends StatefulWidget {
  final ProPurchaseOrder serverPO;

  const _CreatePOForm({required this.serverPO});

  @override
  State<_CreatePOForm> createState() => _CreatePOFormState();
}

class _CreatePOFormState extends State<_CreatePOForm> {
  final _formKey = GlobalKey<FormState>();

  bool get _isFormValid => _formKey.currentState!.validate();

  // Basic fields
  bool _isSubmitting = false;
  String? _poStatus;
  String? _requestedBy;
  String? _paymentTerm;
  String? _currencyCode;
  String? _paymentMethod;
  String? _costCenterCode;
  String? _buyerContactPersonId;

  // Dates
  DateTime? _deliveryDate;

  /// Line Items & Additional Info
  final List<String> _taxCodes = [];
  final List<LineItem> _lineItems = [];
  final List<AddressInfo> _addresses = [];
  final List<SupplierLink> _supplierLinks = [];
  final Map<String, dynamic> _shippingAmount = {};
  final Map<String, dynamic> _additionalInfo = {};

  /// [_taxModeToApply] Tax method to apply either per line[PerLineTax] or per order[HeaderTax].
  TaxMode? _taxModeToApply;
  late ProPurchaseOrder _finalizedPO;

  ProPurchaseOrder get _serverPO => widget.serverPO;

  String get _lineItemType => _serverPO.lineItems.first.getType;

  /// Current employee info
  Employee? get _employee => context.employee;

  String get _employeeId => _employee!.employeeId;

  String get _employeeName => _employee!.fullName;

  ProPurchaseOrderBloc get _bloc => context.read<ProPurchaseOrderBloc>();

  AuditAction get _action =>
      _serverPO.isApproved ? AuditAction.approved : AuditAction.updated;

  /// Construct ProPurchaseOrder object
  ProPurchaseOrder get _updatePO {
    final status = _poStatus ?? _serverPO.getPOStatus;

    return _serverPO.copyWith(
      status: WorkflowStatusUtil.fromString(status),
      supplierLink: _supplierLinks.first,
      requestedBy: _requestedBy ?? _serverPO.requestedBy,

      costCenterCode: _costCenterCode ?? _serverPO.costCenterCode,
      currencyCode: _currencyCode ?? _serverPO.currencyCode,

      paymentTerm: _paymentTerm ?? _serverPO.paymentTerm,
      paymentMethod: _paymentMethod ?? _serverPO.paymentMethod,
      shippingAmount: '${_shippingAmount['shippingAmount']}'.asDouble,

      addresses: List.from(_addresses),
      buyerContactPersonId:
          _buyerContactPersonId ?? _serverPO.buyerContactPersonId,
      notes: _additionalInfo['notes'],
      termsAndConditions: _additionalInfo['termsAndConditions'],

      lineItems: List.from(_lineItems),
      taxMode: _taxModeToApply ?? TaxMode.perLineTax,

      deliveryDate: _deliveryDate ?? _serverPO.deliveryDate,
      updatedBy: _employeeName,
      history: [
        ..._serverPO.history, // Keep existing history
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
      if (!_isFormValid || _updatePO.isNullOrEmpty) {
        context.showAlertOverlay(
          'Please enter all required fields',
          bgColor: kDangerColor,
        );
        return;
      }

      _finalizedPO = _sanitizeTaxCodes(_updatePO);

      _bloc.add(
        UpdateProcurement<ProPurchaseOrder>(
          documentId: _finalizedPO.id,
          data: _finalizedPO,
        ),
      );

      context.showAlertOverlay('Changes successfully saved');

      await _confirmPrintoutDialog();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Ensures tax codes & totalTaxAmount are correctly applied to PO line items
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
  ProPurchaseOrder _sanitizeTaxCodes(ProPurchaseOrder quote) {
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
  void initState() {
    _taxModeToApply = _serverPO.taxMode;
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
        FormGroupCard(
          title: '1. Purchase Order Overview',
          subTitle: '\nGeneral purchase order info & supplier details.',
          children: [_buildPOStatusAndRequestedBy(), _buildSupplier()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '2. Accounting & Cost Assignment',
          subTitle: '\nCost center, currency, & accounting allocation details.',
          children: [_buildCurrencyAndCostCenter(), _buildShippingAmount()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '3. Payment Terms & Tax',
          subTitle: '\nPayment method, payment terms, & tax preferences.',
          children: [_buildPayMethodAndTerms(), _buildTaxModeSelector()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '4. ${_lineItemType.toSentence} Line Items',
          subTitle:
              '\nYou can add more ${_lineItemType}s to the purchase order (PO).',
          children: [_buildLineItems()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '5. Addresses',
          subTitle:
              '\nBuyer\'s billing, shipping, or any additional addresses.',
          children: [_buildAddresses()],
        ),

        FormGroupCard(
          isExpanded: false,
          title: '6. Delivery, Contacts & Terms',
          subTitle: '\nDelivery date, buyer contact, & terms.',
          children: [_buildBuyerRepAndDeliveryDate(), _buildTermsAndNotes()],
        ),

        FormGroupCard(
          showCollapseButton: false,
          title: 'Financial Summary',
          subTitle: '\nOverview of the Quotation’s Financial Details',
          contentPadding: const EdgeInsets.fromLTRB(10, 20, 22, 20),
          children: [
            HorizontalDivider(space: 0.4),
            ...[
              ('SubTotal:', _serverPO.subTotal),
              ('Discount:', _serverPO.totalDiscountAmount),
              ('Tax Amount:', _serverPO.totalTaxPercent),
              ('Net Total:', _serverPO.netTotal),
              if (_serverPO.shippingTaxAmount > 0) ...[
                ('Shipping:', _serverPO.shippingAmount),
                ('Shipping Tax:', _serverPO.shippingTaxAmount),
              ],
              ('Grand Total:', _serverPO.grandTotal),
            ].map((e) => _buildTextSummary(e.$1, e.$2)),
          ],
        ),

        const SizedBox(height: 20.0),
        context.confirmableActionButton(onPressed: _onSubmit),
        const SizedBox(height: 20.0),
      ],
    );
  }

  // -------------------------
  // Section Builders
  // -------------------------

  // Addresses (e.g., Billing, Shipping Address)
  DynamicTextFields _buildAddresses() {
    return DynamicTextFields(
      showButton: true,
      fieldsConfig: POFormInputs.addressFields,
      initialData: _serverPO.addresses?.map((e) => e.toMap()).toList() ?? [{}],
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        // Update the address list
        POFormInputs.updateListFromData<AddressInfo>(
          _addresses,
          map: data,
          fromMap: (map, id) => AddressInfo.fromMap(map, id: id),
        );
      },
    );
  }

  DeliveryDate _buildBuyerRepAndDeliveryDate() {
    return DeliveryDate(
      labelDelivery: "Delivery date",
      initialContact: _serverPO.buyerContactPersonId,
      initialDeliveryDate: _serverPO.getDeliveryDate,
      onContactChanged: (id, _, _) =>
          setState(() => _buyerContactPersonId = id),
      onDeliveryChanged: (date) => setState(() => _deliveryDate = date),
    );
  }

  DynamicTextFields _buildTermsAndNotes() {
    return DynamicTextFields(
      initialData: [
        {
          'notes': _serverPO.notes,
          'termsAndConditions': _serverPO.termsAndConditions,
        },
      ],
      fieldsConfig: POFormInputs.deliveryFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        _additionalInfo
          ..clear() // Clear previous entries to prevent duplication
          ..addAll(data.first);
      },
    );
  }

  DynamicTextFields _buildLineItems() {
    return DynamicTextFields(
      showButton: true,
      fullWidthKey: 'description',
      fieldsConfig: POFormInputs.fields(
        _lineItemType,
        isHidden: _taxModeToApply != TaxMode.perLineTax,
      ),
      initialData: _serverPO.lineItems
          .map((e) => {...e.toMap(true), 'netPrice': '${e.netAmount}'})
          .toList(),
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        // Update the LineItem list
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
      initialCurrency: _serverPO.currencyCode,
      initialCostCenter: _serverPO.costCenterCode,
      onCurrencyChanged: (v) => setState(() => _currencyCode = v),
      onCostCenterChange: (id, code, name) =>
          setState(() => _costCenterCode = code),
    );
  }

  DynamicTextFields _buildShippingAmount() {
    return DynamicTextFields(
      initialData: [
        {'shippingAmount': _serverPO.shippingAmount},
      ],
      fieldsConfig: [
        FieldGroupConfig(
          key: 'shippingAmount',
          label: 'Shipping Amount',
          type: TextInputType.number,
          widgetType: FieldWidgetType.textField,
        ),
      ],
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

        _shippingAmount
          ..clear()
          ..addAll(data.first);
      },
    );
  }

  POStatusAndRequestedBy _buildPOStatusAndRequestedBy() {
    return POStatusAndRequestedBy(
      initialStatus: _serverPO.getPOStatus,
      initialRequestedBy: _serverPO.requestedBy,
      onStatusChanged: (s) => setState(() => _poStatus = s),
      onRequestedChanged: (id, code, name) => setState(() => _requestedBy = id),
    );
  }

  // Only a single supplier is allowed for a PO
  DynamicTextFields _buildSupplier() {
    final supLink = _serverPO.supplierLink;

    return DynamicTextFields(
      initialData: [
        {'supplierLinks': supLink.toMap(), 'status': supLink.getStatus},
      ],
      showButton: false,
      fullWidthKey: 'supplierLinks',
      fieldsConfig: POFormInputs.suppliersFields,
      onChanged: (List<Map<String, dynamic>> data) {
        if (_isFormValid) setState(() {});

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
      initialPayTerms: _serverPO.paymentTerm,
      initialPayMethod: _serverPO.paymentMethod,
      onPayTermsChanged: (t) => setState(() => _paymentTerm = t),
      onPayMethodChanged: (m) => setState(() => _paymentMethod = m),
    );
  }

  Widget _buildTaxModeSelector() {
    return POFormInputs.buildTaxModeSelector(
      initialValues: List.from(_serverPO.lineItems.first.taxCodes),
      selectedTaxCodes: _taxCodes,
      defaultTaxMode: _taxModeToApply,
      selectedTaxMode: (TaxMode? mode) =>
          setState(() => _taxModeToApply = mode),
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
    if (_finalizedPO.isEmpty) return;

    final quoteWithTaxes = await POFormInputs.applyTaxesToQuote(_finalizedPO);
    final supplier = await POFormInputs.getSupplier(
      _finalizedPO.supplierLink.supplierId,
    );
    if (supplier.isEmpty) return;

    // Log that details were printed
    if (mounted &&
        AuditTracker.shouldLog(
          id: '${_finalizedPO.id}::$_employeeId',
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
      order: _finalizedPO,
      empId: _employeeId,
    );
    _bloc.add(up);
  }

  Widget _buildTextSummary(String label, double amount) {
    if (amount.isNaN || amount == 0.0) {
      amount = 0.0; // Set a default value if the amount is invalid
    }
    final sign = getCurrencySign(_serverPO.currencyCode);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: label.filterAny('grand') ? kDangerColor : kTextColor,
          ),
        ),
        Text(
          '$sign${amount.toCurrency}',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.normal,
            color: context.onSurfaceColor,
          ),
          textAlign: TextAlign.end, // Right-align the value
        ),
      ],
    );
  }
}
