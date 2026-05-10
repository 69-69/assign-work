import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_price_lists.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/price_list_master_model.dart';
import 'package:flutter/material.dart';

/// Search priceList [SearchPriceList]
class SearchPriceList extends StatelessWidget {
  final String? initialValue;
  final Function(String, String) onChanged;

  const SearchPriceList({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<PriceListMaster>(
      labelText: (initialValue ?? 'Price list...').toTitle,
      helperText: 'Enter * for all list, or type to search',
      asyncItems: (String filterBy, loadProps) async {
        // If filter contains wildCard/asterisk '*', load all priceList
        // Else load priceList that match the filter
        final priceList = await (filterBy.contains('*')
            ? GetPriceList.load()
            : GetPriceList.byAnyTerm(filterBy));
        return priceList;
      },
      filterFn: (priceList, filter) {
        // If filter contains wildCard/asterisk '*', load all, else load filtered
        if (filter == '*') return true;

        var term = filter.isEmpty ? (initialValue ?? '') : filter;
        return priceList.filterByAny(term);
      },
      itemAsString: (list) => list.name.toTitle,
      onChanged: (list) => onChanged(list!.id, list.name),
      validator: (list) => list == null ? 'Required Price list' : null,
    );
  }
}
