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
      asyncItems: (String filter, loadProps) async =>
          await GetStores.byAnyTerm(filter),
      filterFn: (store, filter) {
        var term = filter.isEmpty ? (initialValue ?? '') : filter;
        return store.filterByAny(term);
      },
      itemAsString: (store) => store.itemAsString,
      onChanged: (store) => onChanged(store!.storeNumber, store.name),
      validator: (store) => store == null ? 'Required Store branch' : null,
    );
  }
}
