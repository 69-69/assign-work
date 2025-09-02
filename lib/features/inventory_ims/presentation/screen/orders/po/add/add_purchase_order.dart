import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/calculate_extras.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/purchase_order_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/orders/purchase_order_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/po/widget/form_inputs.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/print_po.dart';
import 'package:assign_erp/features/setup/data/data_sources/remote/get_suppliers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AddOrderPurchaseForm on BuildContext {
  Future<void> openAddPurchaseOrders({Widget? header}) => openBottomSheet(
    isExpand: false,
    child: FormBottomSheet(
      title: 'Create Purchase Order',
      body: _AddPurchaseOrdersBody(),
    ),
  );
}

class _AddPurchaseOrdersBody extends StatefulWidget {
  const _AddPurchaseOrdersBody();

  @override
  State<_AddPurchaseOrdersBody> createState() => _AddPurchaseOrdersBodyState();
}

class _AddPurchaseOrdersBodyState extends State<_AddPurchaseOrdersBody> {
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();

  bool isMultipleOrders = false;
  final List<PurchaseOrder> _orders = [];

  bool _isEnabledTotalAmt = false;

  String _subTotal = '';
  String _newPONumber = '';
  String _selectedSupplierId = '';
  String? _selectedPOStatus;
  String? _selectedCurrency;
  String? _selectedPaymentTerms;
  String? _selectedPaymentMethod;
  DateTime? _selectedDeliveryDate;
  double _discountAmount = 0.0;
  double _taxAmount = 0.0;

  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _totalAmtController = TextEditingController();
  final _reviewController = TextEditingController();
  final _discountPercentController = TextEditingController();
  final _taxPercentController = TextEditingController();

  void _toggleEditTotalAmt() =>
      setState(() => _isEnabledTotalAmt = !_isEnabledTotalAmt);

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_calculateSubTotal);
    _unitPriceController.addListener(_calculateSubTotal);
    _discountPercentController.addListener(_calculateDiscountAmt);
    _taxPercentController.addListener(_calculateTaxAmt);
    _generatePONumber();
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
    _reviewController.dispose();
    _discountPercentController.dispose();
    _taxPercentController.dispose();
    super.dispose();
  }

  double _strToDouble(String s) => double.tryParse(s) ?? 0.0;

  void _generatePONumber() async {
    await 'purchase'.getShortUID(
      onChanged: (s) => setState(() => _newPONumber = s),
    );
  }

  PurchaseOrder get _orderData => PurchaseOrder(
    poNumber: _newPONumber,
    status: _selectedPOStatus ?? '',
    supplierId: _selectedSupplierId,
    itemName: _itemNameController.text,
    orderType: 'purchase order',
    currency: _selectedCurrency ?? '',
    quantity: int.tryParse(_quantityController.text) ?? 0,
    unitPrice: _strToDouble(_unitPriceController.text),
    payTerms: _selectedPaymentTerms ?? '',
    payMethod: _selectedPaymentMethod ?? '',
    deliveryDate: _selectedDeliveryDate,
    discountPercent: _strToDouble(_discountPercentController.text),
    taxPercent: _strToDouble(_taxPercentController.text),
    subTotal: _strToDouble(_subTotal),
    totalAmount: _strToDouble(_totalAmtController.text),
    remarks: _reviewController.text,
    storeNumber: context.employee!.storeNumber,
    createdBy: context.employee!.fullName,
  );

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      /// Added Multiple Orders Simultaneously
      _orders.add(_orderData);

      context.read<PurchaseOrderBloc>().add(
        AddInventory<List<PurchaseOrder>>(data: _orders),
      );

      _formKey.currentState!.reset();

      _clearFields();
      isMultipleOrders = false;

      _confirmPrintoutDialog();
    }

    /*// Select the message from the DataAddedState
    final message = context.select<PurchaseOrderBloc, String?>(
          (bloc) {
        final state = bloc.state;
        if (state is DataAddedState<PurchaseOrder>) {
          return state.message;
        }
        return null;
      },
    );
    final dataAdded =
        context.select<PurchaseOrderBloc, DataAddedState<PurchaseOrder>?>(
      (bloc) {
        final state = bloc.state;

        return (state is DataAddedState<PurchaseOrder>) ? state : null;
      },
    );
    dataAdded?.message;*/
  }

  /// Function for Adding Multiple Orders Simultaneously
  void _addOrderToList() {
    if (_formKey.currentState!.validate()) {
      setState(() => isMultipleOrders = true);
      _orders.add(_orderData);
      context.showAlertOverlay('PO added to list');
      _clearFields();
    }
  }

  void _clearFields() {
    _quantityController.clear();
    _itemNameController.clear();
    _unitPriceController.clear();
    _totalAmtController.clear();
    _discountPercentController.clear();
    _taxPercentController.clear();
    _discountAmount = 0.0;
    _taxAmount = 0.0;
  }

  void _removeOrder(PurchaseOrder order) {
    setState(() => _orders.remove(order));
  }

  @override
  Widget build(BuildContext context) {
    _calculateTaxAmt();
    _calculateTotalAmount();

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Wrap(
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: [
          if (isMultipleOrders && _orders.isNotEmpty) ...{
            SizedBox(height: 60, child: _buildOrderPreviewChips()),
          },
          _buildBody(),
        ],
      ),
    );
  }

  // Horizontal scrollable row of chips representing the List of batch of Orders
  Widget _buildOrderPreviewChips() {
    return CustomScrollBar(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _orders.map((o) {
          return o.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Chip(
                    padding: EdgeInsets.zero,
                    label: Text(
                      '${o.itemName} - $ghanaCedis${o.unitPrice} x ${o.quantity}'
                          .toTitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    deleteButtonTooltipMessage: 'Remove ${o.itemName}',
                    backgroundColor: kGrayColor.toAlpha(0.3),
                    deleteIcon: const Icon(
                      size: 16,
                      Icons.clear,
                      color: kGrayColor,
                    ),
                    onDeleted: () => _removeOrder(o),
                  ),
                );
        }).toList(),
      ),
    );
  }

  Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildPONumber(),
        const SizedBox(height: 10.0),
        SupplierIDInput(
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
          onStatusChange: (s) => setState(() => _selectedPOStatus = s),
          onCurrencyChange: (c) => setState(() => _selectedCurrency = c),
        ),
        const SizedBox(height: 20.0),
        PayTermsAndMethodDropdown(
          onPayTermsChange: (t) => setState(() => _selectedPaymentTerms = t),
          onPayMethodChange: (t) => setState(() => _selectedPaymentMethod = t),
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
          controller: _reviewController,
          onChanged: (t) => setState(() {}),
        ),
        const SizedBox(height: 20.0),
        context.elevatedIconBtn(
          Icons.add,
          onPressed: _addOrderToList,
          label: 'Add to List',
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(
          label: isMultipleOrders ? 'Create All POs' : 'Create PO',
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  _buildPONumber() => Align(
    alignment: Alignment.topLeft,
    child: FittedBox(
      child: context.actionInfoButton(
        'Refresh PO Number',
        count: _newPONumber,
        bgColor: kPrimaryColor,
        isTotal: false,
        onPressed: _generatePONumber,
      ),
    ),
  );

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

  Future<void> _confirmPrintoutDialog() async {
    final isConfirmed = await context.confirmAction<bool>(
      const Text('Would you like to print the purchase order: PO?'),
      title: "Print Purchase Order",
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
    // Simulate loading supplier and company info
    final sup = await GetSuppliers.bySupplierId(_orders.first.supplierId);
    if (sup.isNotEmpty) {
      // Perform action after loading
      PrintPurchaseOrder(orders: _orders, supplier: sup).onPrintPO();
    }
  });
}
