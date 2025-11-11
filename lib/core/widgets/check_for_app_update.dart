import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:flutter/material.dart';

class CheckForAppUpdate extends StatelessWidget {
  const CheckForAppUpdate({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      // icon: const Icon(Icons.more_vert),
      tooltip: 'Check for Update',
      onSelected: (value) {
        if (value == 'check') {
          _checkingForUpdate(context);
        }
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
        const PopupMenuItem(value: 'changelog', child: Text('View Changelog')),
      ],
    );
  }

  _checkingForUpdate(BuildContext context) async {
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
}
