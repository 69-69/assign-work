import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/setup/data/data_sources/remote/get_stores.dart';
import 'package:assign_erp/features/setup/data/models/company_stores_model.dart';
import 'package:flutter/material.dart';

/// Search Stores [SearchStores]
class SearchStores extends StatelessWidget {
  final String? initialValue;
  final Function(String, String) onChanged;

  const SearchStores({super.key, this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<CompanyStores>(
      labelText: (initialValue ?? 'Assign Store locations...').toTitle,
      asyncItems: (String filter, loadProps) async =>
          await GetStores.byAnyTerm(filter),
      filterFn: (store, filter) {
        var term = filter.isEmpty ? (initialValue ?? '') : filter;
        return store.filterByAny(term);
      },
      itemAsString: (store) => store.itemAsString,
      onChanged: (store) => onChanged(store!.storeNumber, store.name),
      validator: (store) => store == null ? 'Required Store location' : null,
    );
  }
}
