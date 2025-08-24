import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/setup/data/models/department_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/company/department_bloc.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/setup/presentation/screen/company/add/add_department.dart';
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
      skip: true,
      skipPos: 2,
      showIDToggle: true,
      headers: Department.dataHeader,
      anyWidget: _buildAnyWidget(departments),
      rows: departments.map((d) => d.toListL()).toList(),
      onEditTap: (row) async => _onEditTap(departments, row[1]),
      onDeleteTap: (row) async => _onDeleteTap(departments, row[1]),
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
        context.elevatedIconBtn(
          Icon(Icons.groups, color: kLightColor),
          label: 'Add Departments',
          onPressed: () => context.openAddDepartment(),
          bgColor: kDangerColor,
          txtColor: kLightColor,
        ),
      ],
    );
  }

  Future<void> _onEditTap(List<Department> departments, String id) async {
    final depart = Department.findById(departments, id);
    if (depart == null) return;
    prettyPrint('departments', depart.toMap());

    await context.openAddDepartment(serverDepartment: depart);
  }

  Future<void> _onDeleteTap(List<Department> departments, String id) async {
    {
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
}
