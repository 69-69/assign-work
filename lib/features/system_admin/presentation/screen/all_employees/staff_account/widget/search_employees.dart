import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_employees.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';

/// Search Employees [SearchEmployees]
class SearchEmployees extends StatefulWidget {
  final String? initialValue;
  final Function(String, String, String) onChanged;

  const SearchEmployees({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<SearchEmployees> createState() => _SearchEmployeesState();
}

class _SearchEmployeesState extends State<SearchEmployees> {
  String? _initialValue;
  Employee? _employee;

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEmployees());
  }

  Future _loadEmployees({String? filter}) async {
    final initial = widget.initialValue ?? '';
    final filterBy = filter.isNullOrEmpty ? initial : filter;
    final employees = await GetEmployees.byAnyTerm(filterBy);
    if (initial.isNotNullNorEmpty && employees.isNotNullNorEmpty) {
      setState(() => _employee = employees.first);
    }
    return employees;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncSearchDropdown<Employee>(
      selectedItem: _employee,
      labelText: 'Select Employee...',
      asyncItems: (String filter, loadProps) async =>
          await _loadEmployees(filter: filter),
      filterFn: (emp, filter) => _filterEmployee(filter, emp),
      itemAsString: (emp) => emp.itemAsString,
      onChanged: (emp) => widget.onChanged(emp!.id, emp.fullName, emp.role),
      validator: (emp) => emp == null ? 'Select employee' : null,
    );
  }

  bool _filterEmployee(String filter, Employee emp) {
    final term = filter.isEmpty ? (_initialValue ?? '') : filter;
    final matches = emp.filterByAny(term);
    return matches;
  }
}
