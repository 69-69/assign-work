import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/create_acc/employee_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/employee_account/index.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/employee_account/widget/assign_department_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListEmployees extends StatefulWidget {
  const ListEmployees({super.key});

  @override
  State<ListEmployees> createState() => _ListEmployeesState();
}

class _ListEmployeesState extends State<ListEmployees> {
  bool? _isChecked;
  Employee? _selectedEmployee;

  EmployeeBloc get _bloc => context.read<EmployeeBloc>();

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  BlocBuilder<EmployeeBloc, SetupState<Employee>> _buildBody() {
    return BlocBuilder<EmployeeBloc, SetupState<Employee>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<Employee>() => context.loader,
          SetupsLoaded<Employee>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Add Employee',
                    onPressed: () => context.openCreateEmployee(),
                  )
                : _buildCard(context, results),
          SetupError<Employee>(error: final error) => context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<Employee> employees) {
    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 1,
      headers: Employee.dataTableHeader,
      toolbar: _buildToolbar(employees),
      toolbarAlignment: WrapAlignment.start,
      rows: employees.map((d) => d.itemAsList).toList(),
      onChecked: (bool? isChecked, row) =>
          _onChecked(employees, row.first, isChecked),
      onEditTap: (row) async => _onEditTap(employees, row.first),
      onDeleteTap: (row) async => _onDeleteTap(employees, row.first),
      optButtonIcon: Icons.lock,
      optButtonLabel: 'Reset',
      onOptButtonTap: (row) async {
        Employee employee = _findEmployee(row.first, employees);
        await context.openForgotPasscode(employee: employee);
      },
    );
  }

  // Handle onChecked employee
  void _onChecked(List<Employee> employees, String id, bool? isChecked) async {
    Employee employee = _findEmployee(id, employees);

    setState(() {
      _isChecked = isChecked;
      if (_isChecked == true) {
        _selectedEmployee = employee;
      }
    });
  }

  // Executes the given action only if the selected employee can be reassigned.
  // If the employee cannot be reassigned (e.g., business owner or anchored to the main store branch),
  // an alert is shown instead.
  Future<void> _openIfCanReassign(Future<void> Function() action) async {
    if (_selectedEmployee?.canBeReassigned == true) {
      await action();
    } else {
      context.showAlertOverlay(
        'The Default Account cannot be reassigned.',
        bgColor: kDangerColor,
      );
    }
  }

  Widget _buildToolbar(List<Employee> employees) {
    final isSelected = _isChecked == true;

    return ListToolbarButtons(
      primaryLabel: 'Add Employee',
      refreshLabel: 'Refresh Employees',
      dataLength: employees.length,

      warningLabel: 'Assign Store',
      warningTooltip: 'Assign Employee to Store',
      warningIcon: Icons.store,

      secondaryIcon: Icons.edit,
      secondaryLabel: 'Edit Employee',
      secondaryTooltip: 'Edit Employee',

      permanentIcon: Icons.apartment,
      permanentLabel: 'Assign Department',
      permanentTooltip: 'Assign Employee to Department',

      tertiaryLabel: 'Assign Role',
      tertiaryTooltip: 'Assign Employee to Role',
      tertiaryIcon: Icons.security,

      onPrimary: () => context.openCreateEmployee(),
      onRefresh: () => _bloc.add(RefreshSetups<Employee>()),

      onPermanent: isSelected
          ? () => _openIfCanReassign(
              () => context.openAssignEmployeeDepartmentDialog(
                employeeId: _selectedEmployee!.id,
                employeeName: _selectedEmployee?.fullName,
              ),
            )
          : null,
      onSecondary: isSelected
          ? () async => await _onEditTap(employees, _selectedEmployee!.id)
          : null,
      onWarning: isSelected
          ? () => _openIfCanReassign(
              () => context.assignEmployeeToStoreBranchDialog(
                employeeId: _selectedEmployee!.id,
                employeeName: _selectedEmployee?.fullName,
              ),
            )
          : null,
      onTertiary: isSelected
          ? () => _openIfCanReassign(
              () => context.openAssignEmployeeRoleDialog(
                employeeId: _selectedEmployee!.id,
                employeeName: _selectedEmployee?.fullName,
              ),
            )
          : null,
    );
  }

  Employee _findEmployee(String id, List<Employee> employees) {
    final employee = Employee.findById(employees, id).first;
    return employee;
  }

  Future<void> _onEditTap(List<Employee> employees, String id) async {
    Employee employee = _findEmployee(id, employees);

    /// Update specific Employee Account
    await context.openUpdateEmployee(employee: employee);
  }

  Future<void> _onDeleteTap(List<Employee> employees, String id) async {
    {
      Employee employee = _findEmployee(id, employees);
      // Prevent deletion of business owner or employees anchored to the primary branch.
      if (!_guardPrimaryEmployeeAccount(employee)) return;

      // Proceed with deletion
      final isConfirmed = await context.confirmUserActionDialog();
      if (mounted && isConfirmed) {
        /// Delete specific Employee Account
        _bloc.add(DeleteSetup<String>(documentId: employee.id));
      }
    }
  }

  // Prevent deletion of the primary Account associated with the [business owner]
  bool _guardPrimaryEmployeeAccount(Employee employee) {
    if (!employee.canBeDeleted) {
      context.showAlertOverlay(
        'The Default Account cannot be deleted',
        bgColor: kDangerColor,
      );
      return false;
    }
    return true;
  }
}
