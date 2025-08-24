import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/inventory_ims/data/data_sources/remote/get_orders.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/order_model.dart';
import 'package:flutter/material.dart';

/// Search Orders to add to Sales Processing [SearchOrders]
class SearchFinance extends StatelessWidget {
  final bool isDropdown;
  final String? initialValue;
  final Function(String, String)? onChanged;

  const SearchFinance({
    super.key,
    this.onChanged,
    this.initialValue,
    this.isDropdown = false,
  });

  @override
  Widget build(BuildContext context) {
    /// Search for Orders to Add to Sales Processing
    return isDropdown
        ? _buildDropdownSearch(context)
        : _buildAppbarSearch(context);
  }

  /// Dropdown field
  AsyncSearchDropdown<Orders> _buildDropdownSearch(BuildContext context) =>
      AsyncSearchDropdown<Orders>(
        labelText: initialValue ?? 'Select Order...',
        asyncItems: (String filter, loadProps) async =>
            await GetOrders.byAnyTerm(filter),
        filterFn: (order, filter) {
          var f = filter.isEmpty ? (initialValue ?? '') : filter;
          return order.filterByAny(f);
        },
        itemAsString: (Orders order) => order.toString().toTitleCase,
        onChanged: (order) => onChanged!(order!.orderNumber, order.itemName),
        validator: (order) => order == null ? 'Please choose an order' : null,
      );

  /// Custom Search Delegate
  _buildAppbarSearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: context.elevatedIconBtn(
        Icon(Icons.search),
        onPressed: () async {
          // Ensure to wait for the data to be loaded
          // final allData = await GetOrders.load();

          if (context.mounted) {
            /*showSearch(
              context: context,
              delegate: CustomSearchDelegate<Orders, InventoryBloc<Orders>>(
                firestoreBloc: GetOrders.ordersBloc,
                allData: allData,
                field: 'orderNumber',
                optField: 'customerId',
                auxField: 'deliveryDate',
                hintText:'Search by order-number, customer-id, delivery-date...',
                onChanged: (s) {
                  Orders order = s as Orders;
                  debugPrint('steve-orders: $order');

                  context.openAddSales();
                },
              ),
            );*/
          }
        },
        label: const Text('Find Orders'),
      ),
    );
  }
}
