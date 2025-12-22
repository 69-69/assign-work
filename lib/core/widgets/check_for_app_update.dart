import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/remote/get_tenant_by.dart';
import 'package:flutter/material.dart';

import 'dialog/prompt_user_for_action.dart';

class CheckForAppUpdate extends StatelessWidget {
  const CheckForAppUpdate({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      // icon: const Icon(Icons.more_vert),
      tooltip: 'Check for Update',
      onSelected: (value) async {
        if (value.isEmpty || context.mounted == false) return;

        return switch (value) {
          'check' => _checkingForUpdate(context),
          'myLicenseAgent' =>
            context.mounted == false ? null : await _showMyAgentDialog(context),
          _ => null,
        };
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(8.0, 2.0, 0, 2.0),
        color: Colors.orange.shade50,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Updated',
              style: context.textTheme.bodyMedium?.copyWith(
                color: kDangerColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.more_vert, color: kDangerColor),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'check', child: Text('Check for Updates')),
        const PopupMenuItem(
          value: 'myLicenseAgent',
          child: Text('My License Agent'),
        ),
      ],
    );
  }

  Future _checkingForUpdate(BuildContext context) async {
    await context.progressBarDialog(
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.1),
        child: Wrap(
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            Text(
              'Checking for updates and installing...',
              style: context.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
      request: Future.delayed(kFProgressDelay),
      onSuccess: (_) => context.showAlertOverlay(
        'All set! You have the latest update installed',
      ),
      onError: (error) =>
          context.showAlertOverlay('Updated failed', bgColor: kDangerColor),
    );
  }

  Future _showMyAgentDialog(BuildContext context) async {
    final myAgent = (await GetTenant.byWorkspaceId(context.workspace!.agentId));
    if (context.mounted == false || myAgent == null) return;

    return await context.confirmAction(
      Text(
        '${myAgent.clientName}\nTel: ${myAgent.mobileNumber}\nEmail: ${myAgent.email}',
      ),
      onAcceptLabel: 'Done',
      onRejectLabel: 'Close',
      title: 'My License Agent',
    );
  }
}
