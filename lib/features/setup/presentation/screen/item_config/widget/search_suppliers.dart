import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/features/setup/data/data_sources/remote/get_suppliers.dart';
import 'package:assign_erp/features/setup/data/models/supplier_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Search Suppliers [SearchSuppliers]
class SearchSuppliers extends StatefulWidget {
  final String? initialValue;
  final void Function(String id, String name) onChanged;

  const SearchSuppliers({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<SearchSuppliers> createState() => _SearchSuppliersState();
}

class _SearchSuppliersState extends State<SearchSuppliers> {
  String? _initialValue;
  Supplier? _supplier;

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSuppliers());
  }

  Future _loadSuppliers({String? filter}) async {
    final initial = widget.initialValue ?? '';
    final filterBy = filter.isNullOrEmpty ? initial : filter;
    final suppliers = await GetSuppliers.byAnyTerm(filterBy);
    if (initial.isNotNullNorEmpty && suppliers.isNotNullNorEmpty) {
      setState(() => _supplier = suppliers.first);
    }
    return suppliers;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<Supplier>(
      selectedItem: _supplier,
      labelText: 'Select Supplier...',
      asyncItems: (String filter, _) async =>
          await _loadSuppliers(filter: filter),
      filterFn: (supplier, filter) =>
          _filterSupplier(filter, supplier, context),
      itemAsString: (supplier) => supplier.itemAsString,
      onChanged: (supplier) => widget.onChanged(supplier!.id, supplier.name),
      validator: (supplier) => supplier == null ? 'Supplier is required' : null,
      onNoDataFound: () {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handleNoDataFound(context),
        );
      },
    );
  }

  bool _filterSupplier(String filter, Supplier supplier, BuildContext context) {
    final term = filter.isEmpty ? (_initialValue ?? '') : filter;
    final matches = supplier.filterByAny(term);
    if (!matches && filter.isNotEmpty) _handleNoDataFound(context);
    return matches;
  }

  Future<void> _handleNoDataFound(BuildContext context) async {
    final isNewSupplier = await context.confirmAction<bool>(
      const Text('Do you want to create a new supplier manually?'),
      title: 'Supplier not found',
    );

    if (context.mounted && isNewSupplier) {
      context.goNamed(
        RouteNames.productConfig,
        pathParameters: {'openTab': '3'},
      );
    }
  }
}
