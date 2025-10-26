import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:flutter/material.dart';

class RestoreFromCloud extends StatelessWidget {
  const RestoreFromCloud({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restore Data from Cloud storage (e.g., Google Drive, Dropbox)',
            style: context.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 20),
          context.confirmableActionButton(
            label: 'Restore From Cloud',
            onPressed: () async => await _confirmRestoreDialog(context),
          ),
        ],
      ),
    );
  }

  // Widget to confirm restore dialog
  Future<void> _confirmRestoreDialog(BuildContext context) async {
    final isConfirmed = await context.confirmUserActionDialog(
      onAcceptLabel: "Restore",
      msg: "Do you want to proceed with restoring the data?",
    );

    if (context.mounted && isConfirmed) {
      await context.progressBarDialog(
        child: Text('Restoring data from cloud...'),
        request: _restoreFromCloud(),
        onSuccess: (_) =>
            context.showAlertOverlay('Cloud backup restored successfully'),
        onError: (error) => context.showAlertOverlay(
          'Restoring from cloud failed',
          bgColor: kDangerColor,
        ),
      );
    }
  }

  /// Restore from cloud storage (e.g., Google Drive, Dropbox)
  Future<dynamic> _restoreFromCloud() =>
      Future.delayed(kRProgressDelay, () async {
        try {
          throw Exception('Restoring failed');
        } catch (e) {
          throw Exception('Restoring failed: $e');
        }
      });
}
