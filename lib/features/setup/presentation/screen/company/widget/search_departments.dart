import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/setup/data/data_sources/remote/get_departments.dart';
import 'package:assign_erp/features/setup/data/models/department_model.dart';
import 'package:flutter/material.dart';

/// Search Departments [SearchDepartments]
class SearchDepartments extends StatelessWidget {
  final String? initialValue;
  final Function(String, String, String) onChanged;

  const SearchDepartments({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<Department>(
      labelText: (initialValue ?? 'Department...').toTitleCase,
      asyncItems: (String filter, loadProps) async =>
          await GetDepartments.byAnyTerm(filter),
      filterFn: (depart, filter) {
        var term = filter.isEmpty ? (initialValue ?? '') : filter;
        return depart.filterByAny(term);
      },
      itemAsString: (depart) => depart.itemAsString,
      onChanged: (depart) => onChanged(depart!.id, depart.code, depart.name),
      validator: (depart) => depart == null ? 'Required department' : null,
    );
  }
}
