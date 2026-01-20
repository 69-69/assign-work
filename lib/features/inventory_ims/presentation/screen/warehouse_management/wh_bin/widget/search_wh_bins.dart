import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/inventory_ims/data/data_sources/remote/get_wh_bins.dart';
import 'package:assign_erp/features/inventory_ims/data/models/warehouse/wh_bin_model.dart';
import 'package:flutter/material.dart';

/// Search Warehouse Bin/Shelf [SearchWHBin]
class SearchWHBin extends StatefulWidget {
  final String? label;
  final String? initialValue;
  final Function(String, String, String) onChanged;

  const SearchWHBin({
    super.key,
    this.label,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<SearchWHBin> createState() => _SearchWHBinState();
}

class _SearchWHBinState extends State<SearchWHBin> {
  String? _initialValue;
  WHBin? _whBin;

  String get _labelText => widget.label ?? 'Select Bin/Shelf...';

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWHBins());
  }

  Future _loadWHBins({String? filter}) async {
    final initial = widget.initialValue ?? '';
    final filterBy = filter.isNullOrEmpty ? initial : filter;
    final whLocations = await GetWHBins.byAnyTerm(filterBy);
    if (mounted && initial.hasValue && whLocations.hasValue) {
      setState(() => _whBin = whLocations.first);
    }
    return whLocations;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<WHBin>(
      selectedItem: _whBin,
      labelText: _labelText,
      helperText: 'The smallest physical storage unit/slot inside a location',
      asyncItems: (String filter, loadProps) async =>
          await _loadWHBins(filter: filter),
      filterFn: (bin, filter) => _filterWHBin(filter, bin),
      itemAsString: (bin) =>
          '${bin.code.toUpperAll} - ${bin.description.toTitle}',
      onChanged: (bin) => widget.onChanged(bin!.id, bin.code, bin.description),
      validator: (bin) => bin == null ? _labelText : null,
    );
  }

  bool _filterWHBin(String filter, WHBin item) {
    final term = filter.isEmpty ? (_initialValue ?? '') : filter;
    final matches = item.filterByAny(term);
    return matches;
  }
}
