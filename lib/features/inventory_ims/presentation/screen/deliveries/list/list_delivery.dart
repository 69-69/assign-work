import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/customer_crm/data/data_sources/remote/get_customers.dart';
import 'package:assign_erp/features/inventory_ims/data/data_sources/remote/get_orders.dart';
import 'package:assign_erp/features/inventory_ims/data/models/delivery_model.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/delivery/delivery_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/bloc/inventory_bloc.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/deliveries/add/add_delivery.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/deliveries/update/update_delivery.dart';
import 'package:assign_erp/features/inventory_ims/presentation/screen/widget/sales_doc_printer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// All Deliveries
class ListDeliveries extends StatefulWidget {
  const ListDeliveries({super.key});

  @override
  State<ListDeliveries> createState() => _ListDeliveriesState();
}

class _ListDeliveriesState extends State<ListDeliveries> {
  final List<Delivery> _groupMultiDelete = [];

  // final SaleBloc saleBloc = BlocProvider.of<SaleBloc>(context);

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  BlocBuilder<DeliveryBloc, InventoryState<Delivery>> _buildBody() {
    return BlocBuilder<DeliveryBloc, InventoryState<Delivery>>(
      builder: (context, state) {
        return switch (state) {
          LoadingInventory<Delivery>() => context.loader,
          InventoriesLoaded<Delivery>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Add Delivery',
                    onPressed: () => context.openAddDelivery(),
                  )
                : _buildCard(context, results),
          InventoryError<Delivery>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext context, List<Delivery> deliveries) {
    final pendingDeliveries = Delivery.filterDeliveriesByDate(
      deliveries,
      isSameDay: true,
    );
    final deliveredDeliveries = Delivery.filterDeliveriesByDate(deliveries);

    return DynamicDataTable(
      omitAtIndex: 0,
      headers: Delivery.dataHeader,
      anyWidget: _buildAnyWidget(deliveries),
      rows: pendingDeliveries.map((d) => d.itemAsList()).toList(),
      childrenRow: deliveredDeliveries.map((d) => d.itemAsList()).toList(),
      onChecked: (bool? isChecked, row) =>
          _onChecked(deliveries, isChecked, row.first),
      onAllChecked:
          (
            bool isChecked,
            List<bool> isAllChecked,
            List<List<String>> checkedRows,
          ) {
            // if all unChecked, empty _groupReportsForPrintout List
            if (!isAllChecked.first) {
              setState(() => _groupMultiDelete.clear());
            }
            if (checkedRows.isNotEmpty) {
              for (int i = 0; i < checkedRows.length; i++) {
                final id = checkedRows[i].first;
                _onChecked(deliveries, isChecked, id);
              }
            }
          },
      optButtonLabel: 'Print',
      onOptButtonTap: (row) async => await _onInvoiceTap(deliveries, row.first),
      onEditTap: (row) async => _onEditTap(deliveries, row.first),
      onDeleteTap: (row) async => _onDeleteTap(deliveries, row.first),
    );
  }

  _buildAnyWidget(List<Delivery> deliveries) {
    return AdaptiveLayout(
      isFormBuilder: false,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        context.actionInfoButton(
          'Refresh Deliveries',
          label: 'Deliveries',
          count: deliveries.length,
          onPressed: () {
            // Refresh Deliveries Data
            context.read<DeliveryBloc>().add(RefreshInventories<Delivery>());
          },
        ),
        // final deliveryBloc = context.read<DeliveryBloc>();
        // final deliveryBloc = BlocProvider.of<DeliveryBloc>(context, listen: false);
        const SizedBox(height: 20),
        _IssueMultiDelete(
          deliveries: _groupMultiDelete,
          onDone: (s) => setState(() => _groupMultiDelete.clear()),
        ),
      ],
    );
  }

  // Handle onChecked Deliveries
  void _onChecked(List<Delivery> deliveries, bool? isChecked, String id) async {
    setState(() {
      final delivery = deliveries.firstWhere((d) => d.id == id);

      if (isChecked != null && isChecked) {
        _groupMultiDelete.add(delivery);
      } else {
        _groupMultiDelete.remove(delivery);
      }
    });
  }

  _onInvoiceTap(List<Delivery> deliveries, String id) async {
    // Show progress dialog while loading data
    await context.progressBarDialog(
      request: _printout(deliveries, id),
      onSuccess: (_) =>
          context.showAlertOverlay('Printout successfully created'),
      onError: (error) => context.showAlertOverlay(
        'Invoice printout failed',
        bgColor: kDangerColor,
      ),
    );
  }

  Future<dynamic> _printout(List<Delivery> deliveries, String id) =>
      Future.delayed(kRProgressDelay, () async {
        // Simulate loading supplier and company info
        final delivery = Delivery.findDeliveryById(deliveries, id).first;

        // get Orders from Orders-Database
        final orders = await GetOrders.getWithSameId(delivery.orderNumber);

        final cus = await GetAllCustomers.byCustomerId(orders.first.customerId);
        if (orders.isNotEmpty && cus.isNotEmpty) {
          SalesDocPrinter(
            orders: orders,
            customer: cus,
          ).printDoc(title: 'delivery note');
        }
      });

  Future<void> _onEditTap(List<Delivery> deliveries, String id) async {
    final delivery = Delivery.findDeliveryById(deliveries, id).first;
    await context.openUpdateDelivery(delivery: delivery);
  }

  Future<void> _onDeleteTap(List<Delivery> deliveries, String id) async {
    final delivery = Delivery.findDeliveryById(deliveries, id).first;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      /// Delete specific delivery
      context.read<DeliveryBloc>().add(
        DeleteInventory<String>(documentId: delivery.id),
      );
    }
  }
}

/// Delete grouped or multiple Deliveries [_IssueMultiDelete]
class _IssueMultiDelete extends StatelessWidget {
  final List<Delivery> deliveries;
  final Function(bool) onDone;

  const _IssueMultiDelete({required this.deliveries, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return deliveries.isEmpty
        ? const SizedBox.shrink()
        : Center(child: _buildBody(context));
  }

  _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: _buildDeleteButton(context),
    );
  }

  Future<bool> _confirmDeleteDialog(BuildContext context) async {
    return context.confirmAction<bool>(
      const Text('Are you sure you want to delete the selected deliveries?'),
      title: "Confirm Delete",
      onAccept: "Delete",
      onReject: "Cancel",
    );
  }

  _buildDeleteButton(BuildContext context) {
    return context.elevatedIconBtn(
      Icon(Icons.delete, color: kWhiteColor),
      style: OutlinedButton.styleFrom(backgroundColor: context.errorColor),
      onPressed: () async {
        final isConfirmed = await _confirmDeleteDialog(context);
        if (context.mounted && isConfirmed) {
          final ids = deliveries.map((s) => s.id).toList();

          // Remove deliveries from Delivery-DB
          DeliveryBloc(
            firestore: FirebaseFirestore.instance,
          ).add(DeleteInventory<List<String>>(documentId: ids));

          // Check if totalDeleted isEqual to total deliveries,
          // is so, then deletion completed
          onDone(true);

          /* int totalDeleted = 0;
            totalDeleted++;
            for (var delivery in deliveries) {}
            if (totalDeleted == deliveries.length) {
              onDone(true);
            }*/
        }
      },
      label: const Text('Delete', style: TextStyle(color: kWhiteColor)),
    );
  }
}
