import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/calculate_extras.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/barcode_scanner.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/inventory_ims/data/models/item_model.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_order_model.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/orders/pos_order_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/pos_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/orders/widget/form_inputs.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/widget/pos_receipt_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AddPOSOrderForm on BuildContext {
  Future<void> openAddPOSOrder({Widget? header}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(title: 'Create Order', body: _AddOrderForm()),
  );
}

class _AddOrderForm extends StatefulWidget {
  const _AddOrderForm();

  @override
  State<_AddOrderForm> createState() => _AddOrderFormState();
}

class _AddOrderFormState extends State<_AddOrderForm> {
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();

  // Indicates whether the orders are to be placed on the same invoice
  bool _ordersOnSameInvoice = false;
  bool _isEnabledTotalAmt = false;
  bool isMultipleOrders = false;

  double _itemCostPrice = 0.0;
  double _discountAmount = 0.0;
  double _taxAmount = 0.0;

  String _newOrderNumber = '';
  String _selectedCustomerId = '';
  String _selectedItemId = '';
  String _selectedItemName = '';
  String? _selectedOrderStatus;
  String? _selectedPayMethod;

  final List<POSOrder> _orders = [];

  /// Maps each product's ID to its cost price for sales recording purposes [_costPricesMap]
  final Map<String, double> _costPricesMap = {};

  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _subTotalController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _totalAmtController = TextEditingController();
  final _discountPercentController = TextEditingController();
  final _taxPercentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_calculateSubTotal);
    _unitPriceController.addListener(_calculateSubTotal);
    _discountPercentController.addListener(_calculateDiscountAmt);
    _taxPercentController.addListener(_calculateTaxAmt);
    _generateOrderNumber();
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

  void _toggleCheckbox(bool? value) {
    setState(() => _ordersOnSameInvoice = value ?? false);
  }

  void _toggleEditTotalAmt() {
    setState(() => _isEnabledTotalAmt = !_isEnabledTotalAmt);
  }

  double _strToDouble(String s) => double.tryParse(s) ?? 0.0;

  // Updates the item details in the form based on the provided Product instance.
  // Sets the unit price, product ID, item name, and cost price.
  set _setItemId(Item p) {
    _unitPriceController.text = '${p.sellingPrice}';
    _selectedItemId = p.id;
    _selectedItemName = p.name;
    _itemCostPrice = p.costPrice;
  }

  void _generateOrderNumber() async {
    await DocType.pOrder.getShortUID(
      onChanged: (s) => setState(() => _newOrderNumber = s),
    );
  }

  POSOrder get _orderData => POSOrder(
    orderNumber: _newOrderNumber,
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
    createdBy: context.employee!.fullName,
  );

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      _orders.add(_orderData);
      // Maps each product's ID to its cost price for sales recording purposes
      _costPricesMap.addAll({_orderData.itemId: _itemCostPrice});

      context.read<POSOrderBloc>().add(AddPOS<List<POSOrder>>(data: _orders));

      _formKey.currentState!.reset();

      _recordNewSales();
      _clearFields();
      isMultipleOrders = false;

      if (_ordersOnSameInvoice) {
        _confirmPrintoutDialog();
      }

      _formKey.currentState!.reset();
      Navigator.pop(context);
    }
  }

  void _recordNewSales() {
    if (_orders.isNotEmpty) {
      context.read<POSOrderBloc>().createNewSalesForOrder(
        _orders,
        _costPricesMap,
      );
    }
  }

  /// Function for Adding Multiple Orders Simultaneously
  void _addOrderToList() {
    if (_formKey.currentState!.validate()) {
      setState(() => isMultipleOrders = true);
      _orders.add(_orderData);

      if (_itemCostPrice > 0) {
        prettyPrint('addOrderToList', 'form data added');
        _costPricesMap.addAll({_orderData.itemId: _itemCostPrice});
      }

      context.showAlertOverlay('Order added to list');
      _clearFields();
    }
  }

  void _clearFields() {
    _quantityController.clear();
    _barcodeController.clear();
    _subTotalController.clear();
    _totalAmtController.clear();
    _discountPercentController.clear();
    _taxPercentController.clear();
    _selectedItemId = '';
    _selectedItemName = '';
    _selectedOrderStatus = null;
    _discountAmount = 0.0;
    _taxAmount = 0.0;
  }

  void _removeOrder(POSOrder order) {
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
          if (isMultipleOrders && _orders.isNotEmpty) _buildOrderPreviewChips(),
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

  _buildOrderNumber() => Align(
    alignment: Alignment.topLeft,
    child: FittedBox(
      child: context.actionInfoButton(
        'Refresh Order Number',
        count: _newOrderNumber,
        bgColor: kPrimaryColor,
        isTotal: false,
        onPressed: _generateOrderNumber,
      ),
    ),
  );

  _buildBody() {
    return Column(
      children: <Widget>[
        _buildOrderNumber(),
        const SizedBox(height: 10.0),
        CustomerAndItemId(
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
          onItemChanged: (product) => setState(() => _setItemId = product),
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
        Wrap(
          direction: Axis.vertical,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _ordersOnSameInvoice,
                  onChanged: _toggleCheckbox,
                ),
                const Text(
                  'Are these orders on the same receipt?',
                  style: TextStyle(color: kDangerColor),
                ),
              ],
            ),
            context.elevatedIconBtn(
              Icons.add,
              onPressed: _addOrderToList,
              label: 'Add to List',
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(
          label: isMultipleOrders ? 'Create All Orders' : 'Create Order',
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  void _calculateSubTotal() {
    CalculateExtras.subTotal(
      qty: _quantityController.text,
      unitPrice: _unitPriceController.text,
      onChanged: (String s) => setState(() => _subTotalController.text = s),
    );
    _calculateTotalAmount();
  }

  void _calculateDiscountAmt() {
    CalculateExtras.discountAmount(
      discountPercent: _discountPercentController.text,
      subTotal: _subTotalController.text,
      onChanged: (double s) => setState(() => _discountAmount = s),
    );
    _calculateTotalAmount();
  }

  void _calculateTaxAmt() {
    CalculateExtras.taxAmount(
      taxPercent: _taxPercentController.text,
      subTotal: _subTotalController.text,
      discountAmt: _discountAmount,
      onChanged: (double s) => setState(() => _taxAmount = s),
    );
    _calculateTotalAmount();
  }

  void _calculateTotalAmount() {
    CalculateExtras.totalAmount(
      taxAmount: _taxAmount,
      discountAmount: _discountAmount,
      subTotal: _subTotalController.text,
      onChanged: (double s) =>
          setState(() => _totalAmtController.text = s.toStringAsFixed(2)),
    );
  }

  Future<void> _confirmPrintoutDialog() async {
    final isConfirmed = await context.confirmAction<bool>(
      const Text('Would you prefer to print out receipt?'),
      title: "Receipt Option",
      onAcceptLabel: "Print",
      onRejectLabel: "Cancel",
    );

    if (mounted && isConfirmed) {
      // Show progress dialog while loading data
      await context.progressBarDialog(
        request: _printout(),
        onSuccess: (_) =>
            context.showAlertOverlay('Order successfully created'),
        onError: (error) => context.showAlertOverlay(
          'Receipt printout failed',
          bgColor: kDangerColor,
        ),
      );
    }
  }

  Future<dynamic> _printout() => Future.delayed(kRProgressDelay, () async {
    if (mounted) {
      POSReceiptPrinter(
        orders: _orders,
        storeNumber: context.employee!.storeNumber,
        customerId: _orders.first.customerId,
      ).printReceipt();
    }
  });
}
