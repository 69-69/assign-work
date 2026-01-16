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
    return CustomTab(
      length: 4,
      indicatorWeight: 1.0,
      tabs: [
        CustomTabModel(label: 'Company', icon: Icons.home_work),
        CustomTabModel(label: 'Departments', icon: Icons.groups),
        CustomTabModel(label: 'Store Branches', icon: Icons.store),
        CustomTabModel(label: 'PDFs / Print Setup', icon: Icons.print),
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
