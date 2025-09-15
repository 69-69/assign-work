import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/auth/presentation/screen/workspace/update/update_workspace_password.dart';
import 'package:assign_erp/features/system_admin/presentation/index.dart';
import 'package:flutter/material.dart';

const _sideTabs = [
  {'label': 'company', 'icon': Icons.home_work},
  {'label': 'employees', 'icon': Icons.manage_accounts},
  {'label': 'Roles & Permissions', 'icon': Icons.admin_panel_settings},
  {'label': 'Tax rates', 'icon': Icons.calculate},
  {'label': 'item preference', 'icon': Icons.category},
  {'label': 'back up', 'icon': Icons.backup},
  {'label': 'renew license', 'icon': Icons.local_police},
];

class SetupScreen extends StatelessWidget {
  final String openTab;

  const SetupScreen({super.key, this.openTab = '0'});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: systemAdminAppTitle.toUpperAll,
      body: _buildBody(context),
      floatingActionBtnLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: context.buildFloatingBtn(
        'Change Workspace Password',
        icon: Icons.workspaces_outline,
        onPressed: () async => await context.openUpdateWorkspacePopUp(),
      ),
    );
  }

  CustomTab _buildBody(BuildContext context) {
    final openThisTab = int.tryParse(openTab) ?? 0;

    return CustomTab(
      isVertical: true,
      isScrollable: true,
      openThisTab: openThisTab,
      length: 6,
      tabs: _sideTabs,
      children: [
        const CompanyScreen(),
        const AllEmployeesScreen(),
        const ManageRolesScreen(),
        const ManageTaxScreen(),
        const ProductConfigScreen(),
        const BackUp(),
        const LicenseRenewal(),
      ],
    );
  }
}
