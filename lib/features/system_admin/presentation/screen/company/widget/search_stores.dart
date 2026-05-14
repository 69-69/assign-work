import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_stores.dart';
import 'package:assign_erp/features/system_admin/data/models/company_store_model.dart';
import 'package:flutter/material.dart';

/// Search Store Branches [SearchStoreBranches]
class SearchStoreBranches extends StatelessWidget {
  final String? initialValue;
  final Function(String, String) onChanged;

  const SearchStoreBranches({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<CompanyStore>(
      labelText: (initialValue ?? 'Assign Store branch...').toTitle,
      helperText: 'Enter * for all Stores, or type to search',
      asyncItems: (String filterBy, loadProps) async {
        // If filter contains wildCard/asterisk '*', load all stores
        // Else load stores that match the filter
        final stores = await (filterBy.contains('*')
            ? GetStores.load()
            : GetStores.byAnyTerm(filterBy));
        return stores;
      },
      filterFn: (store, filter) {
        // If filter contains wildCard/asterisk '*', load all, else load filtered
        if (filter == '*') return true;

        var term = filter.isEmpty ? (initialValue ?? '') : filter;
        return store.filterByAny(term);
      },
      getDisplayText: (store) => store.itemAsString,
      onChanged: (store) => onChanged(store!.storeNumber, store.name),
      validator: (store) => store == null ? 'Required Store branch' : null,
    );
  }
}
