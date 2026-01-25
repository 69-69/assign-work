import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/inventory_ims/data/data_sources/remote/get_wh_locations.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_location_model.dart';
import 'package:flutter/material.dart';

/// Search Warehouse Storage Location [SearchWHLocation]
/// Functional area within the warehouse
class SearchWHLocation extends StatefulWidget {
  final String? label;
  final String? initialValue;
  final Function(String, String, String) onChanged;

  const SearchWHLocation({
    super.key,
    this.label,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<SearchWHLocation> createState() => _SearchWHLocationState();
}

class _SearchWHLocationState extends State<SearchWHLocation> {
  String? _initialValue;
  WHLocation? _whLocation;

  String get _labelText => widget.label ?? 'Sub-Location...';

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWHLocations());
  }

  Future _loadWHLocations({String? filter}) async {
    final initial = widget.initialValue ?? '';
    final filterBy = filter.isNullOrEmpty ? initial : filter;
    // If filter contains wildCard/asterisk '*', load all Locations
    // Else load Locations that match the filter
    final whLocations = await (filterBy!.contains('*')
        ? GetWHLocations.load()
        : GetWHLocations.byAnyTerm(filterBy));

    if (mounted && initial.hasValue && whLocations.hasValue) {
      setState(() => _whLocation = whLocations.first);
    }
    return whLocations;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<WHLocation>(
      selectedItem: _whLocation,
      labelText: _labelText,
      // helperText: 'Functional area/subdivision within the warehouse',
      helperText: 'Enter * for all sub-locations, or type to search',
      asyncItems: (String filter, loadProps) async =>
          await _loadWHLocations(filter: filter),
      filterFn: (loc, filter) => _filterWHLocation(filter, loc),
      itemAsString: (loc) => loc.getLocType.toTitle,
      onChanged: (loc) =>
          widget.onChanged(loc!.id, loc.warehouseCode, loc.getLocType),
      validator: (loc) => loc == null ? _labelText : null,
    );
  }

  bool _filterWHLocation(String filter, WHLocation item) {
    // If filter contains wildCard/asterisk '*', load all, else load filtered
    if (filter == '*') return true;

    final term = filter.isEmpty ? (_initialValue ?? '') : filter;
    final matches = item.filterByAny(term);
    return matches;
  }
}
