import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/tab_model.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/tab/custom_tab.dart';
import 'package:assign_erp/features/auth/presentation/screen/workspace/update/update_workspace_password.dart';
import 'package:assign_erp/features/system_admin/presentation/index.dart';
import 'package:flutter/material.dart';

const List<Map<String, dynamic>> _tabData = [
  {'label': 'Company Setup', 'icon': Icons.home_work},
  {'label': 'Employees', 'icon': Icons.manage_accounts},
  {'label': 'Roles & Permissions', 'icon': Icons.admin_panel_settings},
  {'label': 'Backup', 'icon': Icons.backup},
  // {'label': 'Workflow Approval Rules', 'icon': Icons.approval},
  // {'label': 'Tax Rates', 'icon': Icons.calculate},
  // {'label': 'Item Preference', 'icon': Icons.category},
  // { 'label': 'renew license', 'icon': Icons.local_police,}
];

class SetupScreen extends StatelessWidget {
  final String openTab;

  const SetupScreen({super.key, this.openTab = '0'});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: systemAdminAppTitle.toUpperAll,
      body: _buildBody(context),
      floatingActionButton: FittedBox(
        child: context.toolbarButton(
          label: 'Change Workspace Password',
          icon: Icons.workspaces,
          bgColor: kDangerColor,
          onPressed: () async => await context.openUpdateWorkspacePopUp(),
        ),
      ),
    );
    /* floatingActionBtnLocation: FloatingActionButtonLocation.startFloat,
      context.buildFloatingBtn(
        'Change Workspace Password',
        icon: Icons.workspaces,
        onPressed: () async => await context.openUpdateWorkspacePopUp(),
      ),
    );*/
  }

  CustomTab _buildBody(BuildContext context) {
    final openThisTab = int.tryParse(openTab) ?? 0;

    return CustomTab(
      isVertical: true,
      isScrollable: true,
      openThisTab: openThisTab,
      length: 4,
      tabs: _tabData
          .map((tab) => CustomTabModel(label: tab['label'], icon: tab['icon']))
          .toList(),
      children: [
        const CompanyScreen(),
        const AllEmployeesScreen(),
        const ManageRolesScreen(),
        const BackUp(),
      ],
    );
  }
}
