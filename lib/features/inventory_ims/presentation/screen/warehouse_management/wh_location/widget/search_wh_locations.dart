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

  String get _labelText => widget.label ?? 'Storage Location...';

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWHLocations());
  }

  Future _loadWHLocations({String? filter}) async {
    final initial = widget.initialValue ?? '';
    final filterBy = filter.isNullOrEmpty ? initial : filter;
    final whLocations = await GetWHLocations.byAnyTerm(filterBy);
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
      helperText: 'Functional area/subdivision within the warehouse',
      asyncItems: (String filter, loadProps) async =>
          await _loadWHLocations(filter: filter),
      filterFn: (loc, filter) => _filterWHLocation(filter, loc),
      itemAsString: (loc) =>
          '${loc.code.toUpperAll} - ${loc.description.toTitle}',
      onChanged: (loc) => widget.onChanged(loc!.id, loc.code, loc.description),
      validator: (loc) => loc == null ? _labelText : null,
    );
  }

  bool _filterWHLocation(String filter, WHLocation item) {
    final term = filter.isEmpty ? (_initialValue ?? '') : filter;
    final matches = item.filterByAny(term);
    return matches;
  }
}
