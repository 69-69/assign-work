import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_wh_locations.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/wh_location_model.dart';
import 'package:flutter/material.dart';

/// Search Warehouse Storage Location [SearchWHSubLocations]
/// Functional area within the warehouse
class SearchWHSubLocations extends StatefulWidget {
  final bool enabled;
  final String? label;
  final String? initialValue;
  final Function(String, String, String, String) onChanged;

  const SearchWHSubLocations({
    super.key,
    this.label,
    this.initialValue,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  State<SearchWHSubLocations> createState() => _SearchWHSubLocationsState();
}

class _SearchWHSubLocationsState extends State<SearchWHSubLocations> {
  String? _initialValue;
  WHLocation? _whLocation;

  String get _labelText => widget.label ?? 'Sub-Location...';
  bool get _isEnabled => widget.enabled;

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
      enabled: _isEnabled,
      selectedItem: _whLocation,
      labelText: _labelText,
      // helperText: 'Functional area/subdivision within the warehouse',
      helperText: 'Enter * for all sub-locations, or type to search',
      asyncItems: (String filter, loadProps) async =>
          await _loadWHLocations(filter: filter),
      filterFn: (loc, filter) => _filterWHLocation(filter, loc),
      itemAsString: (loc) => loc.description.toTitle,
      onChanged: (loc) => widget.onChanged(
        loc!.id,
        loc.warehouseCode,
        loc.getLocationType,
        loc.description ?? '',
      ),
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

/// Sub-Location Codes (e.g., A1, A2, ...., A20, ...) [SearchSubLocationCodes]
class SearchSubLocationCodes extends StatelessWidget {
  final String? label;
  final bool isDisabled;
  final String? initialValue;
  final List<String> subLocCodes;
  final void Function(String?) onChanged;

  const SearchSubLocationCodes({
    super.key,
    required this.onChanged,
    this.isDisabled = false,
    required this.subLocCodes,
    this.initialValue,
    this.label,
  });

  String get _labelText => label ?? 'Sub-Location Codes...';

  @override
  Widget build(BuildContext context) {
    // If label is provided, replace it with the first in the list
    final List<String> locCodes = label != null
        ? [_labelText, ...subLocCodes]
        : [...subLocCodes];

    return IgnorePointer(
      ignoring: isDisabled,
      child: StaticDropdown<String>(
        key: key,
        label: _labelText,
        initialValue: initialValue,
        items: locCodes,
        getDisplayText: (str) => str.toUpperAll,
        onChanged: onChanged,
      ),
    );
  }
}
