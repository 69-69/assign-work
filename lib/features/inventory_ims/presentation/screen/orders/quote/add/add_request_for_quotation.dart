import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
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
import 'package:assign_erp/features/inventory_ims/data/models/orders/request_for_quotation_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/orders/request_price_quotation_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/quote/widget/form_inputs.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/print_request_for_quote.dart';
import 'package:assign_erp/features/setup/data/data_sources/remote/get_suppliers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension CreateRequestForQuoteForm on BuildContext {
  Future<void> openAddRequestForQuotation({RequestForQuotation? serverQuote}) =>
      openBottomSheet(
        isExpand: false,
        child: FormBottomSheet(
          title: 'Create Request For Quotes',
          body: _AddRequestForQuoteForm(serverQuote: serverQuote),
        ),
      );
}

class _AddRequestForQuoteForm extends StatefulWidget {
  final RequestForQuotation? serverQuote;

  const _AddRequestForQuoteForm({this.serverQuote});

  @override
  State<_AddRequestForQuoteForm> createState() =>
      _AddRequestForQuoteFormState();
}

class _AddRequestForQuoteFormState extends State<_AddRequestForQuoteForm> {
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

  @override
  void initState() {
    super.initState();
    _generateRFQNumber();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _generateRFQNumber() async {
    await 'rfq'.getShortUID(
      onChanged: (s) => setState(() => _newRFQNumber = s),
    );
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

      bloc.add(AddInventory<RequestForQuotation>(data: _newQuote));

      _confirmPrintoutDialog().then((_) => _resetForm());
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset(); // reset validators
    _notesController.clear();
    _generateRFQNumber(); // get a new RFQ number

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
        _buildRFQNumber(),
        FormGroupCard(
          title: 'Request for Quotes',
          children: [
            TitleAndDepartments(
              controller: _titleController,
              onChanged: (t) => setState(() {}),
              onDepartmentChange: (s) => setState(() => _department = s),
            ),
            SuppliersAndRFQStatusDropdown(
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
              onChanged: (List<Map<String, String>> data) {
                if (_formKey.currentState!.validate()) setState(() {});
                prettyPrint('Data', data);

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

/*
class _AddRequestForQuoteFormState extends State<_AddRequestForQuoteForm> {
  final _formKey = GlobalKey<FormState>();

  String _newRFQNumber = '';
  String _selectedSupplierId = '';
  String? _selectedRFQStatus;
  DateTime? _selectedDeadlineDate;
  DateTime? _selectedDeliveryDate;
  final _remarksController = TextEditingController();

  // Add a list to manage line items
  final List<RFQLineItem> _lineItems = [];
  RequestForQuotation? get _serverQuote => widget.serverQuote;

  @override
  void initState() {
    super.initState();
    if (_serverQuote != null) {
      _newRFQNumber = _serverQuote!.rfqNumber;
      _selectedSupplierId = _serverQuote!.supplierId;
      _selectedRFQStatus = _serverQuote?.status;
      _selectedDeadlineDate = _serverQuote?.deadline;
      _selectedDeliveryDate = _serverQuote?.deliveryDate;
      _remarksController.text = _serverQuote?.remarks ?? '';
      _lineItems.addAll(_serverQuote!.lineItems);
    } else {
      _generateRFQNumber();
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  void _generateRFQNumber() async {
    await 'rfq'.getShortUID(
      onChanged: (s) => setState(() => _newRFQNumber = s),
    );
  }

  RequestForQuotation get _newQuote => RequestForQuotation(
    rfqNumber: _newRFQNumber,
    status: _selectedRFQStatus ?? '',
    supplierId: _selectedSupplierId,
    lineItems: List.from(_lineItems),
    deadline: _selectedDeadlineDate,
    deliveryDate: _selectedDeliveryDate,
    remarks: _remarksController.text,
    storeNumber: context.employee!.storeNumber,
    createdBy: context.employee!.fullName,
  );

  void _onSubmit() {
    if (_formKey.currentState!.validate() && _newQuote.isNotEmpty) {
      final bloc = context.read<RequestForQuotationBloc>();

      if (_serverQuote != null) {
        bloc.add(
          UpdateInventory<RequestForQuotation>(
            documentId: _serverQuote!.id,
            data: _newQuote,
          ),
        );
      } else {
        bloc.add(AddInventory<RequestForQuotation>(data: _newQuote));
      }

      _confirmPrintoutDialog().then((_) {
        if (_serverQuote == null) _resetForm();
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset(); // reset validators
    _remarksController.clear();
    _generateRFQNumber(); // get a new RFQ number

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
        _buildRFQNumber(),
        const SizedBox(height: 10.0),
        SuppliersAndRFQStatusDropdown(
          serverSupplier: _serverQuote?.supplierId ?? '',
          serverStatus: _serverQuote?.status,
          onSupplierChanged: (id, name) =>
              setState(() => _selectedSupplierId = id),
          onStatusChanged: (s) => setState(() => _selectedRFQStatus = s),
        ),
        const SizedBox(height: 20.0),
        DeadlineAndDeliveryDateInput(
          labelDelivery: "Delivery date",
          labelDeadline: "Deadline date",
          serverDeadlineDate: _serverQuote?.getDeadlineDate,
          serverDeliveryDate: _serverQuote?.getDeliveryDate,
          onDeliveryChanged: (date) =>
              setState(() => _selectedDeliveryDate = date),
          onDeadlineChanged: (date) =>
              setState(() => _selectedDeadlineDate = date),
        ),
        const SizedBox(height: 10.0),
        HorizontalDivider(thickness: 4.0),

        DynamicTextFields(
          title: 'Line Items (Products/Services)',
          fieldsConfig: [
            FieldConfig(key: 'itemName', type: TextInputType.text),
            FieldConfig(key: 'quantity', type: TextInputType.number),
          ],
          initialData:
              _serverQuote?.lineItems
                  .map(
                    (e) => e.toMap().map(
                      (key, value) => MapEntry(key, value.toString()),
                    ),
                  )
                  .toList() ??
              [],
          onChanged: (List<Map<String, String>> data) {
            if (_formKey.currentState!.validate()) setState(() {});
            prettyPrint('Data', data);

            // Create a new line item
            _lineItems
              ..clear() // Clear previous entries to prevent duplication
              ..addAll(data.map((e) => RFQLineItem.fromMap(e)));
          },
        ),
        HorizontalDivider(thickness: 4.0),
        const SizedBox(height: 10.0),
        RemarksTextField(
          controller: _remarksController,
          onChanged: (t) => setState(() {}),
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(
          label: _serverQuote == null ? 'Create Quote' : 'Update Quote',
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
}*/

/*  bool isMultipleItems = false;

  final ScrollController _scrollController = ScrollController();

  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  // Add Multiple Line of Items
  void _addQuoteToList() {
    final isValid =
        _productNameController.text.isNotEmpty &&
        (int.tryParse(_quantityController.text) ?? 0) > 0;

    if (_formKey.currentState!.validate() || isValid) {
      setState(() => isMultipleItems = true);

      // Create a new line item from the current inputs
      final newLineItem = RFQLineItem(
        productName: _productNameController.text,
        quantity: int.tryParse(_quantityController.text) ?? 0,
      );

      _lineItems.add(newLineItem);
      context.showAlertOverlay('Line item added to quote list');
      _clearFields();
    }
  }

  void _clearFields() {
    _productNameController.clear();
    _quantityController.clear();
  }

  void _removeOrder(RFQLineItem quote) {
    setState(() => _lineItems.remove(quote));
  }

  // Horizontal scrollable row of chips representing the List of batch of Request For Quotation
  Widget _buildRFQPreviewChips() {
    return CustomScrollBar(
      padding: EdgeInsets.zero,
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: _quoteData.isEmpty
          ? const SizedBox.shrink()
          : Row(
              children: _lineItems.map((i) {
                return Card(
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Chip(
                    padding: EdgeInsets.zero,
                    label: RichText(
                      text: TextSpan(
                        text: i.productName.toTitleCase,
                        children: [
                          TextSpan(
                            text: ' (+${i.quantity})'.toTitleCase,
                            style: TextStyle(color: kDangerColor),
                          ),
                        ],
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    deleteButtonTooltipMessage: 'Remove ${i.productName}',
                    deleteIcon: const Icon(
                      size: 16,
                      Icons.clear,
                      color: kGrayColor,
                    ),
                    onDeleted: () => _removeOrder(i),
                  ),
                );
              }).toList(),
            ),
    );
  }


ProductNameTextField(
          controller: _productNameController,
          onChanged: (t) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        QuantityTextField(
          controller: _quantityController,
          onChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 10.0),
        if (isMultipleItems && _lineItems.isNotEmpty) ...[
          SizedBox(height: 50, child: _buildRFQPreviewChips()),
        ],
        context.elevatedIconBtn(
          Icons.add,
          onPressed: _addQuoteToList,
          label: 'Add Item',
        ),*/
