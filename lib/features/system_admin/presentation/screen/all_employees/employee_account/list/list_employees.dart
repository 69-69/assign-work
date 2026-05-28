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
  List<String> _selectedIds = [];

  EmployeeBloc get _bloc => context.read<EmployeeBloc>();

  Employee? _selectedEmployee(List<Employee> employees) {
    if (_selectedIds.length != 1) return null;

    return _findEmployee(_selectedIds.first, employees);
  }

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
    return DynamicDataTable2(
      omitAtIndex: 0,
      maskAtIndex: 1,
      headers: Employee.dataTableHeader,
      toolbar: _buildToolbar(employees),
      toolbarAlignment: WrapAlignment.start,
      rows: employees.map(_toTableRow).toList(),
      selectedRowKeys: _selectedIds,
      onSelectionChanged: (ids, rows) {
        setState(() => _selectedIds = ids);
      },
      onEditTap: (row) async => _onEditTap(employees, row.id),
      onDeleteTap: (row) async => _onDeleteTap(employees, row.id),
      optButtonIcon: Icons.lock,
      optButtonLabel: 'Reset',
      onOptButtonTap: (row) async {
        Employee employee = _findEmployee(row.id, employees);
        await context.openForgotPasscode(employee: employee);
      },
    );
  }

  DataTableRow _toTableRow(Employee e) =>
      DataTableRow.fromList(e.id, e.itemAsList);

  // Executes the given action only if the selected employee can be reassigned.
  // If the employee cannot be reassigned (e.g., business owner or anchored to the main store branch),
  // an alert is shown instead.
  Future<void> _openIfCanReassign(
    Future<void> Function() action, {
    Employee? employee,
  }) async {
    if (employee?.canBeReassigned == true) {
      await action();
    } else {
      context.showAlertOverlay(
        'The Default Account cannot be reassigned.',
        bgColor: kDangerColor,
      );
    }
  }

  Widget _buildToolbar(List<Employee> employees) {
    final employee = _selectedEmployee(employees);
    final isOne = employee != null;

    return ListToolbarButtons(
      primaryLabel: 'New Employee',
      refreshLabel: 'Refresh',
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

      onPermanent: isOne
          ? () => _openIfCanReassign(
              employee: employee,
              () => context.openAssignEmployeeDepartmentDialog(
                employeeId: employee.id,
                employeeName: employee.fullName,
              ),
            )
          : null,
      onSecondary: isOne
          ? () async => await _onEditTap(employees, employee.id)
          : null,
      onWarning: isOne
          ? () => _openIfCanReassign(
              employee: employee,
              () => context.assignEmployeeToStoreBranchDialog(
                employeeId: employee.id,
                employeeName: employee.fullName,
              ),
            )
          : null,
      onTertiary: isOne
          ? () => _openIfCanReassign(
              employee: employee,
              () => context.openAssignEmployeeRoleDialog(
                employeeId: employee.id,
                employeeName: employee.fullName,
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
