import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_discount_groups.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/discount_group_model.dart';
import 'package:flutter/material.dart';

/// Discount Group Dropdown [DiscountGroupDropdown]
class DiscountGroupDropdown extends StatefulWidget {
  final String? initialValue;
  final Function(String, String) onChanged;

  const DiscountGroupDropdown({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<DiscountGroupDropdown> createState() => _DiscountGroupDropdownState();
}

class _DiscountGroupDropdownState extends State<DiscountGroupDropdown> {
  DiscountGroup? _discountGroup;
  String? _initialValue;

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPriceLists());
  }

  Future _loadPriceLists({String? filter}) async {
    final filterBy = filter ?? _initialValue ?? '';

    // If filter contains wildCard/asterisk '*', load all Discount Group
    // Else load discountGroups that match the filter
    final discountGroups = await (filterBy.contains('*')
        ? GetDiscountGroups.load()
        : GetDiscountGroups.byAnyTerm(filterBy));

    if (filterBy.hasValue && discountGroups.hasValue) {
      setState(() => _discountGroup = discountGroups.first);
    }
    return discountGroups;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncDropdown<DiscountGroup>(
      labelText: 'Discount Group',
      selectedItem: _discountGroup,
      helperText: 'Enter * for all list, or type to search',
      asyncItems: (String filter, loadProps) async =>
          await _loadPriceLists(filter: filter),
      filterFn: (group, filter) => _filterDiscountGroups(group, filter),
      getDisplayText: (list) => list.name.toTitle,
      onChanged: (list) => widget.onChanged(list!.id, list.name),
      validator: (list) => list == null ? 'Discount group is Required' : null,
    );
  }

  _filterDiscountGroups(DiscountGroup priceList, String filter) {
    // If filter contains wildCard/asterisk '*', load all, else load filtered
    if (filter == '*') return true;

    var term = filter.isEmpty ? (_initialValue ?? '') : filter;
    return priceList.filterByAny(term);
  }
}
