import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_roles.dart';
import 'package:assign_erp/features/system_admin/data/models/role_model.dart';
import 'package:flutter/material.dart';

/// Employee Role to Permissions mapping Dropdown [SearchRole]
class SearchRole extends StatelessWidget {
  final String? initialValue;
  final Function(String, String) onChanged;

  const SearchRole({super.key, this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<Role>(
      labelText: (initialValue ?? 'Assign Role...').toTitle,
      asyncItems: (String filter, loadProps) async =>
          await GetRoles.byAnyTerm(filter),
      filterFn: (role, filter) {
        final term = filter.isEmpty ? (initialValue ?? '') : filter;
        return role.filterByAny(term);
      },
      itemAsString: (role) => role.itemAsString,
      onChanged: (role) => onChanged(role!.id, role.name),
      validator: (role) => role == null ? 'Employee Role is required' : null,
    );
  }

  /*_getProductCategory() async {
    final categories = await GetProductCategory.load();
    return categories.map((m) => m.name).toList();
  }*/
}
