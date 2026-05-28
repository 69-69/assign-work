import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_employees.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';

/// Search Employees [SearchEmployees]
class SearchEmployees extends StatefulWidget {
  final String? labelText;
  final String? initialValue;
  final Function(String empId, String name, String role) onChanged;

  const SearchEmployees({
    super.key,
    this.labelText,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<SearchEmployees> createState() => _SearchEmployeesState();
}

class _SearchEmployeesState extends State<SearchEmployees> {
  String? _initialValue;
  Employee? _employee;

  get _labelText => (widget.labelText ?? 'Select employee').toSentence;

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEmployees());
  }

  Future _loadEmployees({String? filter}) async {
    final initial = widget.initialValue ?? '';
    final filterBy = filter.isNullOrEmpty ? initial : filter;

    // If filter contains wildCard/asterisk '*', load all employees
    // Else load employees that match the filter
    final employees = await (filterBy!.contains('*')
        ? GetEmployees.load()
        : GetEmployees.byAnyTerm(filterBy));

    if (initial.hasValue && employees.hasValue) {
      setState(() => _employee = employees.first);
    }
    return employees;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncDropdown<Employee>(
      selectedItem: _employee,
      labelText: _labelText,
      helperText: 'Enter * for all Employees, or type to search',
      asyncItems: (String filter, loadProps) async =>
          await _loadEmployees(filter: filter),
      filterFn: (emp, filter) => _filterEmployee(filter, emp),
      getDisplayText: (emp) => emp.itemAsString,
      onChanged: (emp) =>
          widget.onChanged(emp!.employeeId, emp.fullName, emp.role),
      validator: (emp) => emp == null ? _labelText : null,
    );
  }

  bool _filterEmployee(String filter, Employee emp) {
    // If filter contains wildCard/asterisk '*', load all, else load filtered
    if (filter == '*') return true;

    final term = filter.isEmpty ? (_initialValue ?? '') : filter;
    final matches = emp.filterByAny(term);
    return matches;
  }
}
