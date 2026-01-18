import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:flutter/material.dart';

import 'index.dart';

class AllEmployeesScreen extends StatefulWidget {
  const AllEmployeesScreen({super.key});

  @override
  State<AllEmployeesScreen> createState() => _AllEmployeesScreenState();
}

class _AllEmployeesScreenState extends State<AllEmployeesScreen> {
  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  CustomTab _buildBody() {
    return CustomTab(
      length: 2,
      tabs: [
        CustomTabModel(label: 'Employees', icon: Icons.people),
        CustomTabModel(label: 'Activity logs', icon: Icons.fact_check_outlined),
      ],
      children: [CreateUserAccScreen(), ActivityLogsScreen()],
    );
  }
}
