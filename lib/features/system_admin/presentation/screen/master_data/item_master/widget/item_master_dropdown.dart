import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_item_master.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/item_master_model.dart';
import 'package:flutter/material.dart';

/// Remote Item Master data [ItemMasterDropdown]
class ItemMasterDropdown extends StatefulWidget {
  final bool isMultiSelect;

  final String? label;
  final String? helperText;

  final String? initialValue;
  final List<ItemMaster>? initialValues;

  final Function(String, String)? onChanged;
  final ValueChanged<List<ItemMaster>>? onMultiChanged;

  const ItemMasterDropdown({
    super.key,
    this.isMultiSelect = false,
    this.label,
    this.helperText,
    this.initialValue,
    this.initialValues,
    this.onChanged,
    this.onMultiChanged,
  });

  @override
  State<ItemMasterDropdown> createState() => _ItemMasterDropdownState();
}

class _ItemMasterDropdownState extends State<ItemMasterDropdown> {
  ItemMaster? _selectedItem;
  List<ItemMaster>? _selectedItems;

  String get _initialFilter => widget.initialValue ?? '';

  @override
  void initState() {
    super.initState();

    _selectedItems = widget.initialValues;

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialItem());
  }

  /// ---------------------------------------------------------------------------
  /// INITIAL LOAD
  /// ---------------------------------------------------------------------------

  Future<void> _loadInitialItem() async {
    if (widget.isMultiSelect) return;

    final filter = _initialFilter;

    if (filter.isEmpty) return;

    final items = await _fetchItems(filter);

    if (mounted && items.hasValue) {
      setState(() => _selectedItem = items.first);
    }
  }

  /// ---------------------------------------------------------------------------
  /// REMOTE FETCH
  /// ---------------------------------------------------------------------------

  Future<List<ItemMaster>> _fetchItems(String filter) async {
    if (filter.contains('*')) {
      return await GetItemMaster.load();
    }

    return await GetItemMaster.byAnyTerm(filter);
  }

  /// ---------------------------------------------------------------------------
  /// BUILD
  /// ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AsyncDropdown<ItemMaster>(
      isMultiSelect: widget.isMultiSelect,

      labelText: widget.label ?? 'Select Item...',

      helperText:
          widget.helperText ?? 'Enter * for all Items, or type to search',

      selectedItem: !widget.isMultiSelect ? _selectedItem : null,

      selectedMultiItems: widget.isMultiSelect ? _selectedItems : null,

      asyncItems: (filter, loadProps) async => await _fetchItems(filter),

      filterFn: _filterItem,

      getDisplayText: (item) => item.name,

      /// SINGLE
      onChanged: (item) {
        widget.onChanged?.call(item!.id, item.name);
      },

      /// MULTI
      onMultiChanged: (items) {
        setState(() => _selectedItems = List<ItemMaster>.from(items));

        widget.onMultiChanged?.call(items);
      },

      validator: !widget.isMultiSelect
          ? (item) {
            return item == null ? 'Item is required' : null;
          }
          : null,

      validatorMulti: widget.isMultiSelect
          ? (items) {
              return items.isNullOrEmpty
                  ? 'Select at least one item'
                  : null;
            }
          : null,
    );
  }

  /// ---------------------------------------------------------------------------
  /// FILTER
  /// ---------------------------------------------------------------------------

  bool _filterItem(ItemMaster item, String filter) {
    if (filter == '*') return true;

    final term = filter.isEmpty ? _initialFilter : filter;

    return item.filterByAny(term);
  }
}
