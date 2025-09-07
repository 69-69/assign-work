import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/index.dart';
import 'package:flutter/material.dart';

class CompanyScreen extends StatelessWidget {
  const CompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  CustomTab _buildBody() {
    return const CustomTab(
      length: 4,
      indicatorWeight: 1.0,
      tabs: [
        {'label': 'company', 'icon': Icons.home_work},
        {'label': 'departments', 'icon': Icons.groups},
        {'label': 'add stores', 'icon': Icons.store},
        {'label': 'PDFs / Print Setup', 'icon': Icons.print},
      ],
      children: [
        ListCompanyInfo(),
        ListDepartments(),
        ListCompanyStores(),
        PrintoutSetup(),
      ],
    );
  }
}
