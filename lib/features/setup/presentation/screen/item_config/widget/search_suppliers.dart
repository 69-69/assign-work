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
  String? _label;

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<Supplier>(
      labelText:
          (_label ?? widget.initialValue ?? 'Select Supplier...').toTitleCase,
      asyncItems: (String filter, loadProps) async =>
          await GetSuppliers.byAnyTerm(filter),
      filterFn: (supplier, filter) => _handleFilter(filter, supplier, context),
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

  bool _handleFilter(String filter, Supplier supplier, BuildContext context) {
    final term = filter.isEmpty ? (widget.initialValue ?? '') : filter;
    final isFound = supplier.filterByAny(term);
    if (!isFound && filter.isNotEmpty) _handleNoDataFound(context);
    setState(() => _label = supplier.name);
    return isFound;
  }

  Future<void> _handleNoDataFound(BuildContext cxt) async {
    final isNewSupplier = await cxt.confirmAction<bool>(
      const Text('Do you want to create a new supplier manually?'),
      title: 'Supplier not found',
    );

    if (cxt.mounted && isNewSupplier) {
      cxt.goNamed(RouteNames.productConfig, pathParameters: {'openTab': '3'});
    }
  }
}

/*class SearchSuppliers extends StatelessWidget {
  final String? initialValue;
  final Function(String, String) onChanged;

  const SearchSuppliers({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdownSearch<Supplier>(
      labelText: (initialValue ?? 'Search Suppliers...').toTitleCase,
      asyncItems: (String filter, loadProps) async =>
          await GetSuppliers.byAnyTerm(filter),
      filterFn: (supplier, filter) {
        var f = filter.isEmpty ? (initialValue ?? '') : filter;
        return supplier.filterByAny(f);
      },
      itemAsString: (supplier) => supplier.itemAsString,
      onChanged: (supplier) async {
        prettyPrint('supplier', supplier?.id);
        if (supplier == null || supplier.isEmpty) {
          await _buildOptionToCreateNew(context);
          return;
        }
        onChanged(supplier.id, supplier.name);
      },
      validator: (supplier) => supplier == null ? 'Supplier is required' : null,
    );
  }

  _buildOptionToCreateNew(BuildContext context) async {
    final isNewSupplier = await context.confirmAction<bool>(
      Text('Do you want to create a new supplier?'),
      title: 'Create New Supplier',
    );
    if (context.mounted && isNewSupplier) {
      context.goNamed(RouteNames.productSuppliers);
    }
  }
}*/
