import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/constants/tax_mode.dart';
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
import 'package:assign_erp/features/procurement/presentation/screen/widget/rfq_printer.dart';
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
  String? _department;
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

  RequestForQuote get _updatedQuote => _serverQuote.copyWith(
    taxMode: _taxModeToApply,
    title: _titleController.text,
    notes: _addressAndNotes['notes'],
    deliveryAddress: _addressAndNotes['deliveryAddress'],
    status: _selectedRFQStatus ?? _serverQuote.status,
    currency: _currency ?? _serverQuote.currency,
    department: _department ?? _serverQuote.department,
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
  );

  void _onSubmit() {
    if (!isFormValid || _lineItems.isNullOrEmpty) {
      context.showAlertOverlay(
        'Please enter all required fields',
        bgColor: kDangerColor,
      );
      return;
    }

    final sanitizedQuote = _sanitizeTaxCodes(_updatedQuote);

    final bloc = context.read<ProRequestForQuoteBloc>();
    bloc.add(
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
            TitleAndDepartments(
              controller: _titleController,
              onChanged: (t) => setState(() {}),
              initialDepartment: _serverQuote.department,
              onDepartmentChange: (id, code, name) =>
                  setState(() => _department = name),
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
                  minLines: 3,
                  validator: (_) => null,
                ),
                FieldGroupConfig(
                  key: 'notes',
                  label: 'Additional Notes (if any)...',
                  type: TextInputType.multiline,
                  isTextArea: true,
                  minLines: 3,
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

    RFQPrinter(quote: quoteWithTaxes, supplier: supplier).printRFQ();
  });

  get _itemsFieldsConfig => [
    FieldGroupConfig(
      key: 'itemName',
      label: 'Item name',
      type: TextInputType.text,
    ),
    FieldGroupConfig(
      key: 'quantity',
      label: 'Quantity',
      type: TextInputType.number,
    ),
    FieldGroupConfig(
      key: 'unitPrice',
      label: 'Unit price',
      type: TextInputType.number,
    ),
    FieldGroupConfig(
      key: 'discount',
      label: 'Discount %',
      validator: (_) => null,
      type: TextInputType.numberWithOptions(decimal: true),
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
  ];
}

// Builds the list of current line items with edit/remove buttons
/*class _UpdateRequestForQuote extends StatefulWidget {
  final RequestForQuotation quote;

  const _UpdateRequestForQuote({required this.quote});

  @override
  State<_UpdateRequestForQuote> createState() => _UpdateRequestForQuoteState();
}

class _UpdateRequestForQuoteState extends State<_UpdateRequestForQuote> {
  RequestForQuotation get _quote => widget.quote;

  String _subTotal = '';
  String? _selectedSupplierId;
  String? _selectedRFQStatus;
  DateTime? _selectedDeliveryDate;
  DateTime? _selectedDeadlineDate;
  double _discountAmount = 0.0;
  double _taxAmount = 0.0;

  bool isMultipleItems = false;
  bool _itemExpanded = false;
  bool _extraExpanded = false;
  final _formKey = GlobalKey<FormState>();

  late final _itemNameController = TextEditingController(text: '');
  late final _quantityController = TextEditingController(text: '');
  late final _unitPriceController = TextEditingController(text: '');
  late final _netPriceController = TextEditingController(text: '');
  late final _remarksController = TextEditingController(text: _quote.remarks);
  late final _discountPercentController = TextEditingController(text: '');
  late final _taxPercentController = TextEditingController(
    text: '${_quote.taxPercent}',
  );

  // Track the line items for the current RFQ
  final List<RFQLineItem> _lineItems = [];
  // Track the current line item being edited
  int? _editingLineItemIndex;

  Key get _itemExpandKey => ValueKey(_itemExpanded);
  Key get _extraExpandKey => ValueKey('e$_extraExpanded');

  @override
  void initState() {
    super.initState();
    _lineItems.addAll(widget.quote.lineItems); // Load existing items
    _quantityController.addListener(_calculateSubTotal);
    _unitPriceController.addListener(_calculateSubTotal);
    _discountPercentController.addListener(_calculateDiscountAmt);
    _taxPercentController.addListener(_calculateTaxAmt);
    _calculateTaxAmt();
    _calculateTotalAmount();
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateSubTotal);
    _unitPriceController.removeListener(_calculateSubTotal);
    _discountPercentController.removeListener(_calculateDiscountAmt);
    _taxPercentController.removeListener(_calculateTaxAmt);

    _itemNameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _remarksController.dispose();
    _discountPercentController.dispose();
    _taxPercentController.dispose();
    super.dispose();
  }

  double _strToDouble(String s) => double.tryParse(s) ?? 0.0;

  RequestForQuotation get _quoteData => RequestForQuotation(
    rfqNumber: _quote.rfqNumber,
    storeNumber: _quote.storeNumber,
    status: _selectedRFQStatus ?? _quote.status,
    supplierId: _selectedSupplierId ?? _quote.supplierId,
    lineItems: List.from(_lineItems),
    /*itemName: _itemNameController.text,
    quantity: int.tryParse(_quantityController.text) ?? 0,
    unitPrice: _strToDouble(_unitPriceController.text),
    netPrice: _strToDouble(_netPriceController.text),
    discountPercent: _strToDouble(_discountPercentController.text),*/
    deliveryDate: _selectedDeliveryDate ?? _quote.deliveryDate,
    deadline: _selectedDeadlineDate ?? _quote.deadline,
    taxPercent: _strToDouble(_taxPercentController.text),
    remarks: _remarksController.text,
    createdBy: _quote.createdBy,
    updatedBy: context.employee!.fullName,
  );

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final item = _quoteData;

      /// Update Request For Quotation
      context.read<RequestForQuotationBloc>().add(
        UpdateInventory<RequestForQuotation>(documentId: _quote.id, data: item),
      );

      context.showAlertOverlay('RFQ no.: ${_quote.rfqNumber} has been updated');

      Navigator.pop(context);
    }
  }

  /// Update Request For Quotation Status
  void _updateStatus(s) {
    _quote.copyWith(status: s);
    setState(() => _selectedRFQStatus = s);

    context.read<RequestForQuotationBloc>().add(
      UpdateInventory<RequestForQuotation>(
        documentId: _quote.id,
        mapData: {'status': s},
      ),
    );

    context.showAlertOverlay('Changes saved');
  }

  void _addQuoteToList() {
    if (_itemNameController.text.isEmpty || _quantityController.text.isEmpty) {
      context.showAlertOverlay('Please fill in item name and quantity');
      return;
    }

    final newLineItem = RFQLineItem(
      itemName: _itemNameController.text,
      unitPrice: double.tryParse(_unitPriceController.text) ?? 0.0,
      quantity: int.tryParse(_quantityController.text) ?? 0,
    );

    setState(() {
      if (_editingLineItemIndex != null) {
        _lineItems[_editingLineItemIndex!] = newLineItem;
        _editingLineItemIndex = null;
      } else {
        _lineItems.add(newLineItem);
      }
      isMultipleItems = true;
    });

    context.showAlertOverlay('Line item added to quote list');
    _clearFields();
  }

  void _clearFields() {
    _quantityController.clear();
    _itemNameController.clear();
  }

  void _removeLineItem(int index) {
    setState(() {
      _lineItems.removeAt(index);
    });
  }

  void _editLineItem(int index) {
    final lineItem = _lineItems[index];
    _itemNameController.text = lineItem.itemName;
    _quantityController.text = lineItem.quantity.toString();
    _unitPriceController.text = lineItem.unitPrice.toString();

    setState(() {
      _editingLineItemIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    _calculateTaxAmt();
    _calculateTotalAmount();

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _buildBody(),
    );
  }

  Widget _buildLineItem() {
    return _buildExpandCard(
      _itemExpandKey,
      _itemExpanded,
      title: 'Line Items',
      trailing: [
        context.outlinedButton(
          _itemExpanded ? 'Cancel' : 'Edit',
          txtColor: kPrimaryAccentColor,
          borderColor: kPrimaryAccentColor,
          onPressed: () => setState(() => _itemExpanded = !_itemExpanded),
        ),
      ],
      children: [
        Column(
          children: List.generate(_lineItems.length, (index) {
            final item = _lineItems[index];

            return _buildCard(
              child: AdaptiveLayout(
                preventLastWrap: true,
                children: [
                  Wrap(
                    runSpacing: 20,
                    children: [
                      CustomTextField(
                        label: 'Item name',
                        initialValue: item.itemName,
                        onChanged: (val) =>
                            _lineItems[index] = item.copyWith(itemName: val),
                        keyboardType: TextInputType.none,
                      ),
                      CustomTextField(
                        label: 'Unit price',
                        initialValue: item.unitPrice.toString(),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (val) => _lineItems[index] = item.copyWith(
                          unitPrice: double.tryParse(val) ?? 0.0,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    runSpacing: 20,
                    children: [
                      CustomTextField(
                        label: 'Quantity',
                        initialValue: item.quantity.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _lineItems[index] = item.copyWith(
                          quantity: int.tryParse(val) ?? 0,
                        ),
                      ),
                      CustomTextField(
                        label: 'Discount %',
                        initialValue: item.discountPercent.toString(),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (val) => _lineItems[index] = item.copyWith(
                          discountPercent: double.tryParse(val) ?? 0.0,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 20,
                    direction: context.isMobile
                        ? Axis.horizontal
                        : Axis.vertical,
                    children: [
                      context.outlinedButton(
                        'Update',
                        onPressed: () {
                          setState(() {
                            _lineItems.removeAt(index);
                          });
                        },
                      ),
                      context.outlinedButton(
                        ' Delete',
                        borderColor: kDangerColor,
                        bgColor: kLightColor,
                        txtColor: kDangerColor,
                        onPressed: () {
                          setState(() {
                            _lineItems.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Update Status',
          style: context.textTheme.titleLarge?.copyWith(color: kTextColor),
        ),
        const SizedBox(height: 10.0),
        RFQStatusDropdown(
          initialValue: _quote.status,
          onChange: (s) => _updateStatus(s),
        ),
        HorizontalDivider(thickness: 4),
        const SizedBox(height: 20.0),
        _buildLineItem(),
        HorizontalDivider(thickness: 4),
        _formBody2(),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(onPressed: _onSubmit),
        const SizedBox(height: 20.0),
      ],
    );
  }

  Widget _formBody2() {
    return _buildExpandCard(
      _extraExpandKey,
      _extraExpanded,
      title: 'Others',
      trailing: [
        context.outlinedButton(
          _extraExpanded ? 'Cancel' : 'Edit',
          txtColor: kPrimaryAccentColor,
          borderColor: kPrimaryAccentColor,
          onPressed: () => setState(() => _extraExpanded = !_extraExpanded),
        ),
      ],
      children: [
        SupplierIDInput(
          onChanged: (id, name) => setState(() => _selectedSupplierId = id),
        ),
        const SizedBox(height: 20.0),

        TaxPercentAndDiscountPercentInput(
          taxController: _taxPercentController,
          discountController: _discountPercentController,
          taxAmount: _taxAmount,
          discountAmount: _discountAmount,
          onTaxChanged: (s) => setState(() => _taxPercentController.text = s),
          onDiscountChanged: (s) =>
              setState(() => _discountPercentController.text = s),
        ),
        const SizedBox(height: 20.0),
        NetPriceAndRFQStatusDropdown(
          netPriceController: _netPriceController,
          onNetPriceChanged: (s) =>
              setState(() => _netPriceController.text = s),
          initialStatus: _quote.status,
          onStatusChanged: (s) => setState(() => _selectedRFQStatus = s),
        ),
        const SizedBox(height: 20.0),
        DeadlineAndDeliveryDateInput(
          labelDelivery: "Delivery date",
          labelDeadline: "Deadline date",
          initialDeadlineDate: _quote.getDeadlineDate,
          initialDeliveryDate: _quote.getDeliveryDate,
          onDeliveryChanged: (date) =>
              setState(() => _selectedDeliveryDate = date),
          onDeadlineChanged: (date) =>
              setState(() => _selectedDeadlineDate = date),
        ),
        const SizedBox(height: 20.0),
        RemarksTextField(
          controller: _remarksController,
          onChanged: (t) => setState(() {}),
        ),
      ],
    );
  }

  _buildCard({required Widget child}) {
    return Card(
      elevation: 3.0,
      color: context.scaffoldBgColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(10), child: child),
    );
  }

  Widget _buildExpandCard(
    Key? key,
    bool initExpanded, {
    String title = '',
    required List<Widget> children,
    required List<Widget> trailing,
  }) {
    return ExpansionTile(
      key: key,
      dense: true,
      initiallyExpanded: initExpanded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: trailing,
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: context.textTheme.titleLarge?.copyWith(color: kTextColor),
      ),
      tilePadding: EdgeInsets.symmetric(horizontal: 10.0),
      childrenPadding: const EdgeInsets.only(bottom: 20.0),
      children: children,
    );
  }

  void _calculateSubTotal() {
    CalculateExtras.subTotal(
      qty: _quantityController.text,
      unitPrice: _unitPriceController.text,
      onChanged: (String s) => setState(() => _subTotal = s),
    );
    _calculateTotalAmount();
  }

  void _calculateDiscountAmt() {
    CalculateExtras.discountAmount(
      discountPercent: _discountPercentController.text,
      subTotal: _subTotal,
      onChanged: (double s) => setState(() => _discountAmount = s),
    );
    _calculateTotalAmount();
  }

  void _calculateTaxAmt() {
    CalculateExtras.taxAmount(
      taxPercent: _taxPercentController.text,
      subTotal: _subTotal,
      discountAmt: _discountAmount,
      onChanged: (s) => setState(() => _taxAmount = s),
    );
    _calculateTotalAmount();
  }

  void _calculateTotalAmount() {
    CalculateExtras.totalAmount(
      taxAmount: _taxAmount,
      discountAmount: _discountAmount,
      subTotal: _subTotal,
      onChanged: (double s) =>
          setState(() => _netPriceController.text = s.toStringAsFixed(2)),
    );
  }
}
*/

/*Widget _buildLineItemsList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 700;
        final availableWidth = isSmallScreen
            ? double.infinity
            : constraints.maxWidth;
        prettyPrint('steve', availableWidth.toString());

        return AdaptiveLayout(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _lineItems.map((lineItem) {
            final index = _lineItems.indexOf(lineItem);
            return SizedBox(
              width: availableWidth, // full width
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                  title: Text(
                    '${lineItem.productName.toTitleCase} x ${lineItem.quantity}',
                  ),
                  subtitle: Text(
                    'Unit Price: ${lineItem.unitPrice.toStringAsFixed(2)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: kLightBlueColor),
                        tooltip: 'Edit item',
                        onPressed: () => _editLineItem(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: kDangerColor),
                        tooltip: 'Delete item',
                        onPressed: () => _removeLineItem(index),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }*/
