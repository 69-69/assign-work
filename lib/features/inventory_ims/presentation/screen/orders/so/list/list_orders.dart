import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/customer_crm/data/data_sources/remote/get_customers.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/order_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/orders/order_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/so/create/create_order.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/orders/so/update/update_order.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/sales_doc_printer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// LIST SALES ORDERS
class ListOrders extends StatefulWidget {
  const ListOrders({super.key});

  @override
  State<ListOrders> createState() => _ListOrdersState();
}

class _ListOrdersState extends State<ListOrders> {
  // List to group orders for printout
  final List<Orders> _groupOrdersForPrintout = [];

  //  oBloc = BlocProvider.of<OrdersBloc>(context);

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  BlocBuilder<OrderBloc, InventoryState<Orders>> _buildBody() {
    return BlocBuilder<OrderBloc, InventoryState<Orders>>(
      builder: (context, state) {
        return switch (state) {
          LoadingInventory<Orders>() => context.loader,
          InventoriesLoaded<Orders>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Place an Order',
                    onPressed: () => context.openAddOrder(),
                  )
                : _buildCard(context, results),
          InventoryError<Orders>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext context, List<Orders> orders) {
    final todayOrders = Orders.filterOrdersByDate(orders);
    final pastOrders = Orders.filterOrdersByDate(orders, isSameDay: false);

    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 3,
      headers: Orders.dataTableHeader,
      anyWidget: _buildAnyWidget(orders),
      rows: todayOrders.map((o) => o.itemAsList()).toList(),
      childrenRow: pastOrders.map((o) => o.itemAsList()).toList(),
      onChecked: (bool? isChecked, row) =>
          _onChecked(orders, isChecked, row.first),
      onAllChecked:
          (
            bool isChecked,
            List<bool> isAllChecked,
            List<List<String>> checkedRows,
          ) {
            // if all unChecked, empty _groupOrdersForPrintout List
            if (!isAllChecked.first) {
              setState(() => _groupOrdersForPrintout.clear());
            }
            if (checkedRows.isNotEmpty) {
              for (int i = 0; i < checkedRows.length; i++) {
                final id = checkedRows[i].first;
                _onChecked(orders, isChecked, id);
              }
            }
          },
      optButtonLabel: 'Print',
      onOptButtonTap: (row) async => await _onInvoiceTap(orders, row.first),
      onEditTap: (row) async => await _onEditTap(orders, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(orders, row.first),
    );
  }

  _buildAnyWidget(List<Orders> orders) {
    return AdaptiveLayout(
      isFormBuilder: false,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        context.actionInfoButton(
          'Refresh Orders',
          label: 'Orders',
          count: orders.length,
          // Dispatch an event to refresh data
          onPressed: () {
            // Refresh Orders Data
            context.read<OrderBloc>().add(RefreshInventories<Orders>());
          },
        ),
        // final orderBloc = context.read<OrdersBloc>();
        // final orderBloc = BlocProvider.of<OrdersBloc>(context, listen: false);
        const SizedBox(height: 20),
        _IssueMultiInvoicePrintout(
          orders: _groupOrdersForPrintout,
          onDone: (s) => setState(() => _groupOrdersForPrintout.clear()),
        ),
      ],
    );
  }

  /// Check if selected Orders are related by orderNumber [_haveSameOrderNumber]
  /// @Return: return Pattern, i.e ({bool a, String b})
  ({bool isSame, String misMatchID}) _haveSameOrderNumber(
    List<Orders> selectedOrders,
  ) {
    if (selectedOrders.isEmpty) {
      return (isSame: true, misMatchID: ''); // Handle empty list
    }

    String misMatchOrderNumber = '';
    final firstOrderNumber = selectedOrders.first.orderNumber;

    var isSame = selectedOrders.every((order) {
      misMatchOrderNumber = order.orderNumber;

      return order.orderNumber == firstOrderNumber;
    });

    return (isSame: isSame, misMatchID: misMatchOrderNumber);
  }

  // Handle onChecked orders
  void _onChecked(List<Orders> orders, bool? isChecked, String id) async {
    setState(() {
      final order = orders.firstWhere((order) => order.id == id);

      if (isChecked != null && isChecked) {
        // A temporary list, tempOrdersForInvoice, is created which includes
        // the current orders in _ordersForInvoice and the new order to be checked.
        List<Orders> tempOrdersForInvoice = List.from(_groupOrdersForPrintout)
          ..add(order);
        ({bool isSame, String misMatchID}) r = _haveSameOrderNumber(
          tempOrdersForInvoice,
        );

        // Orders have same order-No.
        if (r.isSame) {
          _groupOrdersForPrintout.add(order);
        } else {
          context.orderNumberMisMatchWarningDialog(r.misMatchID);
        }
      } else {
        _groupOrdersForPrintout.remove(order);
      }
    });
  }

  _onInvoiceTap(List<Orders> orders, String id) async {
    // Show progress dialog while loading data
    await context.progressBarDialog(
      request: _printout(orders, id),
      onSuccess: (_) =>
          context.showAlertOverlay('Printout successfully created'),
      onError: (error) => context.showAlertOverlay(
        'Proforma Invoice printout failed',
        bgColor: kDangerColor,
      ),
    );
  }

  Future<dynamic> _printout(List<Orders> orders, String id) =>
      Future.delayed(kRProgressDelay, () async {
        // Simulate loading supplier and company info
        final getOrders = Orders.findOrderById(orders, id).toList();
        final cus = await GetAllCustomers.byCustomerId(
          getOrders.first.customerId,
        );

        if (getOrders.isNotEmpty && cus.isNotEmpty) {
          SalesDocPrinter(
            orders: getOrders,
            customer: cus,
          ).printDoc(title: 'proforma invoice');
        }
      });

  Future<void> _onEditTap(List<Orders> orders, String id) async {
    final order = Orders.findOrderById(orders, id).first;

    await context.openUpdateOrder(order: order);
  }

  Future<void> _onDeleteTap(List<Orders> orders, String id) async {
    final order = Orders.findOrderById(orders, id).first;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      /// Remove order from Orders-DB
      context.read<OrderBloc>().add(
        DeleteInventory<String>(documentId: order.id),
      );
    }
  }
}

/// Print grouped or multiple Purchase Orders [_IssueMultiInvoicePrintout]
class _IssueMultiInvoicePrintout extends StatelessWidget {
  final List<Orders> orders;
  final Function(bool) onDone;

  const _IssueMultiInvoicePrintout({
    required this.orders,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return orders.isEmpty
        ? const SizedBox.shrink()
        : Center(child: _buildBody(context));
  }

  _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Wrap(
        spacing: 20,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          _buildPrintButton(context),
          _buildNote(),
          _buildDeleteButton(context),
        ],
      ),
    );
  }

  _buildPrintButton(BuildContext context) {
    return context.elevatedIconBtn(
      Icon(Icons.print, color: kWarningColor),
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: kWarningColor),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      onPressed: () async {
        final cus = await GetAllCustomers.byCustomerId(orders.first.customerId);

        SalesDocPrinter(
          orders: orders,
          customer: cus,
        ).printDoc(title: 'proforma invoice');
      },
      label: const Text('Print', style: TextStyle(color: kWarningColor)),
    );
  }

  Future<bool> _confirmDeleteDialog(BuildContext context) async {
    return context.confirmAction<bool>(
      const Text('Are you sure you want to delete the selected orders?'),
      title: "Confirm Delete",
      onAcceptLabel: "Delete",
      onRejectLabel: "Cancel",
    );
  }

  _buildDeleteButton(BuildContext context) {
    return context.elevatedIconBtn(
      Icon(Icons.delete, color: kWhiteColor),
      style: OutlinedButton.styleFrom(backgroundColor: context.errorColor),
      onPressed: () async {
        final isConfirmed = await _confirmDeleteDialog(context);
        if (context.mounted && isConfirmed) {
          final ids = orders.map((o) => o.id).toList();

          // Remove order from Orders-DB
          OrderBloc(
            firestore: FirebaseFirestore.instance,
          ).add(DeleteInventory<List<String>>(documentId: ids));

          // Check if totalDeleted isEqual to total orders,
          // is so, then deletion completed
          onDone(true);

          /* int totalDeleted = 0;
            totalDeleted++;
            for (var order in orders) {}
            if (totalDeleted == orders.length) {
              onDone(true);
            }*/
        }
      },
      label: const Text('Delete', style: TextStyle(color: kWhiteColor)),
    );
  }

  Padding _buildNote() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: RichText(
        text: const TextSpan(
          text: 'NOTE: ',
          style: TextStyle(color: kDangerColor, fontWeight: FontWeight.bold),
          children: [
            TextSpan(
              text:
                  'Multiple or Grouped Orders Must Have Identical Order Numbers',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
