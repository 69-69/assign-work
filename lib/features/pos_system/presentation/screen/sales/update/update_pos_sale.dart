import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/calculate_extras.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_sale_model.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/pos_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/sales/pos_sale_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/sales/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdatePOSSaleForm on BuildContext {
  Future<void> openUpdatePOSSale({required POSSale sale}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: 'Edit Sale',
      subtitle: 'ID: ${sale.id}'.toUpperAll,
      body: _UpdateSaleForm(sale: sale),
    ),
  );
}

class _UpdateSaleForm extends StatefulWidget {
  final POSSale sale;

  const _UpdateSaleForm({required this.sale});

  @override
  State<_UpdateSaleForm> createState() => _UpdateSaleFormState();
}

class _UpdateSaleFormState extends State<_UpdateSaleForm> {
  POSSale get _sale => widget.sale;

  bool _isEnabledOrderNumber = false;
  bool _isEnabledItemId = false;
  double _discountAmount = 0.0;
  double _taxAmount = 0.0;
  String _subTotal = '';
  String? _selectedSaleStatus;
  String _selectedCustomerId = '';

  late String _selectedPaymentMethod = _sale.payMethod;

  final _formKey = GlobalKey<FormState>();

  late final _quantityController = TextEditingController(
    text: '${_sale.quantity}',
  );
  late final _unitPriceController = TextEditingController(
    text: '${_sale.unitPrice}',
  );
  late final _totalAmtController = TextEditingController(
    text: '${_sale.totalAmount}',
  );

  late final _orderNumberController = TextEditingController(
    text: _sale.orderNumber,
  );
  late final _itemIdController = TextEditingController(text: _sale.itemId);
  late final _receiptNumberController = TextEditingController(
    text: _sale.receiptNumber,
  );

  // Additional Charges
  late final _discountPercentController = TextEditingController(
    text: '${_sale.discountPercent}',
  );
  late final _taxPercentController = TextEditingController(
    text: '${_sale.taxPercent}',
  );

  void _toggleEditItemId() =>
      setState(() => _isEnabledItemId = !_isEnabledItemId);

  void _toggleEditOrderNumber() =>
      setState(() => _isEnabledOrderNumber = !_isEnabledOrderNumber);

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_calculateSubTotal);
    _unitPriceController.addListener(_calculateSubTotal);
    _taxPercentController.addListener(_calculateTaxAmt);
    _discountPercentController.addListener(_calculateDiscountAmt);
    _calculateTaxAmt();
    _calculateTotalAmount();
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateSubTotal);
    _unitPriceController.removeListener(_calculateSubTotal);
    _taxPercentController.removeListener(_calculateTaxAmt);
    _discountPercentController.removeListener(_calculateDiscountAmt);

    _quantityController.dispose();
    _orderNumberController.dispose();
    _itemIdController.dispose();
    _unitPriceController.dispose();
    _discountPercentController.dispose();
    _receiptNumberController.dispose();
    _taxPercentController.dispose();
    _totalAmtController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final item = _sale.copyWith(
        status: _selectedSaleStatus,
        receiptNumber: _receiptNumberController.text,
        orderNumber: _orderNumberController.text,
        itemId: _itemIdController.text,
        customerId: _selectedCustomerId,
        quantity: int.tryParse(_quantityController.text),
        unitPrice: _strToDouble(_unitPriceController.text),
        // Additional Charges
        discountPercent: _strToDouble(_discountPercentController.text),
        taxPercent: _strToDouble(_taxPercentController.text),
        // Total Amount
        totalAmount: _strToDouble(_totalAmtController.text),
        payMethod: _selectedPaymentMethod,
        storeNumber: _sale.storeNumber,

        createdBy: _sale.createdBy,
        updatedBy: context.employee!.fullName,
      );

      /// Update Sale
      context.read<POSSaleBloc>().add(
        UpdatePOS<POSSale>(documentId: _sale.id, data: item),
      );

      _formKey.currentState!.reset();
      context.showAlertOverlay(
        'Sales with ID: ${_sale.id} has been successfully updated',
      );

      Navigator.of(context).pop();
    }
  }

  /// Update POS-Sales Status
  void _updatePOSStatus(status) {
    _sale.copyWith(status: status);
    setState(() => _selectedSaleStatus = status);

    /// Update Sales Status
    context.read<POSSaleBloc>().add(
      UpdatePOS<POSSale>(documentId: _sale.id, mapData: {'status': status}),
    );

    context.showAlertOverlay('Changes saved');
  }

  double? _strToDouble(s) => double.tryParse(s) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    _calculateTaxAmt();
    _calculateTotalAmount();

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _buildBody(context),
    );
  }

  Column _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Update Sales Status', style: context.textTheme.titleLarge),
        const SizedBox(height: 10.0),
        SaleStatusDropdown(
          initialValue: _sale.status,
          onStatusChange: (s) => _updatePOSStatus(s),
        ),
        HorizontalDivider(thickness: 8.0),
        _formBody(),
      ],
    );
  }

  ExpansionTile _formBody() {
    return ExpansionTile(
      dense: true,
      title: Text(
        'Modify this Sales',
        textAlign: TextAlign.center,
        style: context.textTheme.titleLarge,
      ),
      subtitle: Text('ID ${_sale.id}'.toUpperAll, textAlign: TextAlign.center),
      childrenPadding: const EdgeInsets.only(bottom: 20.0),
      children: <Widget>[
        const SizedBox(height: 20.0),
        ReceiptNumberAndCustomerId(
          receiptNoController: _receiptNumberController,
          onReceiptNoChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
          onCustomerChanged: (id, name) async {
            /// If customer doesn't exist, then fallback on 'Auto ID'.
            /// hence, generate new Customer-ID
            if (name.contains(autoID)) {
              final id = await DocType.customer.getShortUID;
              setState(() => _selectedCustomerId = id);
            } else {
              // Customer found...hence use his/her ID
              setState(() => _selectedCustomerId = id);
            }
          },
        ),
        const SizedBox(height: 20.0),
        OrderNumberAndItemId(
          enableOrderNumber: _isEnabledOrderNumber,
          onOrderNumberEdited: _toggleEditOrderNumber,
          enableItemId: _isEnabledItemId,
          onItemIdEdited: _toggleEditItemId,
          orderNumberController: _orderNumberController,
          itemIdController: _itemIdController,
          onItemIdChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
          onIdChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        UnitPriceAndQuantity(
          unitPriceController: _unitPriceController,
          quantityController: _quantityController,
          onUnitPriceChanged: (t) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
          onQuantityChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        SaleStatusDropdown(
          initialValue: _sale.status,
          onStatusChange: (s) => setState(() => _selectedSaleStatus = s),
        ),
        const SizedBox(height: 20.0),
        ListTile(
          dense: true,
          title: Text(
            'Additional Charges:',
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium,
          ),
          subtitle: const Text('Optional', textAlign: TextAlign.center),
        ),
        TaxPercentAndDiscountPercent(
          taxAmount: _taxAmount,
          discountAmount: _discountAmount,
          taxController: _taxPercentController,
          discountController: _discountPercentController,
          onDiscountChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
          onChanged: (t) {
            if (_formKey.currentState!.validate()) {
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 20.0),
        TotalAmtAndPaymentMethod(
          totalAmtController: _totalAmtController,
          initialPayMethod: _selectedPaymentMethod,
          onPayMethodChanged: (s) => setState(() => _selectedPaymentMethod = s),
          onChanged: (t) {
            if (_formKey.currentState!.validate()) {
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 10.0),
        context.confirmableActionButton(onSubmit: _onSubmit),
      ],
    );
  }

  /// Calculate Sub-Total by Quantity & Unit Price [_calculateSubTotal]
  void _calculateSubTotal() {
    CalculateExtras.subTotal(
      qty: _quantityController.text,
      unitPrice: _unitPriceController.text,
      onChanged: (String s) => setState(() => _subTotal = s),
    );
    _calculateTotalAmount();
  }

  /// Calculate Discount-Amount by Total-Price & Discount-Percentile [_calculateDiscountAmt]
  void _calculateDiscountAmt() {
    CalculateExtras.discountAmount(
      discountPercent: _discountPercentController.text,
      subTotal: _subTotal,
      onChanged: (double s) => setState(() => _discountAmount = s),
    );
    _calculateTotalAmount();
  }

  /// Calculate Tax-Amount by Total-Price & Tax-Percentile [_calculateTaxAmt]
  void _calculateTaxAmt() {
    CalculateExtras.taxAmount(
      taxPercent: _taxPercentController.text,
      subTotal: _subTotal,
      discountAmt: _discountAmount,
      onChanged: (double s) => setState(() => _taxAmount = s),
    );
    _calculateTotalAmount();
  }

  /// Calculate Total-Amount by All [_calculateTotalAmount]
  void _calculateTotalAmount() {
    CalculateExtras.totalAmount(
      taxAmount: _taxAmount,
      discountAmount: _discountAmount,
      subTotal: _subTotal,
      onChanged: (double s) => setState(() => _totalAmtController.text = '$s'),
    );
  }
}

/*
* List<Sale> selectedSales = [];
* Wrap(
    spacing: 8.0,
    children: List.generate(
      selectedSales.length,
      (index) => InputChip(
        label: Text(selectedSales[index].itemName),
        onDeleted: () {
          setState(() {
            selectedSales.removeAt(index);
          });
        },
      ),
    ),
  ),*/
