import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/calculate_extras.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/inventory_ims/data/models/sale_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/sales/sale_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/sales/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AddSaleForm<T> on BuildContext {
  Future<void> openAddSales({Widget? header}) => openBottomSheet(
    isExpand: false,
    child: FormBottomSheet(title: 'Add Sales', body: _AddSalesForm()),
  );
}

class _AddSalesForm extends StatefulWidget {
  const _AddSalesForm();

  @override
  State<_AddSalesForm> createState() => _AddSalesFormState();
}

class _AddSalesFormState extends State<_AddSalesForm> {
  bool _isEnabledOrderNumber = false;
  bool _isEnabledTotalAmt = false;
  bool _isEnabledItemId = false;
  double _discountAmount = 0.0;
  double _taxAmount = 0.0;
  String _subTotal = '';
  String _selectedCustomerId = '';
  String? _selectedPayMethod;
  String? _selectedPaymentStatus;
  String? _selectedSaleStatus;

  final _formKey = GlobalKey<FormState>();
  final _orderNumberController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _itemIdController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _totalAmtController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _remarksController = TextEditingController();

  // Additional Charges
  final _discountController = TextEditingController();
  final _taxPercentController = TextEditingController();
  final _discountPercentController = TextEditingController();
  final _deliveryAmountController = TextEditingController();

  void _toggleEditTotalAmt() =>
      setState(() => _isEnabledTotalAmt = !_isEnabledTotalAmt);

  void _toggleEditItemId() =>
      setState(() => _isEnabledItemId = !_isEnabledItemId);

  void _toggleEditOrderNumber() =>
      setState(() => _isEnabledOrderNumber = !_isEnabledOrderNumber);

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_calculateSubTotal);
    _unitPriceController.addListener(_calculateSubTotal);
    _discountController.addListener(_calculateDiscountAmt);
    _taxPercentController.addListener(_calculateTaxAmt);
    _calculateTaxAmt();
    _calculateTotalAmount();
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateSubTotal);
    _unitPriceController.removeListener(_calculateSubTotal);
    _discountController.removeListener(_calculateDiscountAmt);
    _taxPercentController.removeListener(_calculateTaxAmt);

    _amountPaidController.dispose();
    _quantityController.dispose();
    _orderNumberController.dispose();
    _itemIdController.dispose();
    _unitPriceController.dispose();
    _discountController.dispose();
    _deliveryAmountController.dispose();
    _taxPercentController.dispose();
    _totalAmtController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final item = Sale(
        orderNumber: _orderNumberController.text,
        itemId: _itemIdController.text,
        customerId: _selectedCustomerId,
        quantity: int.parse(_quantityController.text),
        unitPrice: double.tryParse(_unitPriceController.text) ?? 0.0,
        deliveryAmount: double.tryParse(_deliveryAmountController.text) ?? 0.0,
        // Additional Charges
        discountPercent: double.tryParse(_discountController.text) ?? 0.0,
        discountAmount: _discountAmount,
        taxPercent: double.tryParse(_taxPercentController.text) ?? 0.0,
        taxAmount: _taxAmount,
        // Total Amount
        amountPaid: double.tryParse(_amountPaidController.text) ?? 0.0,
        totalAmount: double.tryParse(_totalAmtController.text) ?? 0.0,
        paymentMethod: _selectedPayMethod ?? '',
        paymentStatus: _selectedPaymentStatus ?? '',
        status: _selectedSaleStatus ?? '',

        storeNumber: context.employee!.storeNumber,
        createdBy: context.employee!.fullName,
      );

      context.read<SaleBloc>().add(AddInventory<Sale>(data: item));

      _formKey.currentState!.reset();
      Navigator.of(context).pop();
    }
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

  Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 20.0),
        InvoiceNumberAndCustomerId(
          invoiceIdController: _invoiceNumberController,
          onInvoiceNoChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
          onCustomerChanged: (id, name) async {
            /// If customer doesn't exist, then fallback on 'Auto ID'.
            /// hence, generate new Customer-ID
            if (name.contains(autoID)) {
              await 'customer'.getShortUID(
                onChanged: (s) => setState(() => _selectedCustomerId = s),
              );
            } else {
              // Customer found...hence use his/her ID
              setState(() => _selectedCustomerId = id);
            }
          },
        ),
        const SizedBox(height: 20.0),
        OrderNumberAndItemIdInput(
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
        UnitPriceAndQuantityInput(
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
        AmountPaidTextField(
          controller: _amountPaidController,
          onChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
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
        TaxPercentAndDiscountPercentInput(
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
        DeliveryAmtPaymentMethodInput(
          deliveryController: _deliveryAmountController,
          initialPayMethod: _selectedPayMethod,
          onPayMethodChanged: (s) => setState(() => _selectedPayMethod = s),
          onChanged: (s) {
            _calculateTotalAmount();
            setState(() {});
          },
        ),
        const Divider(thickness: 10.0, height: 50),
        SalesAndPaymentStatusDropdown(
          onSaleChanged: (s) => setState(() => _selectedSaleStatus = s),
          onPaymentChanged: (s) => setState(() => _selectedPaymentStatus = s),
        ),
        const SizedBox(height: 20.0),
        RemarksAndTotalAmtTextField(
          enable: _isEnabledTotalAmt,
          onEdited: _toggleEditTotalAmt,
          remarksController: _remarksController,
          totalAmtController: _totalAmtController,
          onTotalAmtChanged: (t) {
            if (_formKey.currentState!.validate()) {
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(
          label: 'Add Sales',
          onPressed: _onSubmit,
        ),
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
      discountPercent: _discountController.text,
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
      deliveryAmt: _deliveryAmountController.text,
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
      deliveryAmt: _deliveryAmountController.text,
      onChanged: (double s) => setState(() => _totalAmtController.text = '$s'),
    );
  }
}
