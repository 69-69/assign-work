import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/department_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/department_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/create/create_department.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListDepartments extends StatefulWidget {
  const ListDepartments({super.key});

  @override
  State<ListDepartments> createState() => _ListDepartmentsState();
}

class _ListDepartmentsState extends State<ListDepartments> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<DepartmentBloc>(
      create: (_) =>
          DepartmentBloc(firestore: FirebaseFirestore.instance)
            ..add(GetSetups<Department>()),
      child: _buildBody(),
    );
  }

  BlocBuilder<DepartmentBloc, SetupState<Department>> _buildBody() {
    return BlocBuilder<DepartmentBloc, SetupState<Department>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<Department>() => context.loader,
          SetupsLoaded<Department>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Departments',
                    onPressed: () => context.openAddDepartment(),
                  )
                : _buildCard(context, results),
          SetupError<Department>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<Department> departments) {
    return DynamicDataTable(
      omitAtIndex: 0,
      maskAtIndex: 1,
      headers: Department.dataHeader,
      anyWidget: _buildAnyWidget(departments),
      rows: departments.map((d) => d.toListL()).toList(),
      onEditTap: (row) async => await _onEditTap(departments, row.first),
      onDeleteTap: (row) async => await _onDeleteTap(departments, row.first),
    );
  }

  _buildAnyWidget(List<Department> departments) {
    return Wrap(
      spacing: 10.0,
      alignment: WrapAlignment.spaceBetween,
      children: [
        context.actionInfoButton(
          'Refresh Departments',
          label: 'Departments',
          count: departments.length,
          onPressed: () {
            // Refresh Company's Departments Data
            context.read<DepartmentBloc>().add(RefreshSetups<Department>());
          },
        ),
        context.elevatedButton(
          'Add Departments',
          onPressed: () => context.openAddDepartment(),
          bgColor: kDangerColor,
          txtColor: kWhiteColor,
        ),
      ],
    );
  }

  Future<void> _onEditTap(List<Department> departments, String id) async {
    final depart = Department.findById(departments, id);
    if (depart == null) return;

    await context.openAddDepartment(serverDepartment: depart);
  }

  Future<void> _onDeleteTap(List<Department> departments, String id) async {
    final depart = Department.findById(departments, id);
    if (depart == null) return;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      /// Delete specific Department
      context.read<DepartmentBloc>().add(
        DeleteSetup<String>(documentId: depart.id),
      );
    }
  }
}
