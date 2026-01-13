import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/calculate_extras.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_sale_model.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/pos_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/sales/pos_sale_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/sales/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AddPOSSaleForm<T> on BuildContext {
  Future<void> openAddPOSSales({Widget? header}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(title: 'Add Sale', body: _AddSalesForm()),
  );
}

class _AddSalesForm extends StatefulWidget {
  const _AddSalesForm();

  @override
  State<_AddSalesForm> createState() => _AddSalesFormState();
}

class _AddSalesFormState extends State<_AddSalesForm> {
  bool _isEnabledOrderNumber = false;
  bool _isEnabledItemId = false;
  double _discountAmount = 0.0;
  double _taxAmount = 0.0;
  String _subTotal = '';
  String _selectedCustomerId = '';
  String? _selectedSaleStatus;
  String? _selectedPayMethod;

  final _formKey = GlobalKey<FormState>();
  final _orderNumberController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _itemIdController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _totalAmtController = TextEditingController();

  // Additional Charges
  final _taxPercentController = TextEditingController();
  final _discountPercentController = TextEditingController();

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
      final item = POSSale(
        status: _selectedSaleStatus ?? '',
        receiptNumber: _receiptNumberController.text,
        orderNumber: _orderNumberController.text,
        itemId: _itemIdController.text,
        customerId: _selectedCustomerId,
        quantity: int.parse(_quantityController.text),
        unitPrice: _toDouble(_unitPriceController.text),
        // Additional Charges
        discountPercent: _toDouble(_discountPercentController.text),
        taxPercent: _toDouble(_taxPercentController.text),
        // Total Amount
        totalAmount: _toDouble(_totalAmtController.text),
        payMethod: _selectedPayMethod ?? '',
        storeNumber: context.employee!.storeNumber,
        createdBy: context.employee!.fullName,
      );

      context.read<POSSaleBloc>().add(AddPOS(data: item));

      _formKey.currentState!.reset();
      Navigator.of(context).pop();
    }
  }

  double _toDouble(String i) => double.tryParse(i) ?? 0.0;

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
        ReceiptNumberAndCustomerId(
          receiptNoController: _receiptNumberController,
          onReceiptNoChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
          onCustomerChanged: (id, name) async {
            /// If customer doesn't exist, then fallback on 'Auto ID'.
            /// hence, generate new Customer-ID
            if (name.contains(autoID)) {
              await DocType.customer.getShortUID(
                onChanged: (s) => setState(() => _selectedCustomerId = s),
              );
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
          initialValue: _selectedSaleStatus,
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
          initialPayMethod: _selectedPayMethod,
          onPayMethodChanged: (s) => setState(() => _selectedPayMethod = s),
          onChanged: (t) {
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
