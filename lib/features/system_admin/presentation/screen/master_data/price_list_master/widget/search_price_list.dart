import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_price_lists.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/price_list_master_model.dart';
import 'package:flutter/material.dart';

/// Search priceList [SearchPriceList]
class SearchPriceList extends StatefulWidget {
  final String? initialValue;
  final Function(String, String) onChanged;

  const SearchPriceList({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<SearchPriceList> createState() => _SearchPriceListState();
}

class _SearchPriceListState extends State<SearchPriceList> {
  PriceListMaster? _priceList;
  String? _initialValue;

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPriceLists());
  }

  Future _loadPriceLists({String? filter}) async {
    final filterBy = filter ?? _initialValue ?? '';

    // If filter contains wildCard/asterisk '*', load all priceList
    // Else load priceList that match the filter
    final priceLists = await (filterBy.contains('*')
        ? GetPriceList.load()
        : GetPriceList.byAnyTerm(filterBy));

    if (filterBy.hasValue && priceLists.hasValue) {
      setState(() => _priceList = priceLists.first);
    }
    return priceLists;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<PriceListMaster>(
      labelText: 'Price list...',
      selectedItem: _priceList,
      helperText: 'Enter * for all list, or type to search',
      asyncItems: (String filter, loadProps) async =>
          await _loadPriceLists(filter: filter),
      filterFn: (priceList, filter) => _filterPriceList(priceList, filter),
      getDisplayText: (list) => list.name.toTitle,
      onChanged: (list) => widget.onChanged(list!.id, list.name),
      validator: (list) => list == null ? 'Price list is Required' : null,
    );
  }

  _filterPriceList(PriceListMaster priceList, String filter) {
    // If filter contains wildCard/asterisk '*', load all, else load filtered
    if (filter == '*') return true;

    var term = filter.isEmpty ? (_initialValue ?? '') : filter;
    return priceList.filterByAny(term);
  }
}
