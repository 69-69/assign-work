import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/setup/data/data_sources/remote/get_departments.dart';
import 'package:assign_erp/features/setup/data/models/department_model.dart';
import 'package:flutter/material.dart';

/// Search Departments [SearchDepartments]
class SearchDepartments extends StatefulWidget {
  final String? initialValue;
  final Function(String, String, String) onChanged;

  const SearchDepartments({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<SearchDepartments> createState() => _SearchDepartmentsState();
}

class _SearchDepartmentsState extends State<SearchDepartments> {
  String? _initialValue;
  Department? _department;

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDepartments());
  }

  Future _loadDepartments({String? filter}) async {
    final initial = widget.initialValue ?? '';
    final filterBy = filter.isNullOrEmpty ? initial : filter;
    final departments = await GetDepartments.byAnyTerm(filterBy);
    if (initial.isNotNullNorEmpty && departments.isNotNullNorEmpty) {
      setState(() => _department = departments.first);
    }
    return departments;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<Department>(
      selectedItem: _department,
      labelText: 'Select Department...',
      asyncItems: (String filter, loadProps) async =>
          await _loadDepartments(filter: filter),
      filterFn: (depart, filter) => _filterDepartment(filter, depart),
      itemAsString: (depart) => depart.itemAsString,
      onChanged: (depart) =>
          widget.onChanged(depart!.id, depart.code, depart.name),
      validator: (depart) => depart == null ? 'Select department' : null,
    );
  }

  bool _filterDepartment(String filter, Department item) {
    final term = filter.isEmpty ? (_initialValue ?? '') : filter;
    final matches = item.filterByAny(term);
    return matches;
  }
}
