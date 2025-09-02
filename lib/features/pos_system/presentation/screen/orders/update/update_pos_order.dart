import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/calculate_extras.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/barcode_scanner.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_model.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_order_model.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/orders/pos_order_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/pos_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/orders/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateOrderForm on BuildContext {
  Future openUpdatePOSOrder({required POSOrder order}) => openBottomSheet(
    isExpand: false,
    child: FormBottomSheet(
      title: 'Edit Order',
      subtitle: order.orderNumber.toUpperAll,
      body: _UpdateOrderForm(order: order),
    ),
  );
}

class _UpdateOrderForm extends StatefulWidget {
  final POSOrder order;

  const _UpdateOrderForm({required this.order});

  @override
  State<_UpdateOrderForm> createState() => _UpdateOrderFormState();
}

class _UpdateOrderFormState extends State<_UpdateOrderForm> {
  POSOrder get _order => widget.order;

  // Updates the product details in the Form by setting the unit price,
  // product ID, & name based on the provided Product instance.
  set _setItemId(Item p) {
    _unitPriceController.text = '${p.sellingPrice}';
    _selectedItemId = p.id;
    _selectedItemName = p.name;
  }

  bool _isEnabledTotalAmt = false;
  String _selectedCustomerId = '';
  String _selectedItemId = '';
  String _selectedItemName = '';
  String? _selectedOrderStatus;
  String? _selectedPayMethod;
  double _discountAmount = 0.0;
  double _taxAmount = 0.0;

  final _formKey = GlobalKey<FormState>();
  late final _quantityController = TextEditingController(
    text: '${_order.quantity}',
  );
  late final _unitPriceController = TextEditingController(
    text: '${_order.unitPrice}',
  );
  late final _subTotalController = TextEditingController(
    text: '${_order.getSubTotal}',
  );
  late final _barcodeController = TextEditingController(text: _order.barcode);
  late final _totalAmtController = TextEditingController(
    text: '${_order.totalAmount}',
  );
  late final _discountPercentController = TextEditingController(
    text: '${_order.discountPercent}',
  );
  late final _taxPercentController = TextEditingController(
    text: '${_order.taxPercent}',
  );

  void _toggleEditTotalAmt() =>
      setState(() => _isEnabledTotalAmt = !_isEnabledTotalAmt);

  @override
  void initState() {
    super.initState();
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

    _quantityController.dispose();
    _barcodeController.dispose();
    _unitPriceController.dispose();
    _subTotalController.dispose();
    _discountPercentController.dispose();
    _taxPercentController.dispose();
    super.dispose();
  }

  POSOrder get _orderData => _order.copyWith(
    status: _selectedOrderStatus ?? '',
    barcode: _barcodeController.text,
    itemId: _selectedItemId,
    itemName: _selectedItemName,
    customerId: _selectedCustomerId,
    quantity: int.tryParse(_quantityController.text) ?? 0,
    unitPrice: _strToDouble(_unitPriceController.text),
    payMethod: _selectedPayMethod ?? '',
    discountPercent: _strToDouble(_discountPercentController.text),
    taxPercent: _strToDouble(_taxPercentController.text),
    discountAmount: _discountAmount,
    taxAmount: _taxAmount,
    totalAmount: _strToDouble(_totalAmtController.text),
    storeNumber: context.employee!.storeNumber,
    createdBy: _order.createdBy,
    updatedBy: context.employee!.fullName,
    /*taxAmount: _taxAmount,
        discountAmount: _discountAmount,
        subTotal: _strToDouble(_subTotalController.text),*/
  );

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final item = _orderData;

      /// Update Orders
      context.read<POSOrderBloc>().add(
        UpdatePOS<POSOrder>(documentId: _order.id, data: item),
      );

      context.showAlertOverlay(
        'Order ${_order.orderNumber} has been successfully updated',
      );

      Navigator.pop(context);
    }
  }

  /// Update Order Status
  void _updateStatus(s) {
    _order.copyWith(status: s);
    setState(() => _selectedOrderStatus = s);

    context.read<POSOrderBloc>().add(
      UpdatePOS<POSOrder>(documentId: _order.id, mapData: {'status': s}),
    );

    context.showAlertOverlay('Changes saved');
  }

  double _strToDouble(String s) => double.tryParse(s) ?? 0.0;

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
        Text('Update Order Status', style: context.textTheme.titleLarge),
        const SizedBox(height: 10.0),
        OrdersStatusDropdown(
          initialValue: _order.status,
          onChange: (s) => _updateStatus(s),
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
        'Modify this Order',
        textAlign: TextAlign.center,
        style: context.textTheme.titleLarge,
      ),
      subtitle: Text('ID ${_order.id}'.toUpperAll, textAlign: TextAlign.center),
      childrenPadding: const EdgeInsets.only(bottom: 20.0),
      children: [
        const SizedBox(height: 20.0),
        CustomerAndItemId(
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
          onItemChanged: (item) => setState(() => _setItemId = item),
        ),
        const SizedBox(height: 20.0),
        UnitPriceAndQuantityInput(
          qtyController: _quantityController,
          unitPriceController: _unitPriceController,
          onQtyChanged: (_) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
          onUnitChanged: (t) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        SubTotalAndOrderStatus(
          subTotalController: _subTotalController,
          onSubTotalChange: (t) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
          initialStatus: _selectedOrderStatus,
          onStatusChange: (s) => setState(() => _selectedOrderStatus = s),
        ),
        const SizedBox(height: 20.0),
        BarcodeScannerWithTextField(
          controller: _barcodeController,
          onChanged: (t) => setState(() {}),
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
            _calculateTotalAmount();
            if (_formKey.currentState!.validate()) setState(() {});
          },
          onTaxChanged: (s) {
            _calculateTotalAmount();
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        TotalAmountAndPayMethod(
          enable: _isEnabledTotalAmt,
          onEdited: _toggleEditTotalAmt,
          totalAmtController: _totalAmtController,
          initialPayMethod: _selectedPayMethod,
          onTotalAmtChanged: (t) {
            if (_formKey.currentState!.validate()) {
              setState(() {});
            }
          },
          onPaymentChanged: (s) => setState(() => _selectedPayMethod = s),
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(onPressed: _onSubmit),
        const SizedBox(height: 20.0),
      ],
    );
  }

  /// Calculate Sub-Total by Quantity & Unit Price [_calculateSubTotal]
  void _calculateSubTotal() {
    CalculateExtras.subTotal(
      qty: _quantityController.text,
      unitPrice: _unitPriceController.text,
      onChanged: (String s) => setState(() => _subTotalController.text = s),
    );
    _calculateTotalAmount();
  }

  /// Calculate Discount-Amount by Total-Price & Discount-Percentile [_calculateDiscountAmt]
  void _calculateDiscountAmt() {
    CalculateExtras.discountAmount(
      discountPercent: _discountPercentController.text,
      subTotal: _subTotalController.text,
      onChanged: (double s) => setState(() => _discountAmount = s),
    );
    _calculateTotalAmount();
  }

  /// Calculate Tax-Amount by Total-Price & Tax-Percentile [_calculateTaxAmt]
  void _calculateTaxAmt() {
    CalculateExtras.taxAmount(
      taxPercent: _taxPercentController.text,
      subTotal: _subTotalController.text,
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
      subTotal: _subTotalController.text,
      onChanged: (double s) =>
          setState(() => _totalAmtController.text = s.toStringAsFixed(2)),
    );
  }
}
