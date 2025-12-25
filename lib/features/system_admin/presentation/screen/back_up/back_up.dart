import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/models/result_data.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/files/data_backup_manager.dart';
import 'package:assign_erp/core/widgets/layout/adaptive_layout.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/layout/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:flutter/material.dart';

class BackUp extends StatefulWidget {
  const BackUp({super.key});

  @override
  State<BackUp> createState() => _BackUpState();
}

class _BackUpState extends State<BackUp> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      noAppBar: true,
      body: CustomScrollBar(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: _buildBody(),
      ),
      bottomNavigationBar: const SizedBox.shrink(),
    );
  }

  _buildBody() {
    final backupOptions = [
      {
        'icon': Icons.computer,
        'label': 'Local',
        'desc': 'Back up data on to this computer device',
        'borderColor': kGrayBlueColor,
        'onPressed': () => _confirmBackupDialog('local'),
      },
      {
        'icon': Icons.storage_sharp,
        'label': 'Drive',
        'desc': 'Back up data to external device like USB Flash Drive',
        'borderColor': kWarningColor,
        'onPressed': () => _confirmBackupDialog('drive'),
      },
      {
        'icon': Icons.cloud_download,
        'label': 'Cloud',
        'desc': 'Back up data to a cloud storage service',
        'borderColor': kDangerColor,
        'onPressed': () {},
      },
    ];

    return AdaptiveLayout(
      isFormBuilder: false,
      children: backupOptions.map<Widget>((o) {
        return context.optCardBuilder(
          desc: o['desc'] as String,
          label: o['label'] as String,
          icon: o['icon'] as IconData,
          borderColor: o['borderColor'] as Color?,
          onPressed: o['onPressed'] as VoidCallback?,
        );
      }).toList(),
    );
  }

  Future<void> _confirmBackupDialog(String label) async {
    final title = '${label.toUpperFirst} Backup';

    final isConfirmed = await context.confirmAction<bool>(
      const Text('Would you like to continue with the BackUp?'),
      title: title,
      onAcceptLabel: "Backup",
      onRejectLabel: "Cancel",
    );

    if (mounted && isConfirmed) {
      // Show progress dialog while loading data
      await context.progressBarDialog(
        child: Text('Creating $label data backup...'),
        request: _performBackup(label),
        onSuccess: (_) =>
            context.showAlertOverlay('$title successfully created'),
        onError: (error) => context.showAlertOverlay(
          '$label BackUp failed',
          bgColor: kDangerColor,
        ),
      );
    }
  }

  Future<dynamic> _performBackup(String label) =>
      Future.delayed(kRProgressDelay, () async {
        try {
          final zipResult = await DataBackupManager.startBackup(
            zipFileName: '$label-backup',
            isLocal: label == 'local',
          );
          if (zipResult is Success) {
            return true;
          }
          throw Exception('$label backup failed');
        } catch (e) {
          throw Exception('$label backup failed: $e');
        }
      });
}
