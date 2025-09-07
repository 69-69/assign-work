import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/nav/custom_tab.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/screen/app_issues/error_logs.dart';
import 'package:assign_erp/features/trouble_shooting/presentation/screen/user_device/user_device_specs.dart';
import 'package:flutter/material.dart';

class DiagnosticScreen extends StatelessWidget {
  final String openTab;

  const DiagnosticScreen({super.key, this.openTab = '0'});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'System Diagnostic',
      body: CustomTab(
        length: 2,
        isVertical: true,
        tabs: [
          {'label': 'App Issues', 'icon': Icons.bug_report_outlined},
          {'label': 'Device Specs', 'icon': Icons.important_devices_outlined},
        ],
        children: [ErrorLogs(), UserDeviceSpec()],
      ),

      // floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  /*Widget _buildFloatingActionButton(BuildContext context) {
    return context.buildFloatingBtn(
      'Device Specs',
      icon: Icons.important_devices_sharp,
      onPressed: () => context.openUserDeviceSpecs(),
    );
  }*/
}
