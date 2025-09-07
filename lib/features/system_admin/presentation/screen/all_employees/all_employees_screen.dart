import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
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
    return const CustomTab(
      length: 2,
      indicatorWeight: 1.0,
      tabs: [
        {'label': 'account', 'icon': Icons.account_circle},
        {'label': 'attendance', 'icon': Icons.fact_check_outlined},
      ],
      children: [CreateUserAccScreen(), AttendanceScreen()],
    );
  }
}
