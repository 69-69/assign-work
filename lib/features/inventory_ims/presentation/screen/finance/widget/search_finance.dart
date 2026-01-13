import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/features/inventory_ims/data/data_sources/remote/get_orders.dart';
import 'package:assign_erp/features/inventory_ims/data/models/orders/order_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Search Orders to add to Sales Processing [SearchOrders]
class SearchFinance extends StatefulWidget {
  final String? initialValue;
  final Function(String, String)? onChanged;

  const SearchFinance({super.key, this.onChanged, this.initialValue});

  @override
  State<SearchFinance> createState() => _SearchFinanceState();
}

class _SearchFinanceState extends State<SearchFinance> {
  String? _initialValue;
  Orders? _order;

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  Future _loadOrders({String? filter}) async {
    final initial = widget.initialValue ?? '';
    final filterBy = filter.isNullOrEmpty ? initial : filter;
    final orders = await GetOrders.byAnyTerm(filterBy);
    if (initial.hasValue && orders.hasValue) {
      setState(() => _order = orders.first);
    }
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    /// Search for Orders to Add to Sales Processing
    return _buildDropdownSearch(context);
  }

  /// Dropdown field
  AsyncSearchDropdown<Orders> _buildDropdownSearch(BuildContext context) =>
      AsyncSearchDropdown<Orders>(
        selectedItem: _order,
        labelText: 'Select Order...',
        asyncItems: (String filter, loadProps) async =>
            await _loadOrders(filter: filter),
        filterFn: (order, filter) => _filterOrder(filter, order, context),
        itemAsString: (Orders order) => order.toString().toTitle,
        onChanged: (o) => widget.onChanged!(o!.orderNumber, o.itemName),
        validator: (order) => order == null ? 'Select an order' : null,
      );

  bool _filterOrder(String filter, Orders order, BuildContext context) {
    final term = filter.isEmpty ? (_initialValue ?? '') : filter;
    final matches = order.filterByAny(term);
    if (!matches && filter.isNotEmpty) _handleNoDataFound(context);
    return matches;
  }

  Future<void> _handleNoDataFound(BuildContext context) async {
    final isNewOrder = await context.confirmAction<bool>(
      const Text('Do you want to create a new order?'),
      title: 'Orders not found',
    );

    if (context.mounted && isNewOrder) {
      context.goNamed('', pathParameters: {'openTab': '3'});
    }
  }
}
