import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
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
import 'package:assign_erp/features/inventory_ims/data/models/orders/request_for_quotation_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/orders/request_price_quotation_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/quote/widget/form_inputs.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/print_request_for_quote.dart';
import 'package:assign_erp/features/setup/data/data_sources/remote/get_suppliers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateRequestForQuotationForm on BuildContext {
  Future openUpdateRequestForQuotation({required RequestForQuotation quote}) =>
      openBottomSheet(
        isExpand: false,
        child: FormBottomSheet(
          title: 'Edit Request For Quote',
          subtitle: quote.rfqNumber.toUpperCaseAll,
          body: _UpdateRequestForQuote(quote: quote),
        ),
      );
}

class _UpdateRequestForQuote extends StatefulWidget {
  final RequestForQuotation quote;

  const _UpdateRequestForQuote({required this.quote});

  @override
  State<_UpdateRequestForQuote> createState() => _UpdateRequestForQuoteState();
}

class _UpdateRequestForQuoteState extends State<_UpdateRequestForQuote> {
  final _formKey = GlobalKey<FormState>();

  String _newRFQNumber = '';
  String _currency = '';
  String _department = '';
  String _selectedSupplierId = '';
  String? _selectedRFQStatus;
  DateTime? _selectedDeadlineDate;
  DateTime? _selectedDeliveryDate;
  DateTime? _selectedValidityDate;
  final _notesController = TextEditingController();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _netPriceController = TextEditingController();

  // Add a list to manage line items
  final List<RFQLineItem> _lineItems = [];
  RequestForQuotation? get _quote => widget.quote;

  @override
  void initState() {
    super.initState();
    if (_quote != null) {
      _newRFQNumber = _quote!.rfqNumber;
      _selectedSupplierId = _quote!.supplierId;
      _selectedRFQStatus = _quote?.status;
      _selectedDeadlineDate = _quote?.deadline;
      _selectedDeliveryDate = _quote?.deliveryDate;
      _currency = _quote!.currency;
      _notesController.text = _quote?.notes ?? '';
      _titleController.text = _quote?.title ?? '';
      _addressController.text = _quote?.deliveryAddress ?? '';
      _lineItems.addAll(_quote!.lineItems);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  RequestForQuotation get _newQuote => RequestForQuotation(
    rfqNumber: _newRFQNumber,
    status: _selectedRFQStatus ?? '',
    department: _department,
    supplierId: _selectedSupplierId,
    currency: _currency,
    title: _titleController.text,
    deliveryAddress: _addressController.text,
    lineItems: List.from(_lineItems),
    deadline: _selectedDeadlineDate,
    deliveryDate: _selectedDeliveryDate,
    validityDate: _selectedValidityDate != null
        ? '${_selectedValidityDate!.toDays} days'
        : '',
    notes: _notesController.text,
    storeNumber: context.employee!.storeNumber,
    createdBy: context.employee!.fullName,
  );

  void _onSubmit() {
    if (_formKey.currentState!.validate() && _newQuote.isNotEmpty) {
      final bloc = context.read<RequestForQuotationBloc>();

      if (_quote != null) {
        bloc.add(
          UpdateInventory<RequestForQuotation>(
            documentId: _quote?.id ?? '',
            data: _newQuote,
          ),
        );
      } else {
        bloc.add(AddInventory<RequestForQuotation>(data: _newQuote));
      }

      _confirmPrintoutDialog().then((_) {
        if (_quote == null) _resetForm();
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset(); // reset validators
    _notesController.clear();
    setState(() {
      _selectedSupplierId = '';
      _selectedRFQStatus = null;
      _selectedDeadlineDate = null;
      _selectedDeliveryDate = null;
      _lineItems.clear();
    });
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
              initialDepartment: _quote?.department ?? '',
              onDepartmentChange: (s) => setState(() => _department = s),
            ),
            SuppliersAndRFQStatusDropdown(
              initialSupplier: _quote?.supplierId ?? '',
              initialStatus: _quote?.status,
              onSupplierChanged: (id, name) =>
                  setState(() => _selectedSupplierId = id),
              onStatusChanged: (s) => setState(() => _selectedRFQStatus = s),
            ),
          ],
        ),

        FormGroupCard(
          children: [
            DynamicTextFields(
              title: 'Products / Services List',
              fieldsConfig: [
                FieldConfig(key: 'itemName', type: TextInputType.text),
                FieldConfig(key: 'quantity', type: TextInputType.number),
                FieldConfig(key: 'unitPrice', type: TextInputType.number),
                FieldConfig(
                  key: 'discount',
                  type: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
              initialData:
                  _quote?.lineItems
                      .map(
                        (e) => e.toMap().map(
                          (key, value) => MapEntry(key, value.toString()),
                        ),
                      )
                      .toList() ??
                  [],
              onChanged: (List<Map<String, String>> data) {
                if (_formKey.currentState!.validate()) setState(() {});
                // Create a new line item
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
              initialDeadlineDate: _quote?.getDeadlineDate,
              initialDeliveryDate: _quote?.getDeliveryDate,
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
          title: 'Supplier Terms',
          children: [
            ValidityAndPayTermsDropdown(
              netPriceController: _netPriceController,
              onNetPriceChanged: (s) =>
                  setState(() => _netPriceController.text = s),
              initialPayTerms: _quote?.status,
              onPayTermsChanged: (s) => setState(() => _selectedRFQStatus = s),
              onValidityChanged: (date) =>
                  setState(() => _selectedValidityDate = date),
            ),
          ],
        ),

        FormGroupCard(
          title: 'Delivery Address and Notes',
          children: [
            DeliveryAddressAndNotes(
              notesController: _notesController,
              addressController: _addressController,
              onAddressChanged: (t) => setState(() {}),
              onNotesChanged: (t) => setState(() {}),
            ),
          ],
        ),
        context.confirmableActionButton(onPressed: _onSubmit),
        const SizedBox(height: 20.0),
      ],
    );
  }

  Future<void> _confirmPrintoutDialog() async {
    final isConfirmed = await context.confirmAction<bool>(
      const Text('Would you like to print the request for quotation: RFQ?'),
      title: "Print RFQ",
      onAccept: "Print",
      onReject: "Cancel",
    );

    if (mounted && isConfirmed) {
      // Show progress dialog while loading data
      await context.progressBarDialog(
        request: _printout(),
        onSuccess: (_) => context.showAlertOverlay('PO successfully created'),
        onError: (error) => context.showAlertOverlay(
          'PO printout failed',
          bgColor: kDangerColor,
        ),
      );
    }
  }

  Future<dynamic> _printout() => Future.delayed(kRProgressDelay, () async {
    if (_newQuote.isEmpty) return;

    // Simulate loading supplier and company info
    final sup = await GetSuppliers.bySupplierId(_newQuote.supplierId);
    if (sup.isNotEmpty) {
      // Perform action after loading
      PrintRequestForQuotation(quote: _newQuote, supplier: sup).onPrintRFQ();
    }
  });
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
