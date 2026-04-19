import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/calculate_extras.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/purchase_order_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/orders/purchase_order_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/po/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdatePurchaseOrderForm on BuildContext {
  Future openUpdatePurchaseOrder({required PurchaseOrder po}) =>
      openBottomSheet(
        isExpand: false,
        child: BottomSheetScaffold(
          title: 'Edit Purchase Order',
          subtitle: po.poNumber.toUpperAll,
          body: _UpdatePurchaseOrderForm(po: po),
        ),
      );
}

class _UpdatePurchaseOrderForm extends StatefulWidget {
  final PurchaseOrder po;

  const _UpdatePurchaseOrderForm({required this.po});

  @override
  State<_UpdatePurchaseOrderForm> createState() =>
      _UpdatePurchaseOrderFormState();
}

class _UpdatePurchaseOrderFormState extends State<_UpdatePurchaseOrderForm> {
  PurchaseOrder get _order => widget.po;

  bool _isEnabledTotalAmt = false;

  String _subTotal = '';
  String? _selectedSupplierId;
  String? _selectedPOStatus;
  String? _selectedPayTerms;
  String? _selectedPayMethod;
  String? _selectedCurrency;
  DateTime? _selectedDeliveryDate;
  double _discountAmount = 0.0;
  double _taxAmount = 0.0;

  final _formKey = GlobalKey<FormState>();
  late final _itemNameController = TextEditingController(text: _order.itemName);
  late final _quantityController = TextEditingController(
    text: '${_order.quantity}',
  );
  late final _unitPriceController = TextEditingController(
    text: '${_order.unitPrice}',
  );
  late final _totalAmtController = TextEditingController(
    text: '${_order.totalAmount}',
  );
  late final _remarksController = TextEditingController(text: _order.remarks);
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
    _totalAmtController.dispose();
    _unitPriceController.dispose();
    _remarksController.dispose();
    _discountPercentController.dispose();
    _taxPercentController.dispose();
    super.dispose();
  }

  double _strToDouble(String s) => double.tryParse(s) ?? 0.0;

  PurchaseOrder get _orderData => PurchaseOrder(
    orderType: 'purchase order',
    storeNumber: _order.storeNumber,
    status: _selectedPOStatus ?? _order.status,
    supplierId: _selectedSupplierId ?? _order.supplierId,
    itemName: _itemNameController.text,
    quantity: int.tryParse(_quantityController.text) ?? 0,
    unitPrice: _strToDouble(_unitPriceController.text),
    payTerms: _selectedPayTerms ?? '',
    payMethod: _selectedPayMethod ?? '',
    currency: _selectedCurrency ?? '',
    deliveryDate: _selectedDeliveryDate,
    discountPercent: _strToDouble(_discountPercentController.text),
    taxPercent: _strToDouble(_taxPercentController.text),
    subTotal: double.tryParse(_subTotal) ?? _order.subTotal,
    totalAmount: _strToDouble(_totalAmtController.text),
    remarks: _remarksController.text,
    createdBy: _order.createdBy,
    updatedBy: context.employee!.fullName,
  );

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final item = _orderData;

      /// Update Orders
      context.read<PurchaseOrderBloc>().add(
        UpdateInventory<PurchaseOrder>(documentId: _order.id, data: item),
      );

      context.showAlertOverlay(
        'PO number: ${_order.id} has been successfully updated',
      );

      Navigator.pop(context);
    }
  }

  /// Update Purchase Order Status
  void _updateStatus(s) {
    _order.copyWith(status: s);
    setState(() => _selectedPOStatus = s);

    context.read<PurchaseOrderBloc>().add(
      UpdateInventory<PurchaseOrder>(
        documentId: _order.id,
        mapData: {'status': s},
      ),
    );

    context.showAlertOverlay('Changes saved');
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
        Text('Update PO Status', style: context.textTheme.titleLarge),
        const SizedBox(height: 10.0),
        POStatusDropdown(
          initialValue: _order.status,
          onChanged: (s) => _updateStatus(s),
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
        'Modify this PO',
        textAlign: TextAlign.center,
        style: context.textTheme.titleLarge,
      ),
      subtitle: Text('ID ${_order.id}'.toUpperAll, textAlign: TextAlign.center),
      childrenPadding: const EdgeInsets.only(bottom: 20.0),
      children: [
        const SizedBox(height: 20.0),
        SupplierIDInput(
          initialValue: _order.supplierId,
          onChanged: (id, name) => setState(() => _selectedSupplierId = id),
        ),
        const SizedBox(height: 20.0),
        ProductDescTextField(
          controller: _itemNameController,
          onChanged: (t) {
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
          onQtyChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        POStatusCurrencyDropdown(
          initialStatus: _order.status,
          initialCurrency: _order.currency,
          onStatusChange: (s) => setState(() => _selectedPOStatus = s),
          onCurrencyChanged: (c) => setState(() => _selectedCurrency = c),
        ),
        const SizedBox(height: 20.0),
        PayTermsAndMethodDropdown(
          initialPayTerms: _order.payTerms,
          initialPayMethod: _order.payMethod,
          onPayTermsChanged: (t) => setState(() => _selectedPayTerms = t),
          onPayMethodChanged: (t) => setState(() => _selectedPayMethod = t),
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
        const SizedBox(height: 20.0),
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
        DeliveryDateAndTotalAmtInput(
          initialDelivery: '${_order.deliveryDate}',
          enable: _isEnabledTotalAmt,
          onEdited: _toggleEditTotalAmt,
          totalAmtController: _totalAmtController,
          labelDelivery: "Delivery date",
          onDeliveryChanged: (date) =>
              setState(() => _selectedDeliveryDate = date),
          onTotalAmtChanged: (t) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        RemarksTextField(
          controller: _remarksController,
          onChanged: (t) => setState(() {}),
        ),
        const SizedBox(height: 10.0),
        context.confirmableActionButton(onPressed: _onSubmit),
      ],
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
      onChanged: (double s) => setState(() => _taxAmount = s),
    );
    _calculateTotalAmount();
  }

  void _calculateTotalAmount() {
    CalculateExtras.totalAmount(
      taxAmount: _taxAmount,
      discountAmount: _discountAmount,
      subTotal: _subTotal,
      onChanged: (double s) =>
          setState(() => _totalAmtController.text = s.toStringAsFixed(2)),
    );
  }
}
