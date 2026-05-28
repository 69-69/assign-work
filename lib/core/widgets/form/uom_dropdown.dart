import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/extensions/unit_of_measure.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/ref_master_cache.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/ref_master_model.dart';
import 'package:flutter/material.dart';

/// Unit of measure [UOMDropdown] - Single select
class UOMDropdown extends StatelessWidget {
  // final String? label;
  final bool enabled;
  final String? initialValue;
  final void Function(String? s) onChanged;

  const UOMDropdown({
    super.key,
    required this.onChanged,
    this.enabled = true,
    this.initialValue,
    // this.label,
  });

  RefMaster? get _cache => RefMasterCache().getById(uomMasterCacheId);

  get _excludedUoms => (_cache?.references ?? const <String>[]);

  @override
  Widget build(BuildContext context) {
    final strList = UOMUtil.toStringList();
    // If label is provided, replace it with the first in the list
    // if (label != null) strList[0] = label!;

    return StaticDropdown<String>(
      key: key,
      enabled: enabled,
      label: strList.first,
      invalidPrefixes:['Unit of Measure'],
      initialValue: initialValue,
      items: strList.where((u) => !_excludedUoms.contains(u)).toList(),
      getDisplayText: (uom) => uom.toTitle,
      onChanged: onChanged,
    );
  }
}

/// Unit of measure [UOMMultiDropdown] - Multi select
class UOMMultiDropdown extends StatefulWidget {
  final Function(List<String>) onMultiChanged;
  final List<String>? initialValues;
  final String? label;

  const UOMMultiDropdown({
    super.key,
    required this.onMultiChanged,
    this.initialValues,
    this.label,
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

  String get _labelText => widget.label ?? 'Units of Measure';

  RefMaster? get _cache => RefMasterCache().getById(uomMasterCacheId);

  get _excludedUoms => (_cache?.references ?? const <String>[]);

  @override
  Widget build(BuildContext context) {
    return AsyncDropdown<String>(
      isMultiSelect: true,
      selectedMultiItems: _selectedUOMs,
      labelText: _labelText,
      asyncItems: (String filter, loadProps) async => _loadUOMs(filter),
      filterFn: _filterUOMs,
      getDisplayText: (String uom) => uom.toTitle,
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
    if (filter.isEmpty) {
      return _allUOMs
          .where((u) => !_excludedUoms.contains(u))
          .toList();
    }

        // Filter using generic filterAny on the UOM label
    return _allUOMs
        .where((u) => !_excludedUoms.contains(u) && u.filterAny(filter))
        .toList();
  }

  /// Used by AsyncSearchDropdown for real-time filtering
  bool _filterUOMs(String uom, String filter) => uom.filterAny(filter);
}
