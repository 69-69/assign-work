import 'package:assign_erp/core/util/extensions/item_category.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

/// Item Category [ItemCategoryDropdown]
class ItemCategoryDropdown extends StatelessWidget {
  final String? label;
  final bool isService;
  final bool isDisabled;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const ItemCategoryDropdown({
    super.key,
    required this.onChanged,
    this.isDisabled = false,
    this.isService = false,
    this.initialValue,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final strList = ItemCategoryUtil.toStringList(isService: isService);
    // If label is provided, replace it with the first in the list
    if (label != null) strList[0] = label!;

    return IgnorePointer(
      ignoring: isDisabled,
      child: StaticDropdown<String>(
        key: key,
        label: strList.first,
        initialValue: initialValue,
        items: strList,
        getDisplayText: (category) => category.toTitle,
        onChanged: onChanged,
      ),
    );
  }
}

/// Unit of measure [ItemCatMultiDropdown] - Multi select
class ItemCatMultiDropdown extends StatefulWidget {
  final Function(List<String>) onMultiChanged;
  final List<String>? initialValues;
  final String? label;

  const ItemCatMultiDropdown({
    super.key,
    required this.onMultiChanged,
    this.initialValues,
    this.label,
  });

  @override
  State<ItemCatMultiDropdown> createState() => _ItemCatMultiDropdownState();
}

class _ItemCatMultiDropdownState extends State<ItemCatMultiDropdown> {
  late List<String>? _selectedCategories;
  final List<String> _allCategories = ItemCategoryUtil.toStringList();

  @override
  void initState() {
    super.initState();
    _selectedCategories = widget.initialValues;
  }

  String get _labelText => widget.label ?? 'Item Category';

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<String>(
      isMultiSelect: true,
      selectedMultiItems: _selectedCategories,
      labelText: _labelText,
      asyncItems: (String filter, loadProps) async => _loadCategories(filter),
      filterFn: _filterCategories,
      itemAsString: (String cat) => cat.toTitle,
      onMultiChanged: (List<String> units) {
        setState(() => _selectedCategories = List.from(units));
        widget.onMultiChanged.call(units); // notify parent
      },
      validatorMulti: (units) =>
          units.isNullOrEmpty ? 'Select at least one Category' : null,
      helperText: 'Enter to search, select one or more categories',
    );
  }

  /// Load Categories filtered by search string
  List<String> _loadCategories(String filter) {
    // If no filter, return full list
    if (filter.isEmpty) return _allCategories;

    // Filter using generic filterAny on the category label
    return _allCategories.where((cat) => cat.filterAny(filter)).toList();
  }

  /// Used by AsyncSearchDropdown for real-time filtering
  bool _filterCategories(String cat, String filter) => cat.filterAny(filter);
}
