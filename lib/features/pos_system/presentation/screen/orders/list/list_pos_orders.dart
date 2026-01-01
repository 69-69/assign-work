import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/pos_system/data/models/pos_order_model.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/orders/pos_order_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/bloc/pos_bloc.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/orders/create/create_pos_order.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/orders/update/update_pos_order.dart';
import 'package:assign_erp/features/pos_system/presentation/screen/widget/pos_receipt_printer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// LIST POS ORDERS
class ListPOSOrders extends StatefulWidget {
  const ListPOSOrders({super.key});

  @override
  State<ListPOSOrders> createState() => _ListPOSOrdersState();
}

class _ListPOSOrdersState extends State<ListPOSOrders> {
  // List to group orders for printout
  final List<POSOrder> _groupOrdersForPrintout = [];

  //  oBloc = BlocProvider.of<OrdersBloc>(context);

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  BlocBuilder<POSOrderBloc, POSState<POSOrder>> _buildBody() {
    return BlocBuilder<POSOrderBloc, POSState<POSOrder>>(
      builder: (context, state) {
        return switch (state) {
          LoadingPOS<POSOrder>() => context.loader,
          POSsLoaded<POSOrder>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Place an Order',
                    onPressed: () => context.openAddPOSOrder(),
                  )
                : _buildCard(context, results),
          POSError<POSOrder>(error: final error) => context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext context, List<POSOrder> orders) {
    final todayOrders = POSOrder.filterOrdersByDate(orders);
    final pastOrders = POSOrder.filterOrdersByDate(orders, isSameDay: false);

    return DynamicDataTable(
      omitAtIndex: 0,
      toolbar: _buildToolbar(orders),
      headers: POSOrder.dataTableHeader,
      rows: todayOrders.map((o) => o.itemAsList).toList(),
      childrenRow: pastOrders.map((o) => o.itemAsList).toList(),
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
      optButtonLabel: 'Receipt',
      onOptButtonTap: (row) async => await _onInvoiceTap(orders, row.first),
      onEditTap: (row) async => await _onEditTap(orders, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(orders, row.first),
    );
  }

  _buildToolbar(List<POSOrder> orders) {
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
            // Refresh POS-Orders data
            context.read<POSOrderBloc>().add(RefreshPOSs<POSOrder>());
          },
        ),
        // final orderBloc = context.read<OrdersBloc>();
        // final orderBloc = BlocProvider.of<OrdersBloc>(context, listen: false);
        const SizedBox(height: 20),
        _IssueMultiReceipts(
          orders: _groupOrdersForPrintout,
          onDone: (s) => setState(() => _groupOrdersForPrintout.clear()),
        ),
      ],
    );
  }

  /// Check if selected Orders are related by orderNumber [_haveSameOrderNumber]
  /// @Return: return Pattern, i.e ({bool a, String b})
  ({bool isSame, String misMatchID}) _haveSameOrderNumber(
    List<POSOrder> selectedOrders,
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
  void _onChecked(List<POSOrder> orders, bool? isChecked, String id) async {
    setState(() {
      final order = orders.firstWhere((order) => order.id == id);

      if (isChecked != null && isChecked) {
        // A temporary list, tempOrdersForInvoice, is created which includes
        // the current orders in _ordersForInvoice and the new order to be checked.
        List<POSOrder> tempOrdersForInvoice = List.from(_groupOrdersForPrintout)
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

  _onInvoiceTap(List<POSOrder> orders, String id) async {
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

  Future<dynamic> _printout(List<POSOrder> orders, String id) =>
      Future.delayed(kRProgressDelay, () async {
        // Simulate loading supplier and company info
        final getOrders = POSOrder.findOrdersById(orders, orderId: id).toList();
        if (mounted && getOrders.isNotEmpty) {
          POSReceiptPrinter(
            orders: getOrders,
            storeNumber: context.employee!.storeNumber,
            customerId: getOrders.first.customerId,
          ).printReceipt();
        }
      });

  Future<void> _onEditTap(List<POSOrder> orders, String id) async {
    final order = POSOrder.findOrdersById(orders, orderId: id).first;

    await context.openUpdatePOSOrder(order: order);
  }

  Future<void> _onDeleteTap(List<POSOrder> orders, String id) async {
    {
      final order = POSOrder.findOrdersById(orders, orderId: id).first;

      final isConfirmed = await context.confirmUserActionDialog();
      if (mounted && isConfirmed) {
        /// Remove order from Orders-DB
        context.read<POSOrderBloc>().add(
          DeletePOS<String>(documentId: order.id),
        );
      }
    }
  }
}

/// Print grouped or multiple Receipts [_IssueMultiReceipts]
class _IssueMultiReceipts extends StatelessWidget {
  final List<POSOrder> orders;
  final Function(bool) onDone;

  const _IssueMultiReceipts({required this.orders, required this.onDone});

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
        POSReceiptPrinter(
          orders: orders,
          storeNumber: context.employee!.storeNumber,
          customerId: orders.first.customerId,
        ).printReceipt();
      },
      label: const Text('Receipt', style: TextStyle(color: kWarningColor)),
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
          POSOrderBloc(
            firestore: FirebaseFirestore.instance,
          ).add(DeletePOS<List<String>>(documentId: ids));

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
