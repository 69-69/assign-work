import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/system_admin/data/models/employee_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/create_acc/employee_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/all_employees/employee_account/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateUserAccScreen extends StatelessWidget {
  const CreateUserAccScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EmployeeBloc>(
      create: (context) =>
          EmployeeBloc(firestore: FirebaseFirestore.instance)
            ..add(GetSetups<Employee>()),
      child: CustomScaffold(
        noAppBar: true,
        body: const ListEmployees(),
        bottomNavigationBar: const SizedBox.shrink(),
      ),
    );
  }
}
