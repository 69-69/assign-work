import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';

/// Unit of measure [UOMDropdown] - Single select
class UOMDropdown extends StatelessWidget {
  // final String? label;
  final bool isDisabled;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const UOMDropdown({
    super.key,
    required this.onChanged,
    this.isDisabled = false,
    this.initialValue,
    // this.label,
  });

  @override
  Widget build(BuildContext context) {
    final strList = UOMUtil.toStringList();
    // If label is provided, replace it with the first in the list
    // if (label != null) strList[0] = label!;

    return IgnorePointer(
      ignoring: isDisabled,
      child: StaticDropdown<String>(
        key: key,
        label: strList.first,
        initialValue: initialValue,
        items: strList,
        getDisplayText: (uom) => uom.toTitle,
        onChanged: onChanged,
      ),
    );
  }
}

/// Unit of measure [UOMMultiDropdown] - Multi select
class UOMMultiDropdown extends StatefulWidget {
  final Function(List<String>) onMultiChanged;
  final List<String>? initialValues;

  const UOMMultiDropdown({
    super.key,
    required this.onMultiChanged,
    this.initialValues,
  });

  @override
  State<UOMMultiDropdown> createState() => _UOMMultiDropdownState();
}

class _UOMMultiDropdownState extends State<UOMMultiDropdown> {
  late List<String>? _selectedUOMs;
  final List<String> _allUOMs = UOMUtil.toStringList(false);

  @override
  void initState() {
    super.initState();
    _selectedUOMs = widget.initialValues;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<String>(
      isMultiSelect: true,
      selectedMultiItems: _selectedUOMs,
      labelText: 'Select Units of Measure',
      asyncItems: (String filter, loadProps) async => _loadUOMs(filter),
      filterFn: _filterUOMs,
      itemAsString: (String uom) => uom.toTitle,
      onMultiChanged: (List<String> units) {
        setState(() => _selectedUOMs = List.from(units));
        widget.onMultiChanged.call(units); // notify parent
      },
      validatorMulti: (units) =>
          units.isNullOrEmpty ? 'Select at least one UOM' : null,
      helperText: 'Enter to search, select one or more units',
    );
  }

  /// Load UOMs filtered by search string
  List<String> _loadUOMs(String filter) {
    // If no filter, return full list
    if (filter.isEmpty) return _allUOMs;

    // Filter using generic filterAny on the UOM label
    return _allUOMs.where((uom) => uom.filterAny(filter)).toList();
  }

  /// Used by AsyncSearchDropdown for real-time filtering
  bool _filterUOMs(String uom, String filter) => uom.filterAny(filter);
}
