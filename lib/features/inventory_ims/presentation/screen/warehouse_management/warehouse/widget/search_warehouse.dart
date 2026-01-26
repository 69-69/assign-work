import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/inventory_ims/data/data_sources/remote/get_warehouses.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/warehouse_model.dart';
import 'package:flutter/material.dart';

/// Search Warehouse [SearchWarehouses]
class SearchWarehouses extends StatefulWidget {
  final String? label;
  final String? initialValue;
  final Function(String, String, String) onChanged;

  const SearchWarehouses({
    super.key,
    this.label,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<SearchWarehouses> createState() => _SearchWarehousesState();
}

class _SearchWarehousesState extends State<SearchWarehouses> {
  String? _initialValue;
  Warehouse? _warehouse;

  String get _labelText => widget.label ?? 'Warehouse...';

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWarehouses());
  }

  Future _loadWarehouses({String? filter}) async {
    final initial = widget.initialValue ?? '';
    final filterBy = filter.isNullOrEmpty ? initial : filter;
    // If filter contains wildCard/asterisk '*', load all warehouses
    // Else load warehouses that match the filter
    final warehouses = await (filterBy!.contains('*')
        ? GetWarehouses.load()
        : GetWarehouses.byAnyTerm(filterBy));

    if (mounted && initial.hasValue && warehouses.hasValue) {
      setState(() => _warehouse = warehouses.first);
    }
    return warehouses;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<Warehouse>(
      selectedItem: _warehouse,
      labelText: _labelText,
      helperText: 'Enter * for all warehouses, or type to search',
      asyncItems: (String filter, loadProps) async =>
          await _loadWarehouses(filter: filter),
      filterFn: (ware, filter) => _filterWarehouse(filter, ware),
      itemAsString: (ware) =>
          '${ware.code.toUpperAll} - ${ware.description.toTitle}',
      onChanged: (ware) =>
          widget.onChanged(ware!.id, ware.code, ware.description),
      validator: (ware) => ware == null ? _labelText : null,
    );
  }

  bool _filterWarehouse(String filter, Warehouse item) {
    // If filter contains wildCard/asterisk '*', load all, else load filtered
    if (filter == '*') return true;

    final term = filter.isEmpty ? (_initialValue ?? '') : filter;
    final matches = item.filterByAny(term);
    return matches;
  }
}
