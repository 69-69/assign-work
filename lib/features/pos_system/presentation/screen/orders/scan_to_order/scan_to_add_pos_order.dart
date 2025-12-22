import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/doc_type_enum.dart';
import 'package:assign_erp/core/util/generate_new_uid.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/barcode_scanner.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/inventory_ims/data/data_sources/remote/get_items.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_order_model.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/orders/pos_order_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/pos_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/widget/pos_receipt_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/*extension PosScanProduct on BuildContext {
  Future<void> openPosScan({Widget? header}) => openBottomSheet(
        isExpand: false,
        child: _AddOrder(header: header),
      );
}*/

class ScanToAddOrder extends StatelessWidget {
  ScanToAddOrder({super.key});

  @override
  Widget build(BuildContext context) {
    return context.buildFloatingBtn(
      '',
      tooltip: 'Scan Product',
      icon: Icons.qr_code_scanner,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      onPressed: () async {
        final deviceOS = context.deviceOSType;
        if (deviceOS.android || deviceOS.ios) {
          await _scanProduct(context);
        } else {
          await context.showItemScanWarningDialog();
        }
      },
    );
  }

  final List<POSOrder> _orders = [];

  /// Maps each product's ID to its cost price for sales recording purposes [_costPricesMap]
  final Map<String, double> _costPricesMap = {};

  Future<void> _scanProduct(BuildContext context) async {
    await context.scanBarcode(
      barcode: (s) async {
        if (s.isNotEmpty) {
          // Fetch product by barcode
          final product = await GetItems.findByBarcode(s.trim());

          if (context.mounted && product != null) {
            // Maps each product's ID to its cost price for sales recording purposes
            _updateCostPricesMap(product.id, product.costPrice);

            POSOrder order = POSOrder(
              orderNumber: '',
              customerId: '',
              status: 'completed',
              barcode: product.barcode,
              itemId: product.id,
              itemName: product.name,
              unitPrice: product.sellingPrice,
              quantity: 1,
              discountAmount: product.discountAmt,
              discountPercent: product.discountPercent,
              totalAmount: (product.sellingPrice - product.discountAmt),
              payMethod: 'cash',
              storeNumber: context.employee!.storeNumber,
              createdBy: context.employee!.fullName,
            );

            _updateOrAddOrder(order);

            if (_orders.isNotEmpty) {
              // Show Scanned Product in Bottom Sheet dialog
              context.openBottomSheet(
                isExpand: false,
                child: _customBottomSheet(context),
              );
            }
          }
        }
      },
    );
  }

  CustomDraggableBottomSheet _customBottomSheet(BuildContext context) {
    return CustomDraggableBottomSheet(
      padding: EdgeInsets.only(bottom: context.bottomInsetPadding),
      initialChildSize: 0.90,
      maxChildSize: 0.90,
      header: _buildHeader(context),
      child: _ScannedItems(
        orders: _orders,
        costPrices: _costPricesMap,
        existingQuantity: (String itemId, int qty) {
          _existingQuantityUpdate(itemId, qty);
        },
      ),
    );
  }

  void _existingQuantityUpdate(String itemId, int qty) {
    if (itemId.isNotEmpty) {
      final index = _orders.indexWhere((order) => order.itemId == itemId);

      // Order exists, update quantity
      if (index != -1) {
        if (qty > 0) {
          final existingOrder = _orders[index];
          final updatedOrder = existingOrder.copyWith(quantity: qty);
          _orders[index] = updatedOrder;
        } else {
          _orders.removeAt(index);
        }
      }
    }
  }

  DialogHeader _buildHeader(BuildContext context) {
    return DialogHeader(
      title: Text(
        'Scan Product'.toTitle,
        semanticsLabel: 'Scan Product',
        style: context.textTheme.titleLarge?.copyWith(color: kGrayColor),
      ),
      btnText: ElevatedButton(
        onPressed: () async {
          await _scanProduct(context);
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: kSuccessColor,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: const Text('Scan Next', style: TextStyle(color: kWhiteColor)),
      ),
      onCancel: () => Navigator.pop(context),
    );
  }

  // Maps each product's ID to its cost price for sales recording purposes
  void _updateCostPricesMap(String pId, double pCost) {
    // _costPricesMap.addAll({pId: pCost});
    _costPricesMap[pId] = pCost;
  }

  void _updateOrAddOrder(POSOrder newOrder) {
    // Check if an order with the same product ID or barcode exists
    final index = _orders.indexWhere(
      (existingOrder) =>
          existingOrder.itemId == newOrder.itemId ||
          existingOrder.barcode == newOrder.barcode,
    );

    if (index != -1) {
      // Order exists, update it
      final existingOrder = _orders[index];

      var qty = existingOrder.quantity + newOrder.quantity;
      var subTotal = qty * existingOrder.unitPrice;

      final updatedOrder = existingOrder.copyWith(
        quantity: qty,
        totalAmount: (subTotal - newOrder.discountAmount),
      );
      _orders[index] = updatedOrder;
    } else {
      // Order does not exist, add a new one
      _orders.add(newOrder);
    }
  }
}

class _ScannedItems extends StatefulWidget {
  final List<POSOrder> orders;
  final Map<String, double> costPrices;
  final Function(String, int) existingQuantity;

  const _ScannedItems({
    required this.costPrices,
    required this.orders,
    required this.existingQuantity,
  });

  @override
  State<_ScannedItems> createState() => _ScannedItemsState();
}

class _ScannedItemsState extends State<_ScannedItems> {
  String? _customerId;
  String? _newOrderNumber;
  double _finalAmount = 0.0;
  late List<POSOrder> _orders;
  bool _continueToCheckout = false;

  /// Maps each product's ID to its cost price for sales recording purposes [_costPricesMap]
  late Map<String, double> _costPricesMap;

  @override
  void initState() {
    super.initState();
    _initializeOrderDetails();
    _orders = widget.orders;
    _costPricesMap = widget.costPrices;
  }

  Future<void> _initializeOrderDetails() async {
    _newOrderNumber = (await DocType.pOrder.getShortStr());
    _customerId = (await DocType.customer.getShortStr());
  }

  void _updateOrder(int index, int quantity) {
    setState(() {
      var order = _orders[index];
      double subTotal = order.unitPrice * quantity;
      double newTotalAmount = subTotal - order.discountAmount;

      _orders[index] = order.copyWith(
        quantity: quantity,
        totalAmount: newTotalAmount,
      );

      widget.existingQuantity(order.itemId, order.quantity);
    });
  }

  void _removeOrderAt(int index) {
    var ord = _orders[index];
    setState(() => _orders.removeAt(index));

    widget.existingQuantity(ord.itemId, 0);
  }

  // Adding an item at specific index
  void _addOrderAt(int index, POSOrder order) {
    setState(() => _orders.insert(index, order));
  }

  Future<void> _onCheckout() async {
    if (_orders.isEmpty) return;

    final ordersData = _orders.map((order) {
      return order.copyWith(
        orderNumber: _newOrderNumber,
        customerId: _customerId,
      );
    }).toList();

    context.read<POSOrderBloc>().add(AddPOS<List<POSOrder>>(data: ordersData));

    _recordNewSales(ordersData);
    await _confirmPrintoutDialog();
  }

  void _recordNewSales(List<POSOrder> orders) {
    if (orders.isNotEmpty) {
      context.read<POSOrderBloc>().createNewSalesForOrder(
        orders,
        _costPricesMap,
      );
    }
  }

  void _onContinue() {
    setState(() {
      _continueToCheckout = true;
      _finalAmount = _orders.fold(0.0, (sum, p) => sum + p.totalAmount);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
      child: _orders.isEmpty
          ? const Text('Scan to add products')
          : _buildBody(context),
    );
  }

  _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ..._orders.asMap().entries.map((entry) {
          var index = entry.key;
          POSOrder order = entry.value;

          return order.isEmpty
              ? const SizedBox.shrink()
              : _slideToRemoveOrder(
                  index: index,
                  order: order,
                  child: _continueToCheckout
                      ? _buildCheckoutCard(order)
                      : _buildProductCard(order, index),
                );
        }),
        if (_continueToCheckout) ...{_totalAmtCard(context)},
        const SizedBox(height: 20),
        _slideToContinue(),
      ],
    );
  }

  RichText _totalAmtCard(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: 'Total Amount: ',
        style: context.textTheme.titleLarge,
        children: [
          TextSpan(
            text: '$ghanaCedis${_finalAmount.toCurrency}',
            style: const TextStyle(
              color: kDangerColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  ListTile _buildProductCard(POSOrder order, int index) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      minTileHeight: 48,
      title: Text(
        softWrap: true,
        order.itemName.toTitle,
        style: context.textTheme.titleMedium,
      ),
      subtitle: Text(
        softWrap: true,
        '$ghanaCedis${order.unitPrice.toCurrency} X ${order.quantity} = $ghanaCedis${order.totalAmount.toCurrency}',
        style: context.textTheme.labelSmall,
      ),
      trailing: _QtyCount(
        quantity: order.quantity,
        qtyChanged: (quantity) {
          if (quantity == 0) {
            _removeOrderAt(index);
          } else {
            _updateOrder(index, quantity);
          }
        },
      ),
    );
  }

  ListTile _buildCheckoutCard(POSOrder order) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      minTileHeight: 48,
      title: Text(
        softWrap: true,
        order.itemName.toTitle,
        style: context.textTheme.titleMedium,
      ),
      subtitle: Text(
        softWrap: true,
        '$ghanaCedis${order.unitPrice.toCurrency} X ${order.quantity} = $ghanaCedis${order.totalAmount.toCurrency}',
        style: context.textTheme.labelSmall,
      ),
    );
  }

  Dismissible _slideToRemoveOrder({
    required POSOrder order,
    required int index,
    Widget? child,
  }) {
    return Dismissible(
      key: ValueKey('${order.itemId}$index'),
      direction: DismissDirection.endToStart,
      behavior: HitTestBehavior.translucent,
      background: _buildBackground(
        kDangerColor.toAlpha(0.4),
        Icons.delete,
        kDangerColor,
      ),
      onDismissed: (direction) {
        _removeOrderAt(index);

        context.showAlertOverlay(
          '${order.itemName.toUpperAll} removed from list',
          label: 'Undo',
          onPressed: () => _addOrderAt(index, order),
        );
      },
      child: child!,
    );
  }

  Dismissible _slideToContinue() {
    final icon = _continueToCheckout
        ? Icons.shopping_basket_outlined
        : Icons.done;
    return Dismissible(
      key: ValueKey('$_continueToCheckout-action'),
      behavior: HitTestBehavior.translucent,
      background: _buildBackground(kLightBlueColor, icon, kPrimaryColor),
      direction: _continueToCheckout
          ? DismissDirection.horizontal
          : DismissDirection.startToEnd,
      // Only allow start-to-end swipe when not in checkout mode
      secondaryBackground: _buildBackground(
        kDangerColor.toAlpha(0.4),
        Icons.arrow_back,
        kDangerColor,
      ),
      onDismissed: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Handle swipe from start to end
          _continueToCheckout ? await _onCheckout() : _onContinue();
        } else if (direction == DismissDirection.endToStart) {
          // Handle swipe from end to start
          if (_continueToCheckout) {
            // Reset the state if needed and handle end-to-start action
            setState(() => _continueToCheckout = false);
          }
        }
      },
      child: _slideButton(),
    );
  }

  Row _slideButton() {
    return Row(
      children: [
        Expanded(
          child: context.elevatedIconBtn(
            const Icon(Icons.swap_horiz, color: kWhiteColor),
            onPressed: () {},
            label: Text(
              'Swipe to ${_continueToCheckout ? 'Checkout' : 'Continue'}',
              style: const TextStyle(color: kWhiteColor),
            ),
            style: ButtonStyle(
              padding: const WidgetStatePropertyAll(EdgeInsets.all(15)),
              backgroundColor: WidgetStatePropertyAll(context.secondaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackground(Color color, IconData icon, Color iconColor) {
    var dir =
        icon == Icons.done ||
        icon == Icons.shopping_basket_outlined ||
        icon == Icons.delete;
    return Container(
      color: color,
      alignment: dir ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Icon(icon, color: iconColor),
    );
  }

  Future<void> _confirmPrintoutDialog() async {
    final isConfirmed = await context.confirmAction<bool>(
      const Text('Would you prefer to print out the receipt?'),
      title: "Receipt Option",
      onAcceptLabel: "Print",
      onRejectLabel: "Cancel",
    );

    if (mounted && isConfirmed) {
      await context.progressBarDialog(
        request: _printout(),
        onSuccess: (_) {
          context.showAlertOverlay('Order successfully created');
          setState(() => _continueToCheckout = false);

          Navigator.pop(context);
        },
        onError: (error) => context.showAlertOverlay(
          'Receipt printout failed',
          bgColor: kDangerColor,
        ),
      );
    }
  }

  Future<void> _printout() async {
    await Future.delayed(kRProgressDelay);
    if (mounted) {
      POSReceiptPrinter(
        orders: _orders,
        storeNumber: context.employee!.storeNumber,
        customerId: _orders.first.customerId,
      ).printReceipt();
    }
  }
}

class _QtyCount extends StatefulWidget {
  final int quantity;
  final Function(int) qtyChanged;

  const _QtyCount({required this.qtyChanged, required this.quantity});

  @override
  State<_QtyCount> createState() => _QtyCountState();
}

class _QtyCountState extends State<_QtyCount> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.quantity;
  }

  void _increment() {
    setState(() {
      _count++;
      widget.qtyChanged(_count);
    });
  }

  void _decrement() {
    setState(() {
      if (_count > 0) {
        _count--;
        widget.qtyChanged(_count);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildIconButton(
          'Increase quantity',
          icon: Icons.remove_circle_outline,
          onPressed: _decrement,
        ),
        const SizedBox(width: 10),
        Text('$_count', style: context.textTheme.labelLarge),
        const SizedBox(width: 10),
        _buildIconButton(
          'Decrease quantity',
          icon: Icons.add_circle_outline,
          onPressed: _increment,
        ),
      ],
    );
  }

  IconButton _buildIconButton(
    String tooltip, {
    IconData? icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: kPrimaryColor),
      style: IconButton.styleFrom(
        elevation: 20,
        backgroundColor: kLightBlueColor.toAlpha(0.5),
        padding: EdgeInsets.zero,
      ),
      onPressed: onPressed,
    );
  }
}

/*BarcodeScanner _buildBarcodeScanner(BuildContext context) {
    return BarcodeScanner(
      childWidget: (void Function()? scanFunction, List<Barcode> barcodes) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (context.mounted && barcodes.isNotEmpty) {
            barcodeValue.call(barcodes.first.displayValue);
          }
        });
        return FloatingActionButton(
          onPressed: scanFunction,
          tooltip: 'Scan Product',
          child: const Icon(Icons.qr_code_scanner),
        );
      },
    );
  }*/
