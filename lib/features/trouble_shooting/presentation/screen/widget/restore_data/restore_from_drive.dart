import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/result_data.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/data_backup_manager.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:flutter/material.dart';

class RestoreFromDrive extends StatelessWidget {
  const RestoreFromDrive({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restore Data from Device/Storage (e.g., USB Flash Drive, user preferences)',
            style: context.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 20),
          context.confirmableActionButton(
            label: 'Restore From Drive',
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
        child: Text('Restoring data from drive...'),
        request: _restoreFromDrive(),
        onSuccess: (_) =>
            context.showAlertOverlay('Drive backup restored successfully'),
        onError: (error) => context.showAlertOverlay(
          'Restoring from drive failed',
          bgColor: kDangerColor,
        ),
      );
    }
  }

  /// Restore from external device/storage (e.g., USB Flash Drive, user preferences)
  Future<dynamic> _restoreFromDrive() async {
    try {
      final restoreResult = await DataBackupManager.startRestore(
        zipFileName: '',
        isLocal: false,
      );

      if (restoreResult is Success<String>) {
        return;
      }
      throw Exception('Restoring failed');
    } catch (e) {
      throw Exception('Restoring failed: $e');
    }
  }
}
